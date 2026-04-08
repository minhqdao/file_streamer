/// Exception thrown when a file cannot be opened or read as a stream.
final class ReadStreamException implements Exception {
  /// Creates a stream exception with a descriptive message.
  const ReadStreamException(this.message, {this.cause});

  /// Human-readable explanation of the read failure.
  final String message;

  /// The underlying error that caused this exception, if any.
  final Object? cause;

  @override
  String toString() => cause != null
      ? 'ReadStreamException: $message (cause: $cause)'
      : 'ReadStreamException: $message';
}
