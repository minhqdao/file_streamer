import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_streamer/src/interface.dart';
import 'package:file_streamer/src/js_interop_types.dart';
import 'package:file_streamer/src/picker/picked_file.dart';
import 'package:file_streamer/src/picker/picker_exceptions.dart';
import 'package:file_streamer/src/picker/picker_options.dart';
import 'package:file_streamer/src/picker/picker_result.dart';
import 'package:file_streamer/src/stream/stream_exceptions.dart';
import 'package:file_streamer/src/stream/stream_options.dart';
import 'package:mime/mime.dart';

base class FileStreamerWeb extends FileStreamerPlatform<Object> {
  static void registerWith(dynamic registrar) {
    FileStreamerPlatform.instance = FileStreamerWeb();
  }

  /// Internal getter reflecting File System Access API availability.
  bool get supportsSystemAccess =>
      _supportsSystemAccess ?? isFileSystemAccessSupported;
  set supportsSystemAccess(bool? value) => _supportsSystemAccess = value;
  bool? _supportsSystemAccess;

  @override
  bool get isSupported => true; // Web always supported (via fallback)

  @override
  PickedFile<Object> fromPath(String path) {
    throw UnsupportedError(
        'FileStreamer.fromPath() is not supported on Web due to browser security restrictions. '
        'Use FileStreamer.pickFiles() to allow the user to select a file.');
  }

  @override
  Future<FilePickerResult<Object>> pickFiles(
    PickerOptions options,
  ) {
    if (supportsSystemAccess) {
      return _pickFilesWithSystemAccess(options);
    } else {
      return _pickFilesWithInputFallback(options);
    }
  }

  Future<FilePickerResult<FileSystemFileHandle>> _pickFilesWithSystemAccess(
    PickerOptions options,
  ) async {
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
        throw FilePickerException('Failed to resolve handle to File', cause: e);
      }

      pickedFiles.add(PickedFile(
        name: jsFile.name,
        size: jsFile.size,
        mimeType: jsFile.type,
        lastModified: DateTime.fromMillisecondsSinceEpoch(
          jsFile.lastModified.toInt(),
        ),
        handle: handle,
      ));
    }

    return FilePickerResult(files: pickedFiles);
  }

  Future<FilePickerResult<WebFile>> _pickFilesWithInputFallback(
    PickerOptions options,
  ) {
    final input = jsDocument.createInputElement();
    input.type = 'file';
    input.multiple = options.allowMultiple;
    input.accept = _buildAcceptString(options.filters);
    input.style.display = 'none';
    jsDocument.body.appendChild(input);

    final completer = Completer<FilePickerResult<WebFile>>();

    // Timeout fallback for cancellation (~10 seconds)
    final timer = Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.complete(const FilePickerResult(files: []));
      }
    });

    late JSFunction changeListener;

    void cleanup() {
      timer.cancel();
      input.removeEventListener('change', changeListener);
      input.remove();
    }

    changeListener = (JSAny? _) {
      if (completer.isCompleted) return;

      final files = input.files;
      if (files == null || files.length == 0) {
        completer.complete(const FilePickerResult(files: []));
      } else {
        final pickedFiles = <PickedFile<WebFile>>[];
        for (var i = 0; i < files.length; i++) {
          final file = files.item(i);
          if (file == null) continue;
          pickedFiles.add(PickedFile(
            name: file.name,
            size: file.size,
            mimeType: file.type,
            lastModified: DateTime.fromMillisecondsSinceEpoch(
              file.lastModified.toInt(),
            ),
            handle: file,
          ));
        }
        completer.complete(FilePickerResult(files: pickedFiles));
      }
    }.toJS;

    input.addEventListener('change', changeListener);
    input.click();

    return completer.future.whenComplete(cleanup);
  }

  @override
  Stream<Uint8List> openReadStream(
    PickedFile<Object> file, {
    ReadStreamOptions options = const ReadStreamOptions(),
  }) {
    late StreamController<Uint8List> controller;
    controller = StreamController<Uint8List>(
      onListen: () async {
        WebFile jsFile;
        final handle = file.handle;

        // Use direct type checks as requested.
        // ignore: invalid_runtime_check_with_js_interop_types
        if (handle is FileSystemFileHandle) {
          try {
            jsFile = await handle.getFile().toDart;
          } on Object catch (e) {
            controller
                .addError(ReadStreamException('Failed to open file', cause: e));
            await controller.close();
            return;
          }
          // ignore: invalid_runtime_check_with_js_interop_types
        } else if (handle is WebFile) {
          jsFile = handle;
        } else {
          controller.addError(ReadStreamException(
              'Unknown handle type: ${handle.runtimeType}'));
          await controller.close();
          return;
        }
        await _pumpStreamFromBlob(jsFile, controller, options);
      },
    );
    return controller.stream;
  }

  @override
  Stream<Uint8List> openReadStreamFromBlob(
    Object blob, {
    ReadStreamOptions options = const ReadStreamOptions(),
  }) {
    late StreamController<Uint8List> controller;
    controller = StreamController<Uint8List>(
      onListen: () => _pumpStreamFromBlob(blob as WebFile, controller, options),
    );
    return controller.stream;
  }

  Future<void> _pumpStreamFromBlob(
    WebFile jsFile,
    StreamController<Uint8List> controller,
    ReadStreamOptions options,
  ) async {
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
          controller
              .addError(ReadStreamException('Error reading chunk', cause: e));
          break;
        }

        if (result.done) break;

        final JSUint8Array? jsChunk = result.value;
        if (jsChunk == null) continue;

        final Uint8List dartChunk = jsChunk.toDart;

        if (dartChunk.lengthInBytes <= options.chunkSize) {
          controller.add(dartChunk);
        } else {
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
      final extensions =
          filter.extensions.map((e) => e.startsWith('.') ? e : '.$e').toList();

      for (final mime in filter.mimeTypes) {
        mimeToExts[mime] = extensions;
      }

      // If no MIME types provided but extensions are, try to look them up.
      if (mimeToExts.isEmpty) {
        for (final ext in extensions) {
          final mime = lookupMimeType(ext) ?? 'application/octet-stream';
          if (!mimeToExts.containsKey(mime)) {
            mimeToExts[mime] = [];
          }
          mimeToExts[mime]!.add(ext);
        }
      }

      if (mimeToExts.isNotEmpty) {
        types.add(buildAcceptType(
          description: filter.label,
          accept: buildAcceptRecord(mimeToExts),
        ));
      }
    }
    return types.toJS;
  }

  String _buildAcceptString(List<FileTypeFilter> filters) {
    if (filters.isEmpty || filters.contains(FileTypeFilter.any)) {
      return '';
    }
    final combined = <String>{};
    for (final filter in filters) {
      for (final mime in filter.mimeTypes) {
        combined.add(mime);
      }
      for (final ext in filter.extensions) {
        combined.add(ext.startsWith('.') ? ext : '.$ext');
      }
    }
    return combined.join(',');
  }
}
