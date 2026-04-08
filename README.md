## `streamed_file_uploader`

A high-performance, memory-efficient file uploader for Flutter and Dart. It avoids pre-loading the entire file into RAM before processing by piping data as a stream.

## Usage

```dart
import 'package:streamed_file_uploader/streamed_file_uploader.dart';

Future<void> main() async {
  // 1. Pick one or more images
  final result = await StreamedFileUploader.pickFiles(
    const PickerOptions(
      allowMultiple: false,
      filters: [FileTypeFilter.images],
    ),
  );

  if (result.isEmpty) return;

  final file = result.files.first;
  print('Selected: ${file.name} (${file.size} bytes)');

  // 2. Open a read stream
  final stream = StreamedFileUploader.openReadStream(
    file,
    options: const ReadStreamOptions(chunkSize: 1024 * 512), // 512 KB chunks
  );

  // 3. Pipe to your destination (e.g., an HTTP client or AWS S3)
  int bytesRead = 0;
  await for (final chunk in stream) {
    bytesRead += chunk.length;
    final progress = (bytesRead / file.size * 100).toStringAsFixed(1);
    print('Progress: $progress%');

    // await myHttpClient.post(url, body: chunk);
  }
}
```

## Features
- **Constant-RAM**: Handles 2GB+ files with the same memory footprint as a 10KB file.
- **True Streaming**: Pipes data directly from the OS buffer to a Dart `Stream<Uint8List>`.
- **Wasm-Native**: Built using `dart:js_interop` and `package:web` (No legacy `dart:html`).
- **Modern Standards**: Leverages the **File System Access API** with fallbacks for older systems.
- **Pure Dart**: 100% UI-agnostic. Works on Web, Mobile, Desktop, and the CLI.

## Setup

macOS apps require file access entitlements to read user-selected files.

Add the following to both `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:

```xml
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
