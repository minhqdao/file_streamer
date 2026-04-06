import 'package:streamed_file_uploader/src/interface.dart';
import 'package:streamed_file_uploader/src/io_impl.dart';

StreamedFileUploaderPlatform<Object> createPlatform() =>
    StreamedFileUploaderIO();
