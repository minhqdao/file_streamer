import 'dart:typed_data';

import 'package:file_streamer/src/interface.dart';
import 'package:file_streamer/src/picker/picked_file.dart';
import 'package:file_streamer/src/picker/picker_options.dart';
import 'package:file_streamer/src/picker/picker_result.dart';
import 'package:file_streamer/src/stream/stream_options.dart';

/// Static entry point for file picking and streaming operations.
///
/// This facade selects the appropriate platform implementation (Web or Native IO)
/// to handle file access.
abstract final class FileStreamer {
  FileStreamer._();

  /// Whether the file streaming API is supported on the current platform.
  static bool get isSupported => FileStreamerPlatform.instance.isSupported;

  /// Opens the platform's file picker dialog.
  ///
  /// Returns a [FilePickerResult] containing one or more [PickedFile] objects.
  /// Throws a [FilePickerException] if the operation is cancelled or fails.
  static Future<FilePickerResult<Object>> pickFiles([
    PickerOptions options = const PickerOptions(),
  ]) =>
      FileStreamerPlatform.instance.pickFiles(options);

  /// Streams the bytes of [file] as [Uint8List] chunks.
  ///
  /// This operation does not load the whole file into memory. Instead, it reads
  /// from the platform's underlying file handle in chunks defined by
  /// [options.chunkSize].
  ///
  /// Throws a [ReadStreamException] if the file cannot be accessed or read.
  static Stream<Uint8List> openReadStream(
    PickedFile<Object> file, {
    ReadStreamOptions options = const ReadStreamOptions(),
  }) =>
      FileStreamerPlatform.instance.openReadStream(
        file,
        options: options,
      );
}
