/// Helpers to resolve size and modification time for natively
/// picked files. Pure Dart (no file_picker import) so it stays
/// testable under plain `dart test`.
library;

import 'dart:io' as io;

/// Resolves the [size] and [lastModified] of a picked native [path].
///
/// [syncLength] is the size reported without I/O
/// (PlatformFile.lengthSync), [readLength] resolves it with I/O
/// (PlatformFile.length). Falls back to a filesystem stat, then to
/// size 0 and epoch when the file is missing: statSync() reports
/// notFound with size -1 instead of throwing, which must not leak
/// into PickedFile's non-negative size assert.
Future<({int size, DateTime lastModified})> resolveNativeFileStat(
  String path, {
  int? syncLength,
  Future<int?> Function()? readLength,
}) async {
  int? statSize;
  var lastModified = DateTime.fromMillisecondsSinceEpoch(0);
  try {
    final stat = io.File(path).statSync();
    if (stat.type != io.FileSystemEntityType.notFound) {
      statSize = stat.size;
      lastModified = stat.modified;
    }
  } on Object {
    // Keep epoch fallback when stat fails.
  }
  final size = syncLength ?? await readLength?.call() ?? statSize ?? 0;
  return (size: size, lastModified: lastModified);
}
