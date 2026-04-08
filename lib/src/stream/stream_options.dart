// lib/src/stream/stream_options.dart
/// Options for configuring the file reading stream.
final class ReadStreamOptions {
  /// Creates read stream configuration options.
  const ReadStreamOptions({
    this.chunkSize = 256 * 1024, // 256 KiB default
  });

  /// The size of each data chunk emitted by the stream, in bytes.
  ///
  /// Defaults to 256 KiB. Larger chunks may be more efficient for uploads,
  /// while smaller chunks use less memory.
  final int chunkSize;
}
