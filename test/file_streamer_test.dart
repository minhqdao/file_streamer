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

  group('FileTypeFilter', () {
    test('fromMime should resolve common extensions', () {
      final filter = FileTypeFilter.fromMime('application/pdf');
      expect(filter.mimeTypes, contains('application/pdf'));
      expect(filter.extensions, contains('pdf'));
    });

    test('fromExtension should resolve common mime types', () {
      final filter = FileTypeFilter.fromExtension('png');
      expect(filter.mimeTypes, contains('image/png'));
      expect(filter.extensions, contains('png'));
    });
  });

  group('FileStreamer (Native IO)', () {
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

    test('should respect chunkSize when streaming', () async {
      final filePath = p.join(tempDir.path, 'large_chunk_file.bin');
      const totalSize = 1024 * 10;
      const chunkSize = 1024;
      final originalData = Uint8List(totalSize);
      for (var i = 0; i < totalSize; i++) {
        originalData[i] = i % 256;
      }
      File(filePath).writeAsBytesSync(originalData);

      final pickedFile = pickedFileFromPath(filePath);
      final stream = FileStreamer.openReadStream(
        pickedFile,
        options: const ReadStreamOptions(chunkSize: chunkSize),
      );

      var chunkCount = 0;
      final List<int> combinedData = [];
      await for (final chunk in stream) {
        chunkCount++;
        combinedData.addAll(chunk);
      }

      expect(chunkCount, equals(totalSize ~/ chunkSize));
      expect(Uint8List.fromList(combinedData), equals(originalData));
    });

    test('should handle empty files', () async {
      final filePath = p.join(tempDir.path, 'empty.txt');
      File(filePath).writeAsBytesSync([]);

      final pickedFile = pickedFileFromPath(filePath);
      expect(pickedFile.size, equals(0));

      final stream = FileStreamer.openReadStream(pickedFile);
      final result = await stream.toList();

      expect(result, isEmpty);
    });

    test('should handle files smaller than chunkSize', () async {
      final filePath = p.join(tempDir.path, 'small.txt');
      final data = Uint8List.fromList([1, 2, 3]);
      File(filePath).writeAsBytesSync(data);

      final pickedFile = pickedFileFromPath(filePath);
      final stream = FileStreamer.openReadStream(
        pickedFile,
        options: const ReadStreamOptions(chunkSize: 100),
      );

      final chunks = await stream.toList();
      expect(chunks.length, equals(1));
      expect(chunks.first, equals(data));
    });

    test('should handle files that are exact multiple of chunkSize', () async {
      final filePath = p.join(tempDir.path, 'multiple.bin');
      const chunkSize = 10;
      final data = Uint8List(chunkSize * 3);
      File(filePath).writeAsBytesSync(data);

      final pickedFile = pickedFileFromPath(filePath);
      final stream = FileStreamer.openReadStream(
        pickedFile,
        options: const ReadStreamOptions(chunkSize: chunkSize),
      );

      final chunks = await stream.toList();
      expect(chunks.length, equals(3));
      for (final chunk in chunks) {
        expect(chunk.length, equals(chunkSize));
      }
    });

    test('should throw ReadStreamException for non-existent files', () {
      final nonExistentPath = p.join(tempDir.path, 'does_not_exist.txt');
      final pickedFile = pickedFileFromPath(nonExistentPath);
      final stream = FileStreamer.openReadStream(pickedFile);

      expect(
        () => stream.drain(),
        throwsA(isA<ReadStreamException>()),
      );
    });
  });
}
