// lib/src/picker/platform/picker_stub.dart
import 'package:file_streamer/src/picker/picker_options.dart';
import 'package:file_streamer/src/picker/picker_result.dart';

Future<FilePickerResult<String>> pickFilesNative(PickerOptions options) =>
    throw UnsupportedError(
      'pickFiles() on native platforms requires a Flutter environment.',
    );
