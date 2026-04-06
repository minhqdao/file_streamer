// lib/src/io_impl.dart
//
// Native (Android / iOS / macOS / Linux / Windows) implementation.
// Uses dart:io File.openRead() — zero full-file buffering.
// H=String: the handle is always an absolute file-system path.

import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:streamed_file_uploader/src/interface.dart';

base class StreamedFileUploaderIO extends StreamedFileUploaderPlatform<String> {
  static void registerWith(dynamic registrar) {
    StreamedFileUploaderPlatform.instance = StreamedFileUploaderIO();
  }

  @override
  bool get isSupported => true;

  @override
  Future<FilePickerResult<String>> pickFiles(PickerOptions options) {
    throw UnsupportedError(
      'pickFiles() on native platforms requires a host-side method channel '
      'implementation. Inject your picker via '
      'StreamedFileUploaderPlatform.instance = MyNativePicker(), '
      'then delegate streaming to StreamedFileUploaderIO.openReadStream().',
    );
  }

  @override
  Stream<Uint8List> openReadStream(
    PickedFile<String> file, {
    ReadStreamOptions options = const ReadStreamOptions(),
  }) {
    // file.handle is statically a String — no cast, no type-check warning.
    final ioFile = io.File(file.handle);

    if (!ioFile.existsSync()) {
      return Stream.error(
        ReadStreamException('File not found: ${file.handle}'),
      );
    }

    return _rechunk(ioFile.openRead(), options.chunkSize);
  }

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  Stream<Uint8List> _rechunk(
    Stream<List<int>> source,
    int chunkSize,
  ) async* {
    final buffer = _ChunkBuffer(chunkSize);
    await for (final incoming in source) {
      var offset = 0;
      while (offset < incoming.length) {
        offset += buffer.add(incoming, offset);
        if (buffer.isFull) yield buffer.flush();
      }
    }
    if (buffer.isNotEmpty) yield buffer.flush();
  }
}

// ---------------------------------------------------------------------------
// Helper — fixed-capacity chunk buffer
// ---------------------------------------------------------------------------

final class _ChunkBuffer {
  _ChunkBuffer(this._capacity) : _data = Uint8List(_capacity);

  final int _capacity;
  final Uint8List _data;
  int _length = 0;

  bool get isFull => _length == _capacity;
  bool get isNotEmpty => _length > 0;

  int add(List<int> src, int srcOffset) {
    final toCopy = (src.length - srcOffset).clamp(0, _capacity - _length);
    for (var i = 0; i < toCopy; i++) {
      _data[_length + i] = src[srcOffset + i];
    }
    _length += toCopy;
    return toCopy;
  }

  Uint8List flush() {
    final result = Uint8List.fromList(_data.sublist(0, _length));
    _length = 0;
    return result;
  }
}

// ---------------------------------------------------------------------------
// Utility — build a PickedFile<String> from a native file path
// ---------------------------------------------------------------------------

/// Convenience factory for native platforms.
///
/// Use this when your method-channel picker returns an absolute file path:
/// ```dart
/// final path = await pickFilePathFromMethodChannel();
/// final file = pickedFileFromPath(path);
/// final stream = StreamedFileUploaderPlatform.instance
///     .openReadStream(file as PickedFile<String>);
/// ```
PickedFile<String> pickedFileFromPath(String absolutePath) {
  final ioFile = io.File(absolutePath);
  final stat = ioFile.statSync();
  return PickedFile(
    name: absolutePath.split(io.Platform.pathSeparator).last,
    size: stat.size,
    mimeType: '',
    lastModified: stat.modified,
    handle: absolutePath,
  );
}
