## `file_streamer`

A high-performance, constant-memory file streamer for Flutter and Dart. It avoids pre-loading the entire file into RAM and instead pipes data directly as a stream.

## Usage

```dart
import 'dart:typed_data';
import 'package:file_streamer/file_streamer.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  // 1. Pick files
  final result = await FileStreamer.pickFiles(
    const PickerOptions(
      allowMultiple: true,
      filters: [FileTypeFilter.images],
    ),
  );

  if (result.isEmpty) return;

  // 2 + 3. Stream and upload each file
  for (final file in result.files) {
    print('Uploading: ${file.name} (${file.size} bytes)');

    final stream = FileStreamer.openReadStream(
      file,
      options: const ReadStreamOptions(chunkSize: 512 * 1024), // 512 KB
    );

    final request = http.StreamedRequest(
      'POST',
      Uri.parse('https://httpbin.org/post'),
    );

    request.headers['Content-Type'] = 'application/octet-stream';
    request.contentLength = file.size;

    int uploaded = 0;

    final progressStream = stream.map((Uint8List chunk) {
      uploaded += chunk.length;
      final progress = file.size > 0
          ? (uploaded / file.size * 100).toStringAsFixed(1)
          : '0.0';

      print('${file.name}: $progress%');
      return chunk;
    });

    final responseFuture = request.send();

    await request.sink.addStream(progressStream);
    await request.sink.close();

    final response = await responseFuture;
    await response.stream.drain();

    print('${file.name}: done (${response.statusCode})\n');
  }
}
```

Find complete [flutter](example/flutter/) and [dart](example/dart/) examples in the [example](example) folder.

## Features
- **Constant-RAM**: Handles 2GB+ files with the same memory footprint as a 10KB file.
- **True Streaming**: Pipes data straight from the OS buffer to a Dart `Stream<Uint8List>`.
- **Upload-Ready**: Directly feed network requests with minimal intermediate RAM overhead.
- **Modern Standards**: Leverages the **File System Access API** with fallbacks for older systems.
- **Wasm-Native**: Built using `dart:js_interop` and `package:web` (No legacy `dart:html`).
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
```

If you want to upload files, you also need to enable outgoing connections in your App Sandbox:

1. Open `macos/Runner.xcworkspace` in Xcode.
2. Select the **Runner** project in the project navigator.
3. Go to the **Signing & Capabilities** tab.
4. Under **App Sandbox** -> **Network**, check **Outgoing Connections (Client)**.

## Tests

Run `vm`-annotated tests with:

```bash
dart test
````

`Browser` tests are ran with:

```bash
dart test -p chrome
```
