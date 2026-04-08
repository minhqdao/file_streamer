@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_streamer/file_streamer.dart';
import 'package:file_streamer/src/interface.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

void main() {
  test('isSupported should reflect browser capabilities', () {
    // In headless chrome, this should generally be true if the API is there
    expect(FileStreamer.isSupported, isA<bool>());
  });

  group('Web Stream: openReadStreamFromBlob', () {
    test('converts web.Blob to Dart Stream', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]).toJS;
      final blob = web.Blob(<JSUint8Array>[bytes].toJS);

      final stream = FileStreamerPlatform.instance.openReadStreamFromBlob(blob);

      final result = await stream.expand((bin) => bin).toList();
      expect(result, equals([1, 2, 3, 4, 5]));
    });

    test('respects chunkSize for large blobs', () async {
      const totalSize = 10 * 1024; // 10KB
      const chunkSize = 1024; // 1KB
      final bytes = Uint8List(totalSize);
      for (var i = 0; i < totalSize; i++) {
        bytes[i] = i % 256;
      }

      final blob = web.Blob(<JSUint8Array>[bytes.toJS].toJS);

      final stream = FileStreamerPlatform.instance.openReadStreamFromBlob(
        blob,
        options: const ReadStreamOptions(chunkSize: chunkSize),
      );

      var chunkCount = 0;
      final List<int> combined = [];
      await for (final chunk in stream) {
        chunkCount++;
        expect(chunk.length, lessThanOrEqualTo(chunkSize));
        combined.addAll(chunk);
      }

      expect(chunkCount, equals(totalSize ~/ chunkSize));
      expect(Uint8List.fromList(combined), equals(bytes));
    });

    test('handles empty blobs', () async {
      final blob = web.Blob(<JSUint8Array>[].toJS);
      final stream = FileStreamerPlatform.instance.openReadStreamFromBlob(blob);

      final result = await stream.toList();
      expect(result, isEmpty);
    });

    test('respects back-pressure (paused stream)', () async {
      const totalSize = 10 * 1024;
      const chunkSize = 1024;
      final bytes = Uint8List(totalSize);
      final blob = web.Blob(<JSUint8Array>[bytes.toJS].toJS);

      final stream = FileStreamerPlatform.instance.openReadStreamFromBlob(
        blob,
        options: const ReadStreamOptions(chunkSize: chunkSize),
      );

      final List<Uint8List> results = [];
      final subscription = stream.listen((chunk) {
        results.add(chunk);
      });

      subscription.pause();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      // Should not have more than one chunk if it was already in flight,
      // but here it should have 0 or 1.
      expect(results.length, lessThanOrEqualTo(1));

      subscription.resume();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      // Now it should have progressed.
      expect(results.length, greaterThan(1));

      await subscription.cancel();
    });
  });
}
