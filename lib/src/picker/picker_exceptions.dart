/// Exception thrown when a file selection operation fails or is cancelled.
final class FilePickerException implements Exception {
  /// Creates a file picker exception with a descriptive message.
  const FilePickerException(this.message, {this.cause});

  /// Human-readable explanation of the failure.
  final String message;

  /// The underlying error that caused this exception, if any.
  final Object? cause;

  @override
  String toString() => cause != null
      ? 'FilePickerException: $message (cause: $cause)'
      : 'FilePickerException: $message';
}
