// lib/src/picker/platform/picker_ffi.dart
import 'dart:io' as io;
import 'package:file_picker/file_picker.dart' as fp;
import 'package:streamed_file_uploader/src/picker/picked_file.dart';
import 'package:streamed_file_uploader/src/picker/picker_exceptions.dart';
import 'package:streamed_file_uploader/src/picker/picker_options.dart';
import 'package:streamed_file_uploader/src/picker/picker_result.dart';

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

    final result = await fp.FilePicker.pickFiles(
      allowMultiple: options.allowMultiple,
      type: type,
      allowedExtensions: allowedExtensions,
      initialDirectory: options.startDirectory,
    );

    if (result == null || result.files.isEmpty) {
      return const FilePickerResult(files: []);
    }

    final pickedFiles = <PickedFile<String>>[];
    for (final platformFile in result.files) {
      final path = platformFile.path;
      if (path == null) continue;

      final stat = io.File(path).statSync();
      pickedFiles.add(PickedFile(
        name: platformFile.name,
        size: platformFile.size,
        mimeType: _mimeFromExtension(
          path.contains('.') ? path.substring(path.lastIndexOf('.')) : '',
        ),
        lastModified: stat.modified,
        handle: path,
      ));
    }

    return FilePickerResult(files: pickedFiles);
  } on Object catch (e) {
    throw FilePickerException('Native file picker failed', cause: e);
  }
}

String _mimeFromExtension(String ext) => switch (ext.toLowerCase()) {
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.png' => 'image/png',
      '.gif' => 'image/gif',
      '.webp' => 'image/webp',
      '.mp4' => 'video/mp4',
      '.webm' => 'video/webm',
      '.mov' => 'video/quicktime',
      '.pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
