/// A high-performance, memory-efficient file streamer for Flutter and Dart.
///
/// This package provides tools to select files and read their contents as
/// streams, avoiding memory-intensive pre-loading of entire files.
library;

export 'src/facade.dart' show FileStreamer, StreamableFile;
export 'src/picker/picked_file.dart' show PickedFile;
export 'src/picker/picker_exceptions.dart' show FilePickerException;
export 'src/picker/picker_options.dart' show FileTypeFilter, PickerOptions;
export 'src/picker/picker_result.dart' show FilePickerResult;
export 'src/stream/stream_exceptions.dart' show ReadStreamException;
export 'src/stream/stream_options.dart' show ReadStreamOptions;
