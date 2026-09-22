// lib/src/picker/platform/picker_ffi.dart
import 'package:file_picker/file_picker.dart' as fp;
import 'package:file_streamer/src/picker/file_stats.dart';
import 'package:file_streamer/src/picker/filter_mapping.dart';
import 'package:file_streamer/src/picker/picked_file.dart';
import 'package:file_streamer/src/picker/picker_exceptions.dart';
import 'package:file_streamer/src/picker/picker_options.dart';
import 'package:file_streamer/src/picker/picker_result.dart';
import 'package:mime/mime.dart';

Future<FilePickerResult<String>> pickFilesNative(PickerOptions options) async {
  try {
    final filter = resolvePickerFilter(options.filters);
    final fp.FileType type = switch (filter.kind) {
      PickerFileKind.any => fp.FileType.any,
      PickerFileKind.image => fp.FileType.image,
      PickerFileKind.video => fp.FileType.video,
      PickerFileKind.custom => fp.FileType.custom,
    };
    final List<String>? allowedExtensions = filter.kind == PickerFileKind.custom
        ? filter.extensions
        : null;

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
