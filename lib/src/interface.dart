// lib/src/interface.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:streamed_file_uploader/src/picker/picked_file.dart';
import 'package:streamed_file_uploader/src/picker/picker_options.dart';
import 'package:streamed_file_uploader/src/picker/picker_result.dart';
import 'package:streamed_file_uploader/src/stream/stream_options.dart';

/// Base class for platform implementations.
abstract base class StreamedFileUploaderPlatform<H extends Object> {
  static StreamedFileUploaderPlatform<Object>? _instance;

  static StreamedFileUploaderPlatform<Object> get instance {
    assert(
      _instance != null,
      'No StreamedFileUploaderPlatform implementation registered.',
    );
    return _instance!;
  }

  static set instance(StreamedFileUploaderPlatform<Object> impl) {
    _instance = impl;
  }

  Future<FilePickerResult<H>> pickFiles(PickerOptions options);

  Stream<Uint8List> openReadStream(
    PickedFile<H> file, {
    ReadStreamOptions options = const ReadStreamOptions(),
  });

  bool get isSupported;
}
