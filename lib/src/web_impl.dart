// lib/src/web_impl.dart
//
// Web platform implementation of StreamedFileUploaderPlatform.
//
// Key design decisions:
//  • Uses dart:js_interop — no dart:html, no XFile.
//  • Opens an OS-level file picker via window.showOpenFilePicker.
//  • Pipes bytes through the browser's native ReadableStream without ever
//    accumulating the full file in a Dart List/Uint8List.
//  • StreamController is driven by an async JS reader loop — back-pressure
//    is respected: the next reader.read() is not issued until the previous
//    chunk has been consumed downstream.
//  • H=FileSystemFileHandle: PickedFile<FileSystemFileHandle> is the concrete
//    type throughout, so no runtime `is` / `as` cast is ever needed.

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:streamed_file_uploader/src/interface.dart';
import 'package:streamed_file_uploader/src/js_interop_types.dart';

// ---------------------------------------------------------------------------
// Plugin registration
// ---------------------------------------------------------------------------

base class StreamedFileUploaderWeb
    extends StreamedFileUploaderPlatform<FileSystemFileHandle> {
  static void registerWith(dynamic registrar) {
    StreamedFileUploaderPlatform.instance = StreamedFileUploaderWeb();
  }

  // -------------------------------------------------------------------------
  // isSupported
  // -------------------------------------------------------------------------

  @override
  bool get isSupported => isFileSystemAccessSupported;

  // -------------------------------------------------------------------------
  // pickFiles → FilePickerResult<FileSystemFileHandle>
  // -------------------------------------------------------------------------

  @override
  Future<FilePickerResult<FileSystemFileHandle>> pickFiles(
    PickerOptions options,
  ) async {
    if (!isSupported) {
      throw UnsupportedError(
        'window.showOpenFilePicker is not available in this browser. '
        'Chrome 86+, Edge 86+, and Opera 72+ are supported.',
      );
    }

    final jsOptions = buildPickerOptions(
      multiple: options.allowMultiple,
      types: _buildAcceptTypes(options.filters),
      excludeAcceptAllOption: options.filters.isNotEmpty &&
          !options.filters.contains(FileTypeFilter.any),
    );

    final JSArray<FileSystemFileHandle> handles;
    try {
      handles = await showOpenFilePicker(jsOptions).toDart;
    } on Object catch (e) {
      final msg = e.toString();
      if (msg.contains('AbortError') || msg.contains('abort')) {
        return const FilePickerResult(files: []);
      }
      throw FilePickerException('showOpenFilePicker failed', cause: e);
    }

    final pickedFiles = <PickedFile<FileSystemFileHandle>>[];
    final length = handles.length;
    for (var i = 0; i < length; i++) {
      final handle = handles.toDart[i];
      final WebFile jsFile;
      try {
        jsFile = await handle.getFile().toDart;
      } on Object catch (e) {
        throw FilePickerException(
          'Failed to resolve FileSystemFileHandle to File',
          cause: e,
        );
      }

      pickedFiles.add(PickedFile(
        name: jsFile.name,
        size: jsFile.size,
        mimeType: jsFile.type,
        lastModified: DateTime.fromMillisecondsSinceEpoch(
          jsFile.lastModified.toInt(),
        ),
        // Store the handle, not the File object — keeps the GC-able File
        // off the long-lived heap; we re-call getFile() in openReadStream.
        handle: handle,
      ));
    }

    return FilePickerResult(files: pickedFiles);
  }

  // -------------------------------------------------------------------------
  // openReadStream — no cast needed; handle is already FileSystemFileHandle
  // -------------------------------------------------------------------------

  @override
  Stream<Uint8List> openReadStream(
    PickedFile<FileSystemFileHandle> file, {
    ReadStreamOptions options = const ReadStreamOptions(),
  }) {
    // file.handle is statically typed as FileSystemFileHandle — no `is` check,
    // no `as` cast, no JS interop runtime-type-check warning.
    late StreamController<Uint8List> controller;
    controller = StreamController<Uint8List>(
      onListen: () => _pumpStream(file.handle, controller, options),
      onCancel: () {
        // Cancellation propagated inside _pumpStream via controller.isClosed.
      },
    );
    return controller.stream;
  }

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  Future<void> _pumpStream(
    FileSystemFileHandle handle,
    StreamController<Uint8List> controller,
    ReadStreamOptions options,
  ) async {
    WebFile jsFile;
    try {
      jsFile = await handle.getFile().toDart;
    } on Object catch (e) {
      controller.addError(
        ReadStreamException('Failed to open file for reading', cause: e),
      );
      await controller.close();
      return;
    }

    final JsReadableStream readableStream = jsFile.stream();
    final ReadableStreamDefaultReader reader = readableStream.getReader();

    try {
      while (true) {
        if (controller.isPaused) await _waitForResume(controller);
        if (controller.isClosed) break;

        final ReadableStreamReadResult result;
        try {
          result = await reader.read().toDart;
        } on Object catch (e) {
          controller.addError(
            ReadStreamException('Error reading chunk from browser stream',
                cause: e),
          );
          break;
        }

        if (result.done) break;

        final JSUint8Array? jsChunk = result.value;
        if (jsChunk == null) continue;

        // .toDart: zero-copy view in dart2js; one copy in dart2wasm (unavoidable
        // due to linear memory isolation). Either way, one allocation per chunk.
        final Uint8List dartChunk = jsChunk.toDart;

        if (dartChunk.lengthInBytes <= options.chunkSize) {
          controller.add(dartChunk);
        } else {
          // Sub-chunk without re-allocation (sublistView is a view, not a copy).
          var offset = 0;
          while (offset < dartChunk.lengthInBytes) {
            final end =
                (offset + options.chunkSize).clamp(0, dartChunk.lengthInBytes);
            controller.add(Uint8List.sublistView(dartChunk, offset, end));
            offset = end;
            if (controller.isPaused) await _waitForResume(controller);
            if (controller.isClosed) break;
          }
        }
      }
    } finally {
      try {
        reader.releaseLock();
      } catch (_) {}
      if (!controller.isClosed) await controller.close();
    }
  }

  Future<void> _waitForResume(StreamController<Uint8List> controller) async {
    while (controller.isPaused && !controller.isClosed) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  JSArray<JSObject> _buildAcceptTypes(List<FileTypeFilter> filters) {
    final types = <JSObject>[];
    for (final filter in filters) {
      if (filter.mimeTypes.isEmpty && filter.extensions.isEmpty) continue;

      final mimeToExts = <String, List<String>>{};
      for (final mime in filter.mimeTypes) {
        mimeToExts[mime] = filter.extensions
            .map((e) => e.startsWith('.') ? e : '.$e')
            .toList();
      }
      if (mimeToExts.isEmpty && filter.extensions.isNotEmpty) {
        mimeToExts['application/octet-stream'] = filter.extensions
            .map((e) => e.startsWith('.') ? e : '.$e')
            .toList();
      }

      types.add(buildAcceptType(
        description: filter.label,
        accept: buildAcceptRecord(mimeToExts),
      ));
    }
    return types.toJS;
  }
}
