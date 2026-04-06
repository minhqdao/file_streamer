// lib/src/interface.dart
//
// Abstract interface for streamed_file_uploader.
// Platform implementations (web_impl.dart, io_impl.dart) extend this class
// and register themselves via Flutter's federated plugin mechanism.
//
// Design principles:
//  • No `dynamic` anywhere in the public surface.
//  • Returns Stream<Uint8List> — never a full in-memory Uint8List.
//  • FilePickerResult carries only metadata; bytes live in the stream.
//  • PickedFile<H> is generic over its handle type so platform impls never
//    need a runtime `is` / `as` cast (unsound for JS interop extension types).

import 'dart:async';
import 'dart:typed_data';

// ---------------------------------------------------------------------------
// Value types
// ---------------------------------------------------------------------------

/// Immutable metadata describing a file selected by the user.
///
/// [H] is the platform-specific handle type:
///  - `PickedFile<FileSystemFileHandle>` on Web
///  - `PickedFile<String>` (absolute path) on native
///
/// The actual bytes are intentionally absent; obtain them via
/// [StreamedFileUploaderPlatform.openReadStream].
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

  /// Platform-specific handle used internally by [openReadStream].
  ///
  /// Web: a JS FileSystemFileHandle.
  /// Native: an absolute file-system path String.
  ///
  /// The type parameter [H] guarantees this field is the correct type at
  /// compile time — no runtime cast is ever needed.
  final H handle;

  @override
  String toString() => 'PickedFile<$H>(name: $name, size: $size, mimeType: $mimeType)';
}

/// Result returned from a single [StreamedFileUploaderPlatform.pickFiles] call.
///
/// [H] matches the [PickedFile] handle type of the active platform impl.
final class FilePickerResult<H extends Object> {
  const FilePickerResult({required this.files});

  /// Ordered list of files chosen by the user. Empty iff the picker was
  /// cancelled (platforms should return an empty list, not throw).
  final List<PickedFile<H>> files;

  bool get isEmpty => files.isEmpty;
  bool get isNotEmpty => files.isNotEmpty;
  int get count => files.length;
}

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

/// Options for the streaming pipeline returned by [openReadStream].
final class ReadStreamOptions {
  const ReadStreamOptions({
    this.chunkSize = 256 * 1024, // 256 KiB default
  });

  final int chunkSize;
}

// ---------------------------------------------------------------------------
// Platform interface
// ---------------------------------------------------------------------------

/// Base class for platform implementations.
///
/// [H] is the handle type this implementation works with.
/// Concrete subclasses: web_impl.dart → H=FileSystemFileHandle,
///                      io_impl.dart  → H=String.
abstract base class StreamedFileUploaderPlatform<H extends Object> {
  static StreamedFileUploaderPlatform<Object>? _instance;

  static StreamedFileUploaderPlatform<Object> get instance {
    assert(
      _instance != null,
      'No StreamedFileUploaderPlatform implementation registered. '
      'Did you forget to depend on streamed_file_uploader in pubspec.yaml?',
    );
    return _instance!;
  }

  static set instance(StreamedFileUploaderPlatform<Object> impl) {
    _instance = impl;
  }

  Future<FilePickerResult<H>> pickFiles(PickerOptions options);

  Stream<Uint8List> openReadStream(
    PickedFile<H> file, {
    ReadStreamOptions options = const ReadStreamOptions(),
  });

  bool get isSupported;
}

// ---------------------------------------------------------------------------
// Exceptions
// ---------------------------------------------------------------------------

final class FilePickerException implements Exception {
  const FilePickerException(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() =>
      cause != null ? 'FilePickerException: $message (cause: $cause)' : 'FilePickerException: $message';
}

final class ReadStreamException implements Exception {
  const ReadStreamException(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() =>
      cause != null ? 'ReadStreamException: $message (cause: $cause)' : 'ReadStreamException: $message';
}
