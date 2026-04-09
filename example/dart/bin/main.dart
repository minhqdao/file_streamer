import 'dart:io';
import 'package:file_streamer/file_streamer.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    stdout.writeln('Missing argument.\n\nUsage: dart main.dart <path-to-file>');
    return;
  }

  final filePath = args[0];
  final file = File(filePath);

  if (!await file.exists()) {
    stdout.writeln('Error: File not found.');
    return;
  }

  stdout.writeln('Streaming ${file.path} (${await file.length()} bytes)...');

  // Demonstrate the zero-memory stream
  final streamer = FileStreamer.fromPath(file.path);

  int totalBytes = 0;
  await for (final chunk in streamer.openRead()) {
    totalBytes += chunk.length;
    // Log progress without flooding the console
    stdout.write('\r$totalBytes bytes streamed...');
  }

  stdout.writeln('\nStreaming complete.');
}
