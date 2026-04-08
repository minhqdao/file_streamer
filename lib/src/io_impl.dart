import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:streamed_file_uploader/src/interface.dart';
import 'package:streamed_file_uploader/src/picker/picked_file.dart';
import 'package:streamed_file_uploader/src/picker/picker_options.dart';
import 'package:streamed_file_uploader/src/picker/picker_result.dart';
import 'package:streamed_file_uploader/src/picker/platform/picker_stub.dart'
    if (dart.library.ui) 'package:streamed_file_uploader/src/picker/platform/picker_ffi.dart';
import 'package:streamed_file_uploader/src/stream/stream_exceptions.dart';
import 'package:streamed_file_uploader/src/stream/stream_options.dart';

base class StreamedFileUploaderIO extends StreamedFileUploaderPlatform<String> {
  static void registerWith(dynamic registrar) {
    StreamedFileUploaderPlatform.instance = StreamedFileUploaderIO();
  }

  @override
  bool get isSupported => true;

  @override
  Future<FilePickerResult<String>> pickFiles(PickerOptions options) {
    return pickFilesNative(options);
  }

  @override
  Stream<Uint8List> openReadStream(
    PickedFile<String> file, {
    ReadStreamOptions options = const ReadStreamOptions(),
  }) {
    final ioFile = io.File(file.handle);

    if (!ioFile.existsSync()) {
      return Stream.error(
        ReadStreamException('File not found: ${file.handle}'),
      );
    }

    return _rechunk(ioFile.openRead(), options.chunkSize);
  }

  @override
  Stream<Uint8List> openReadStreamFromBlob(
    Object blob, {
    ReadStreamOptions options = const ReadStreamOptions(),
  }) {
    return Stream.error(
      const ReadStreamException(
          'Blobs are only supported on the Web platform.'),
    );
  }

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
