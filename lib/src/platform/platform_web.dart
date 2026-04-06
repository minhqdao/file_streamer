import 'package:streamed_file_uploader/src/interface.dart';
import 'package:streamed_file_uploader/src/web_impl.dart';

StreamedFileUploaderPlatform<Object> createPlatform() =>
    StreamedFileUploaderWeb();
