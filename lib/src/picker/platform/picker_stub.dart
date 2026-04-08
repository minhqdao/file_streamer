// lib/src/picker/platform/picker_stub.dart
import 'package:streamed_file_uploader/src/picker/picker_options.dart';
import 'package:streamed_file_uploader/src/picker/picker_result.dart';

Future<FilePickerResult<String>> pickFilesNative(PickerOptions options) =>
    throw UnsupportedError(
      'pickFiles() on native platforms requires a Flutter environment.',
    );
