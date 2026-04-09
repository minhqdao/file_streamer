import 'dart:io';
import 'dart:typed_data';
import 'package:file_streamer/file_streamer.dart';
import 'package:http/http.dart' as http;

void main(List<String> args) async {
  if (args.isEmpty) {
    stdout.writeln('Missing argument.\n\nUsage: dart main.dart <path-to-file>');
    return;
  }

  final path = args[0];
  final file = File(path);

  if (!await file.exists()) {
    stdout.writeln('Error: File not found.');
    return;
  }

  final size = await file.length();
  stdout.writeln('Uploading $path ($size bytes)...');

  try {
    final streamable = FileStreamer.fromPath(path);
    final response = await _uploadFile(streamable);
    await response.stream.drain();

    stdout.writeln('\nUpload complete.');
    stdout.writeln('Status: ${response.statusCode}');
  } catch (e) {
    stdout.writeln('\nUpload failed: $e');
  }
}

Future<http.StreamedResponse> _uploadFile(StreamableFile streamable) async {
  final file = streamable.file;

  final request = http.StreamedRequest(
    'POST',
    Uri.parse('https://httpbin.org/post'),
  );

  request.headers['Content-Type'] = 'application/octet-stream';
  request.contentLength = file.size;

  int uploaded = 0;

  final stream = streamable.openRead();

  final progressStream = stream.map((Uint8List chunk) {
    uploaded += chunk.length;

    final progress = file.size > 0
        ? (uploaded / file.size).clamp(0.0, 1.0)
        : 0.0;

    stdout.write('\rProgress: ${(progress * 100).toStringAsFixed(1)}%');

    return chunk;
  });

  final responseFuture = request.send();

  await request.sink.addStream(progressStream);
  await request.sink.close();

  return await responseFuture;
}
