import 'dart:typed_data';

import 'package:file_streamer/src/interface.dart';
import 'package:file_streamer/src/picker/picked_file.dart';
import 'package:file_streamer/src/picker/picker_options.dart';
import 'package:file_streamer/src/picker/picker_result.dart';
import 'package:file_streamer/src/stream/stream_options.dart';

/// Thin static facade over [FileStreamerPlatform.instance].
abstract final class FileStreamer {
  FileStreamer._();

  static bool get isSupported =>
      FileStreamerPlatform.instance.isSupported;

  static Future<FilePickerResult<Object>> pickFiles([
    PickerOptions options = const PickerOptions(),
  ]) =>
      FileStreamerPlatform.instance.pickFiles(options);

  /// Streams the bytes of [file] without loading the whole file into memory.
  static Stream<Uint8List> openReadStream(
    PickedFile<Object> file, {
    ReadStreamOptions options = const ReadStreamOptions(),
  }) =>
      FileStreamerPlatform.instance.openReadStream(
        file,
        options: options,
      );
}
