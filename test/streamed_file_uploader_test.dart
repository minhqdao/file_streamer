@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:streamed_file_uploader/src/io_impl.dart';
import 'package:streamed_file_uploader/streamed_file_uploader.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    StreamedFileUploaderPlatform.instance = StreamedFileUploaderIO();
  });

  group('StreamedFileUploader (Native IO)', () {
    test('isSupported should be true on VM', () {
      expect(StreamedFileUploader.isSupported, isTrue);
    });

    late Directory tempDir;

    setUp(() {
      tempDir =
          Directory.systemTemp.createTempSync('streamed_file_uploader_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should stream file contents correctly', () async {
      final filePath = p.join(tempDir.path, 'test_file.txt');
      final content = 'Hello, Streamed File Uploader! ' * 100;
      final expectedBytes = Uint8List.fromList(content.codeUnits);
      File(filePath).writeAsBytesSync(expectedBytes);

      final pickedFile = pickedFileFromPath(filePath);
      final stream = StreamedFileUploader.openReadStream(pickedFile);

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
      final stream = StreamedFileUploader.openReadStream(
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

    test('should throw ReadStreamException for non-existent files', () {
      final nonExistentPath = p.join(tempDir.path, 'does_not_exist.txt');

      final pickedFile = pickedFileFromPath(nonExistentPath);

      final stream = StreamedFileUploader.openReadStream(pickedFile);

      expect(
        () => stream.drain(),
        throwsA(isA<ReadStreamException>()),
      );
    });

    test('openReadStreamFromBlob should throw on native platform', () {
      final stream = StreamedFileUploader.openReadStreamFromBlob(Object());
      expect(
        () => stream.drain(),
        throwsA(isA<ReadStreamException>()),
      );
    });
  });
}
