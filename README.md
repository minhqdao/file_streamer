## `file_streamer`

A high-performance, constant-memory file streamer for Flutter and Dart. It avoids pre-loading the entire file into RAM and instead pipes data directly as a stream.

## Usage

```dart
import 'package:file_streamer/file_streamer.dart';

Future<void> main() async {
  // 1. Pick one or more images
  final result = await FileStreamer.pickFiles(
    const PickerOptions(
      allowMultiple: false,
      filters: [FileTypeFilter.images],
    ),
  );

  if (result.isEmpty) return;

  final file = result.files.first;
  print('Selected: ${file.name} (${file.size} bytes)');

  // 2. Open a read stream
  final stream = FileStreamer.openReadStream(
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

## Installation

Run

```bash
dart pub add file_streamer
```

in your project root or add:

```yaml
file_streamer: ^0.1.0
```

to the dependencies section in your `pubspec.yaml`.

## Setup

### macOS

macOS apps require file access entitlements to read user-selected files.

Add the following to `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:

```xml
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
