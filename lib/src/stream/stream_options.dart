// lib/src/stream/stream_options.dart
/// Options for the streaming pipeline.
final class ReadStreamOptions {
  const ReadStreamOptions({
    this.chunkSize = 256 * 1024, // 256 KiB default
  });

  final int chunkSize;
}
