import 'dart:io';
import 'dart:typed_data';
import 'package:file_streamer/file_streamer.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  // 1. Pick files
  final result = await FileStreamer.pickFiles(
    const PickerOptions(allowMultiple: true, filters: [FileTypeFilter.images]),
  );

  if (result.isEmpty) return;

  // 2 + 3. Stream and upload each file
  for (final file in result.files) {
    stdout.writeln('Uploading: ${file.name} (${file.size} bytes)');

    final stream = FileStreamer.openReadStream(
      file,
      options: const ReadStreamOptions(chunkSize: 512 * 1024), // 512 KB
    );

    final request = http.StreamedRequest(
      'POST',
      Uri.parse('https://httpbin.org/post'),
    );

    request.headers['Content-Type'] = 'application/octet-stream';
    request.contentLength = file.size;

    int uploaded = 0;

    final progressStream = stream.map((Uint8List chunk) {
      uploaded += chunk.length;
      final progress = file.size > 0
          ? (uploaded / file.size * 100).toStringAsFixed(1)
          : '0.0';

      stdout.writeln('${file.name}: $progress%');
      return chunk;
    });

    final responseFuture = request.send();

    await request.sink.addStream(progressStream);
    await request.sink.close();

    final response = await responseFuture;
    await response.stream.drain();

    stdout.writeln('${file.name}: done (${response.statusCode})\n');
  }
}
