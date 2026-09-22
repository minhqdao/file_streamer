/// Maps [FileTypeFilter] lists to native picker file kinds.
///
/// Pure Dart (no file_picker import) so the mapping stays testable
/// under plain `dart test`. The caller translates [PickerFileKind]
/// to the file_picker API, which `dart analyze` pins.
library;

import 'package:file_streamer/src/picker/picker_options.dart';

/// Target file kind for the native picker dialog.
enum PickerFileKind {
  /// Any file; no extension filtering.
  any,

  /// Image files only.
  image,

  /// Video files only.
  video,

  /// Custom extension list.
  custom,
}

/// Maps [filters] to a [PickerFileKind] plus custom [extensions].
///
/// An empty list or any [FileTypeFilter.any] entry selects
/// [PickerFileKind.any]; uniformly image/video lists select their
/// kind; anything else selects [PickerFileKind.custom] with the
/// flattened extensions. [extensions] is empty unless the kind is
/// custom.
({PickerFileKind kind, List<String> extensions}) resolvePickerFilter(
  List<FileTypeFilter> filters,
) {
  if (filters.isEmpty || filters.any((f) => f == FileTypeFilter.any)) {
    return (kind: PickerFileKind.any, extensions: const []);
  }
  if (filters.every((f) => f == FileTypeFilter.images)) {
    return (kind: PickerFileKind.image, extensions: const []);
  }
  if (filters.every((f) => f == FileTypeFilter.videos)) {
    return (kind: PickerFileKind.video, extensions: const []);
  }
  return (
    kind: PickerFileKind.custom,
    extensions: filters.expand((f) => f.extensions).toList(),
  );
}
