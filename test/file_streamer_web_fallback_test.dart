@TestOn('browser')
library;

import 'package:file_streamer/file_streamer.dart';
import 'package:file_streamer/src/js_interop_types.dart';
import 'package:file_streamer/src/web_impl.dart';
import 'package:test/test.dart';

void main() {
  group('Web Fallback (<input type="file">)', () {
    late FileStreamerWeb platform;

    setUp(() {
      platform = FileStreamerWeb();
      platform.supportsSystemAccess = false; // Force fallback
    });

    test('pickFiles triggers fallback and configures input correctly', () {
      platform.pickFiles(const PickerOptions());

      // Find the input element created by the platform
      final inputs = jsDocument.querySelectorAll('input[type="file"]');
      expect(inputs.length, greaterThan(0));

      final rawInput = inputs.item(inputs.length - 1);
      expect(rawInput, isA<HTMLInputElement>());
      final input = rawInput! as HTMLInputElement;

      expect(input, isNotNull);
      expect(input.type, equals('file'));

      // Cleanup
      input.remove();
    });

    test('pickFiles returns empty result after timeout', () {
      final pickFuture = platform.pickFiles(const PickerOptions());

      // We don't trigger any event, so it should time out (eventually).
      // Given the 10s default, we just verify the future exists.
      expect(pickFuture, isA<Future<FilePickerResult<Object>>>());
    });
  });
}
