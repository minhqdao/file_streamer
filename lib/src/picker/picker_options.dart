// lib/src/picker/picker_options.dart
/// Filter that restricts which file types appear in the OS picker dialog.
final class FileTypeFilter {
  /// Creates a custom file type filter.
  const FileTypeFilter({
    required this.label,
    required this.mimeTypes,
    required this.extensions,
  });

  /// User-friendly label for the filter (e.g., "Documents").
  final String label;

  /// MIME types allowed by this filter (e.g., `["application/pdf"]`).
  final List<String> mimeTypes;

  /// File extensions allowed by this filter (e.g., `["pdf"]`).
  final List<String> extensions;

  /// Default filter for common image formats (png, jpg, jpeg, gif, webp).
  static const FileTypeFilter images = FileTypeFilter(
    label: 'Images',
    mimeTypes: ['image/png', 'image/jpeg', 'image/gif', 'image/webp'],
    extensions: ['png', 'jpg', 'jpeg', 'gif', 'webp'],
  );

  /// Default filter for common video formats (mp4, webm, mov).
  static const FileTypeFilter videos = FileTypeFilter(
    label: 'Videos',
    mimeTypes: ['video/mp4', 'video/webm', 'video/quicktime'],
    extensions: ['mp4', 'webm', 'mov'],
  );

  /// Default filter that allows any file type.
  static const FileTypeFilter any = FileTypeFilter(
    label: 'All files',
    mimeTypes: [],
    extensions: [],
  );
}

/// Options forwarded to the OS or browser's file picker dialog.
final class PickerOptions {
  /// Creates picker configuration options.
  const PickerOptions({
    this.allowMultiple = false,
    this.filters = const [FileTypeFilter.any],
    this.startDirectory,
  });

  /// Whether to allow the user to select more than one file.
  final bool allowMultiple;

  /// List of file type filters to display in the picker dialog.
  final List<FileTypeFilter> filters;

  /// Optional initial directory to open in the picker (if supported).
  final String? startDirectory;
}
