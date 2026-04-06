// lib/streamed_file_uploader.dart
//
// Public API surface of streamed_file_uploader.
//
// Usage:
//   import 'package:streamed_file_uploader/streamed_file_uploader.dart';
//
//   final result = await StreamedFileUploader.pickFiles(
//     const PickerOptions(filters: [FileTypeFilter.images]),
//   );
//   if (result.isNotEmpty) {
//     final stream = StreamedFileUploader.openReadStream(result.files.first);
//     await uploadToS3(stream);
//   }

import 'dart:typed_data';

import 'package:streamed_file_uploader/src/interface.dart';

export 'src/interface.dart'
    show
        FilePickerException,
        FilePickerResult,
        FileTypeFilter,
        PickedFile,
        PickerOptions,
        ReadStreamException,
        ReadStreamOptions,
        StreamedFileUploaderPlatform;

/// Thin static façade over [StreamedFileUploaderPlatform.instance].
abstract final class StreamedFileUploader {
  StreamedFileUploader._();

  static bool get isSupported => StreamedFileUploaderPlatform.instance.isSupported;

  static Future<FilePickerResult<Object>> pickFiles([
    PickerOptions options = const PickerOptions(),
  ]) =>
      StreamedFileUploaderPlatform.instance.pickFiles(options);

  /// Streams the bytes of [file] without loading the whole file into memory.
  ///
  /// [file] must come from [pickFiles] on the same platform instance.
  /// The type parameter is erased to [Object] at the façade level; the
  /// platform implementation receives the correctly-typed [PickedFile<H>]
  /// because [pickFiles] always returns files from the live instance.
  static Stream<Uint8List> openReadStream(
    PickedFile<Object> file, {
    ReadStreamOptions options = const ReadStreamOptions(),
  }) =>
      StreamedFileUploaderPlatform.instance.openReadStream(
        file,
        options: options,
      );
}
