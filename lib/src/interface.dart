import 'dart:async';
import 'dart:typed_data';

import 'package:file_streamer/src/picker/picked_file.dart';
import 'package:file_streamer/src/picker/picker_options.dart';
import 'package:file_streamer/src/picker/picker_result.dart';
import 'package:file_streamer/src/platform/platform_stub.dart'
    if (dart.library.js_interop) 'package:file_streamer/src/platform/platform_web.dart'
    if (dart.library.io) 'package:file_streamer/src/platform/platform_io.dart';
import 'package:file_streamer/src/stream/stream_options.dart';

/// Base class for platform implementations.
abstract base class FileStreamerPlatform<H extends Object> {
  static FileStreamerPlatform<Object>? _instance;

  static FileStreamerPlatform<Object> get instance {
    _instance ??= createPlatform();
    return _instance!;
  }

  static set instance(FileStreamerPlatform<Object> impl) {
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
