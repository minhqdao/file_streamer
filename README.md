## `streamed_file_uploader`

A high-performance, memory-efficient file uploader for Flutter and Dart. Avoids pre-loading the entire file into RAM before processing by piping data as a stream.

## Usage

## Features
- **Zero-RAM Bottleneck**: Handles 2GB+ files with the same memory footprint as a 10KB file.
- **True Streaming**: Pipes data directly from the OS buffer to a Dart `Stream<Uint8List>`.
- **Wasm-Native**: Built using `dart:js_interop` and `package:web` (No legacy `dart:html`).
- **Modern Standards**: Leverages the **File System Access API** with fallbacks for older systems.
- **Pure Dart**: 100% UI-agnostic. Works on Web, Mobile, Desktop, and the CLI.

