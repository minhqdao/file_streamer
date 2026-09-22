/// Helpers to resolve size and modification time for natively
/// picked files. Pure Dart (no file_picker import) so it stays
/// testable under plain `dart test`.
library;

import 'dart:io' as io;

import 'package:file_streamer/src/picker/picker_exceptions.dart';

/// Resolves the [size] and [lastModified] of a picked native [path].
///
/// [syncLength] is the size reported without I/O
/// (PlatformFile.lengthSync), [readLength] resolves it with I/O
/// (PlatformFile.length). Falls back to a filesystem stat.
///
/// Fails loudly with [FilePickerException] naming [path] when the
/// file is missing or inaccessible: statSync() reports notFound
/// with size -1 instead of throwing, which must not leak into
/// PickedFile's non-negative size assert as a fictional size 0.
Future<({int size, DateTime lastModified})> resolveNativeFileStat(
  String path, {
  int? syncLength,
  Future<int?> Function()? readLength,
}) async {
  try {
    final stat = io.File(path).statSync();
    if (stat.type == io.FileSystemEntityType.notFound) {
      throw FilePickerException('Picked file is no longer accessible: $path');
    }
    final size = syncLength ?? await readLength?.call() ?? stat.size;
    return (size: size, lastModified: stat.modified);
  } on FilePickerException {
    rethrow;
  } on Object catch (e) {
    throw FilePickerException('Cannot access picked file: $path', cause: e);
  }
}
