// lib/src/picker/picker_result.dart
import 'package:file_streamer/src/picker/picked_file.dart';

/// Result returned from a single file picking operation.
final class FilePickerResult<H extends Object> {
  /// Creates a result wrapper for the selected files.
  const FilePickerResult({required this.files});

  /// The list of [PickedFile] objects chosen by the user.
  final List<PickedFile<H>> files;

  /// Whether no files were selected.
  bool get isEmpty => files.isEmpty;

  /// Whether at least one file was selected.
  bool get isNotEmpty => files.isNotEmpty;

  /// The number of files selected.
  int get count => files.length;

  @override
  String toString() => 'FilePickerResult<$H>(count: $count, files: $files)';
}
