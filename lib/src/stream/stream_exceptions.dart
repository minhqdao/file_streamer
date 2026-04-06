final class ReadStreamException implements Exception {
  const ReadStreamException(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() => cause != null
      ? 'ReadStreamException: $message (cause: $cause)'
      : 'ReadStreamException: $message';
}
