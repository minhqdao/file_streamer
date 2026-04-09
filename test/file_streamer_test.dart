@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_streamer/file_streamer.dart';
import 'package:file_streamer/src/interface.dart';
import 'package:file_streamer/src/io_impl.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    FileStreamerPlatform.instance = FileStreamerIO();
  });

  group('FileStreamer (Flutter Native)', () {
    test('isSupported should be true on VM', () {
      expect(FileStreamer.isSupported, isTrue);
    });

    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('file_streamer_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should stream file contents correctly', () async {
      final filePath = p.join(tempDir.path, 'test_file.txt');
      final content = 'Hello, File Streamer! ' * 100;
      final expectedBytes = Uint8List.fromList(content.codeUnits);
      File(filePath).writeAsBytesSync(expectedBytes);

      final pickedFile = pickedFileFromPath(filePath);
      expect(pickedFile.mimeType, equals('text/plain'));
      final stream = FileStreamer.openReadStream(pickedFile);

      final List<int> streamedBytes = [];
      await for (final chunk in stream) {
        streamedBytes.addAll(chunk);
      }

      expect(Uint8List.fromList(streamedBytes), equals(expectedBytes));
      expect(pickedFile.size, equals(expectedBytes.length));
    });
  });
}
