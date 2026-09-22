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

  group('FileTypeFilter (CLI)', () {
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

  group('FileStreamer.fromPath (CLI)', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('file_streamer_cli_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should stream from local path', () async {
      final filePath = p.join(tempDir.path, 'path_test.txt');
      const content = 'Path streaming test content';
      File(filePath).writeAsStringSync(content);

      final streamer = FileStreamer.fromPath(filePath);
      expect(streamer.file.name, equals('path_test.txt'));

      final chunks = await streamer.openRead().toList();
      final streamedContent = String.fromCharCodes(chunks.expand((c) => c));
      expect(streamedContent, equals(content));
    });

    test('StreamableFile.openRead should respect ReadStreamOptions', () async {
      final filePath = p.join(tempDir.path, 'options_test.txt');
      final content = Uint8List.fromList(List.generate(100, (i) => i));
      File(filePath).writeAsBytesSync(content);

      final streamer = FileStreamer.fromPath(filePath);
      final stream = streamer.openRead(
        options: const ReadStreamOptions(chunkSize: 10),
      );

      final chunks = await stream.toList();
      expect(chunks.length, equals(10));
      expect(
        Uint8List.fromList(chunks.expand((c) => c).toList()),
        equals(content),
      );
    });

    test('should throw error for non-existent path', () {
      final nonExistent = p.join(tempDir.path, 'missing.txt');
      final streamer = FileStreamer.fromPath(nonExistent);

      expect(
        () => streamer.openRead().drain(),
        throwsA(isA<ReadStreamException>()),
      );
    });
  });

  group('FileStreamer large-file streaming (CLI)', () {
    // Proves the constant-memory claim structurally: fixed-size
    // chunks are the bounded footprint (the rechunk buffer never
    // exceeds chunkSize). Deliberately no RSS assertion: process
    // RSS depends on GC timing, so any bound is flaky by
    // construction, with or without coverage instrumentation.
    const totalSize = 100 * 1024 * 1024; // 100 MB
    const chunkSize = 64 * 1024; // 64 KB -> exactly 1600 chunks
    const sliceSize = 1024 * 1024; // 1 MB setup slices

    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('file_streamer_big_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test(
      'streams 100 MB in fixed-size chunks with verified integrity',
      timeout: const Timeout(Duration(minutes: 3)),
      () async {
        final filePath = p.join(tempDir.path, 'big.bin');
        final file = File(filePath);
        final slice = Uint8List(sliceSize);
        var expectedChecksum = 0;
        var offset = 0;
        while (offset < totalSize) {
          for (var i = 0; i < sliceSize; i++) {
            final byte = (offset + i) % 256;
            slice[i] = byte;
            expectedChecksum = (expectedChecksum * 31 + byte) & 0x3fffffff;
          }
          file.writeAsBytesSync(slice, mode: FileMode.append);
          offset += sliceSize;
        }

        final streamer = FileStreamer.fromPath(filePath);
        var actualChecksum = 0;
        var readOffset = 0;
        var chunkCount = 0;
        await for (final chunk in streamer.openRead(
          options: const ReadStreamOptions(chunkSize: chunkSize),
        )) {
          expect(chunk.length, lessThanOrEqualTo(chunkSize));
          for (var i = 0; i < chunk.length; i++) {
            actualChecksum = (actualChecksum * 31 + chunk[i]) & 0x3fffffff;
          }
          readOffset += chunk.length;
          chunkCount++;
        }

        expect(readOffset, totalSize);
        expect(chunkCount, totalSize ~/ chunkSize);
        expect(actualChecksum, expectedChecksum);
      },
    );
  });

  group('FileStreamer (Pure IO - CLI)', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'file_streamer_cli_io_test_',
      );
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
    });

    test('should handle empty files', () async {
      final filePath = p.join(tempDir.path, 'empty.txt');
      File(filePath).writeAsBytesSync([]);

      final pickedFile = pickedFileFromPath(filePath);
      final stream = FileStreamer.openReadStream(pickedFile);
      final result = await stream.toList();

      expect(result, isEmpty);
    });
  });
}
