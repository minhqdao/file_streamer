import 'dart:typed_data';

import 'package:file_streamer/src/facade.dart';
import 'package:file_streamer/src/picker/picked_file.dart';
import 'package:file_streamer/src/stream/stream_options.dart';

/// A handle to a file that can be read as a stream.
final class StreamableFile {
  /// The underlying metadata for this file.
  final PickedFile<Object> file;

  /// Creates a [StreamableFile] wrapping a [PickedFile].
  const StreamableFile(this.file);

  /// Opens a stream to read the file's contents in chunks.
  Stream<Uint8List> openRead({
    ReadStreamOptions options = const ReadStreamOptions(),
  }) =>
      FileStreamer.openReadStream(file, options: options);
}
