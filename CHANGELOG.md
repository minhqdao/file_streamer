## 0.1.0

* **Universal File Access**: Supports the modern File System Access API with a transparent `<input type="file">` fallback for Safari, Firefox, and legacy browsers.
* **Low-Level Streaming**: Direct piping of OS file buffers to Dart `Stream<Uint8List>` to ensure near-zero memory pressure.
* **Cross-Platform Support**: Seamless operation across Web (JS & Wasm), Mobile, Desktop, and CLI/Server environments.
* **Dart2Wasm Compatible**: 100% `dart:js_interop` implementation, removing all legacy `dart:html` dependencies.
