// lib/src/picker/picker_options.dart
/// Filter that restricts which file types appear in the OS picker dialog.
final class FileTypeFilter {
  const FileTypeFilter({
    required this.label,
    required this.mimeTypes,
    required this.extensions,
  });

  final String label;
  final List<String> mimeTypes;
  final List<String> extensions;

  static const FileTypeFilter images = FileTypeFilter(
    label: 'Images',
    mimeTypes: ['image/png', 'image/jpeg', 'image/gif', 'image/webp'],
    extensions: ['png', 'jpg', 'jpeg', 'gif', 'webp'],
  );

  static const FileTypeFilter videos = FileTypeFilter(
    label: 'Videos',
    mimeTypes: ['video/mp4', 'video/webm', 'video/quicktime'],
    extensions: ['mp4', 'webm', 'mov'],
  );

  static const FileTypeFilter any = FileTypeFilter(
    label: 'All files',
    mimeTypes: [],
    extensions: [],
  );
}

/// Options forwarded to the OS / browser picker dialog.
final class PickerOptions {
  const PickerOptions({
    this.allowMultiple = false,
    this.filters = const [FileTypeFilter.any],
    this.startDirectory,
  });

  final bool allowMultiple;
  final List<FileTypeFilter> filters;
  final String? startDirectory;
}
