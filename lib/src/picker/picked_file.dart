// lib/src/picker/picked_file.dart
/// Immutable metadata describing a file selected by the user.
///
/// [H] is the platform-specific handle type:
///  - `PickedFile<FileSystemFileHandle>` on Web
///  - `PickedFile<String>` (absolute path) on native
final class PickedFile<H extends Object> {
  /// Creates a metadata object for a selected file.
  const PickedFile({
    required this.name,
    required this.size,
    required this.mimeType,
    required this.lastModified,
    required this.handle,
  }) : assert(size >= 0, 'size must be non-negative');

  /// File name as reported by the OS / browser (e.g. "photo.jpg").
  final String name;

  /// File size in bytes. May be 0 if the platform cannot determine it.
  final int size;

  /// MIME type string, e.g. "image/jpeg". Empty string if unknown.
  final String mimeType;

  /// Last-modified timestamp. Epoch if unavailable.
  final DateTime lastModified;

  /// Opaque platform-specific handle used internally to access the file.
  ///
  /// Do not depend on its type or contents.
  final H handle;

  @override
  String toString() =>
      'PickedFile<$H>(name: $name, size: ${_formatSize(size)}, mimeType: $mimeType)';

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }
}
