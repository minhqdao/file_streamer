import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:streamed_file_uploader/src/io_impl.dart';
import 'package:streamed_file_uploader/streamed_file_uploader.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    // Manually register the IO implementation for the test.
    StreamedFileUploaderPlatform.instance = StreamedFileUploaderIO();
  });

  group('StreamedFileUploader (Native IO)', () {
    late Directory tempDir;

    setUp(() => tempDir =
        Directory.systemTemp.createTempSync('streamed_file_uploader_test_'));

    tearDown(() => tempDir.deleteSync(recursive: true));

    test('should stream file contents correctly', () async {
      // 1. Arrange: Create a temporary file with known content.
      final filePath = p.join(tempDir.path, 'test_file.txt');
      final content = 'Hello, Streamed File Uploader! ' * 100; // ~3KB
      final expectedBytes = Uint8List.fromList(content.codeUnits);
      File(filePath).writeAsBytesSync(expectedBytes);

      // 2. Act: Use the utility to create a PickedFile and open a stream.
      final pickedFile = pickedFileFromPath(filePath);
      final stream = StreamedFileUploader.openReadStream(pickedFile);

      // 3. Assert: Collect all bytes from the stream and compare.
      final List<int> streamedBytes = [];
      await for (final chunk in stream) {
        streamedBytes.addAll(chunk);
      }

      expect(Uint8List.fromList(streamedBytes), equals(expectedBytes));
      expect(pickedFile.size, equals(expectedBytes.length));
      expect(pickedFile.name, equals('test_file.txt'));
    });

    test('should respect chunkSize when streaming', () async {
      // 1. Arrange: Create a file larger than the chunk size.
      final filePath = p.join(tempDir.path, 'large_chunk_file.bin');
      const totalSize = 1024 * 10; // 10 KiB
      const chunkSize = 1024; // 1 KiB
      final originalData = Uint8List(totalSize);
      for (var i = 0; i < totalSize; i++) {
        originalData[i] = i % 256;
      }
      File(filePath).writeAsBytesSync(originalData);

      final pickedFile = pickedFileFromPath(filePath);

      // 2. Act: Open stream with a small chunk size.
      final stream = StreamedFileUploader.openReadStream(
        pickedFile,
        options: const ReadStreamOptions(chunkSize: chunkSize),
      );

      // 3. Assert: Verify each chunk size.
      var chunkCount = 0;
      final List<int> combinedData = [];
      await for (final chunk in stream) {
        chunkCount++;
        expect(chunk.length, lessThanOrEqualTo(chunkSize));
        // All chunks except the last one should be exactly chunkSize.
        if (combinedData.length + chunk.length < totalSize) {
          expect(chunk.length, equals(chunkSize));
        }
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
  });
}
