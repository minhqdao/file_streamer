// lib/src/picker/platform/picker_ffi.dart
import 'package:file_picker/file_picker.dart' as fp;
import 'package:file_streamer/src/picker/file_stats.dart';
import 'package:file_streamer/src/picker/picked_file.dart';
import 'package:file_streamer/src/picker/picker_exceptions.dart';
import 'package:file_streamer/src/picker/picker_options.dart';
import 'package:file_streamer/src/picker/picker_result.dart';
import 'package:mime/mime.dart';

Future<FilePickerResult<String>> pickFilesNative(PickerOptions options) async {
  try {
    final fp.FileType type;
    List<String>? allowedExtensions;

    if (options.filters.isEmpty ||
        options.filters.any((f) => f == FileTypeFilter.any)) {
      type = fp.FileType.any;
    } else if (options.filters.every((f) => f == FileTypeFilter.images)) {
      type = fp.FileType.image;
    } else if (options.filters.every((f) => f == FileTypeFilter.videos)) {
      type = fp.FileType.video;
    } else {
      type = fp.FileType.custom;
      allowedExtensions = options.filters.expand((f) => f.extensions).toList();
    }

    final List<fp.PlatformFile> platformFiles;
    if (options.allowMultiple) {
      platformFiles = await fp.FilePicker.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        initialDirectory: options.startDirectory,
      );
    } else {
      final single = await fp.FilePicker.pickFile(
        type: type,
        allowedExtensions: allowedExtensions,
        initialDirectory: options.startDirectory,
      );
      platformFiles = single == null ? const [] : [single];
    }

    if (platformFiles.isEmpty) {
      return const FilePickerResult(files: []);
    }

    final pickedFiles = <PickedFile<String>>[];
    for (final platformFile in platformFiles) {
      final path = platformFile.path;
      if (path == null) continue;

      final resolved = await resolveNativeFileStat(
        path,
        syncLength: platformFile.lengthSync(),
        readLength: platformFile.length,
      );
      pickedFiles.add(
        PickedFile(
          name: platformFile.name,
          size: resolved.size,
          mimeType: lookupMimeType(path) ?? 'application/octet-stream',
          lastModified: resolved.lastModified,
          handle: path,
        ),
      );
    }

    return FilePickerResult(files: pickedFiles);
  } on Object catch (e) {
    throw FilePickerException('Native file picker failed', cause: e);
  }
}
