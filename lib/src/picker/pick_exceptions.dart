final class FilePickerException implements Exception {
  const FilePickerException(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() => cause != null
      ? 'FilePickerException: $message (cause: $cause)'
      : 'FilePickerException: $message';
}
