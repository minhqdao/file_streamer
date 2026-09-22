@TestOn('vm')
library;

import 'dart:io';

import 'package:file_streamer/src/picker/file_stats.dart';
import 'package:file_streamer/src/picker/picker_exceptions.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('file_stats_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('resolveNativeFileStat', () {
    test('uses stat size and modified for existing files', () async {
      final file = File('${tempDir.path}/a.txt')..writeAsBytesSync([1, 2, 3]);
      final stat = file.statSync();

      final resolved = await resolveNativeFileStat(file.path);

      expect(resolved.size, stat.size);
      expect(resolved.lastModified, stat.modified);
    });

    test('prefers syncLength over stat', () async {
      final file = File('${tempDir.path}/a.txt')..writeAsBytesSync([1, 2, 3]);

      final resolved = await resolveNativeFileStat(file.path, syncLength: 42);

      expect(resolved.size, 42);
    });

    test('prefers readLength over stat', () async {
      final file = File('${tempDir.path}/a.txt')..writeAsBytesSync([1, 2, 3]);

      final resolved = await resolveNativeFileStat(
        file.path,
        readLength: () async => 7,
      );

      expect(resolved.size, 7);
    });

    test('missing file fails loudly with its path', () async {
      await expectLater(
        resolveNativeFileStat('${tempDir.path}/gone.txt'),
        throwsA(
          isA<FilePickerException>().having(
            (e) => e.message,
            'message',
            contains('gone.txt'),
          ),
        ),
      );
    });

    test('missing file fails even with reported length', () async {
      await expectLater(
        resolveNativeFileStat('${tempDir.path}/gone.txt', syncLength: 9),
        throwsA(isA<FilePickerException>()),
      );
    });
  });
}
