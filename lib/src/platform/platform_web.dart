import 'package:file_streamer/src/interface.dart';
import 'package:file_streamer/src/web_impl.dart';

FileStreamerPlatform<Object> createPlatform() =>
    FileStreamerWeb();
