// lib/src/picker/picker_result.dart
import 'package:streamed_file_uploader/src/picker/picked_file.dart';

/// Result returned from a single pickFiles call.
final class FilePickerResult<H extends Object> {
  const FilePickerResult({required this.files});

  /// Ordered list of files chosen by the user.
  final List<PickedFile<H>> files;

  bool get isEmpty => files.isEmpty;
  bool get isNotEmpty => files.isNotEmpty;
  int get count => files.length;
}
