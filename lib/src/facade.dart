import 'dart:typed_data';

import 'package:streamed_file_uploader/src/interface.dart';
import 'package:streamed_file_uploader/src/picker/picked_file.dart';
import 'package:streamed_file_uploader/src/picker/picker_options.dart';
import 'package:streamed_file_uploader/src/picker/picker_result.dart';
import 'package:streamed_file_uploader/src/stream/stream_options.dart';

/// Thin static facade over [StreamedFileUploaderPlatform.instance].
abstract final class StreamedFileUploader {
  StreamedFileUploader._();

  static bool get isSupported =>
      StreamedFileUploaderPlatform.instance.isSupported;

  static Future<FilePickerResult<Object>> pickFiles([
    PickerOptions options = const PickerOptions(),
  ]) =>
      StreamedFileUploaderPlatform.instance.pickFiles(options);

  /// Streams the bytes of [file] without loading the whole file into memory.
  static Stream<Uint8List> openReadStream(
    PickedFile<Object> file, {
    ReadStreamOptions options = const ReadStreamOptions(),
  }) =>
      StreamedFileUploaderPlatform.instance.openReadStream(
        file,
        options: options,
      );
}
