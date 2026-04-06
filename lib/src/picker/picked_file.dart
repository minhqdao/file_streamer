// lib/src/picker/picked_file.dart
/// Immutable metadata describing a file selected by the user.
///
/// [H] is the platform-specific handle type:
///  - `PickedFile<FileSystemFileHandle>` on Web
///  - `PickedFile<String>` (absolute path) on native
final class PickedFile<H extends Object> {
  const PickedFile({
    required this.name,
    required this.size,
    required this.mimeType,
    required this.lastModified,
    required this.handle,
  });

  /// File name as reported by the OS / browser (e.g. "photo.jpg").
  final String name;

  /// File size in bytes. May be 0 if the platform cannot determine it.
  final int size;

  /// MIME type string, e.g. "image/jpeg". Empty string if unknown.
  final String mimeType;

  /// Last-modified timestamp. Epoch if unavailable.
  final DateTime lastModified;

  /// Platform-specific handle used internally.
  final H handle;

  @override
  String toString() =>
      'PickedFile<$H>(name: $name, size: $size, mimeType: $mimeType)';
}
