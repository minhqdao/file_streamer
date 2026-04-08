import 'package:file_streamer/src/interface.dart';
import 'package:file_streamer/src/io_impl.dart';

FileStreamerPlatform<Object> createPlatform() =>
    FileStreamerIO();
