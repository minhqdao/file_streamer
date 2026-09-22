@TestOn('vm')
library;

import 'dart:io';

import 'package:file_streamer/src/picker/file_stats.dart';
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

    test('missing file resolves to size 0 and epoch', () async {
      final resolved = await resolveNativeFileStat('${tempDir.path}/gone.txt');

      expect(resolved.size, 0);
      expect(resolved.lastModified, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('stat failure keeps the reported length', () async {
      final resolved = await resolveNativeFileStat(
        '${tempDir.path}/gone.txt',
        syncLength: 9,
      );

      expect(resolved.size, 9);
    });
  });
}
