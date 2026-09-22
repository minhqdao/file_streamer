@TestOn('vm')
library;

import 'package:file_streamer/src/picker/filter_mapping.dart';
import 'package:file_streamer/src/picker/picker_options.dart';
import 'package:test/test.dart';

void main() {
  group('resolvePickerFilter', () {
    test('empty filters select any', () {
      final resolved = resolvePickerFilter(const []);

      expect(resolved.kind, PickerFileKind.any);
      expect(resolved.extensions, isEmpty);
    });

    test('any filter wins over others', () {
      final resolved = resolvePickerFilter(const [
        FileTypeFilter.any,
        FileTypeFilter.images,
      ]);

      expect(resolved.kind, PickerFileKind.any);
      expect(resolved.extensions, isEmpty);
    });

    test('uniform image filters select image', () {
      final resolved = resolvePickerFilter(const [
        FileTypeFilter.images,
        FileTypeFilter.images,
      ]);

      expect(resolved.kind, PickerFileKind.image);
      expect(resolved.extensions, isEmpty);
    });

    test('uniform video filters select video', () {
      final resolved = resolvePickerFilter(const [FileTypeFilter.videos]);

      expect(resolved.kind, PickerFileKind.video);
      expect(resolved.extensions, isEmpty);
    });

    test('mixed image and video filters select custom', () {
      final resolved = resolvePickerFilter(const [
        FileTypeFilter.images,
        FileTypeFilter.videos,
      ]);

      expect(resolved.kind, PickerFileKind.custom);
      expect(resolved.extensions, containsAll(['png', 'jpg', 'mp4', 'mov']));
    });

    test('single custom filter selects custom extensions', () {
      final resolved = resolvePickerFilter([
        FileTypeFilter.fromExtension('pdf'),
      ]);

      expect(resolved.kind, PickerFileKind.custom);
      expect(resolved.extensions, ['pdf']);
    });

    test('mime filter selects custom extensions', () {
      final resolved = resolvePickerFilter([
        FileTypeFilter.fromMime('application/pdf'),
      ]);

      expect(resolved.kind, PickerFileKind.custom);
      expect(resolved.extensions, ['pdf']);
    });
  });
}
