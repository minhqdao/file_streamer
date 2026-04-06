import 'dart:async';
import 'dart:typed_data';

import 'package:streamed_file_uploader/src/picker/picked_file.dart';
import 'package:streamed_file_uploader/src/picker/picker_options.dart';
import 'package:streamed_file_uploader/src/picker/picker_result.dart';
import 'package:streamed_file_uploader/src/platform/platform_stub.dart'
    if (dart.library.js_interop) 'package:streamed_file_uploader/src/platform/platform_web.dart'
    if (dart.library.io) 'package:streamed_file_uploader/src/platform/platform_io.dart';
import 'package:streamed_file_uploader/src/stream/stream_options.dart';

/// Base class for platform implementations.
abstract base class StreamedFileUploaderPlatform<H extends Object> {
  static StreamedFileUploaderPlatform<Object>? _instance;

  static StreamedFileUploaderPlatform<Object> get instance {
    _instance ??= createPlatform();
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

  /// Streams the bytes from a platform-specific blob or file object.
  ///
  /// On Web, this accepts a `package:web` `Blob` or `File`.
  /// On other platforms, this typically throws an [UnsupportedError].
  Stream<Uint8List> openReadStreamFromBlob(
    Object blob, {
    ReadStreamOptions options = const ReadStreamOptions(),
  });

  bool get isSupported;
}
