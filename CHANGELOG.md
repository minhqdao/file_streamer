## 0.2.0

* **file_picker 13**: Migrate native picking to the `file_picker` v13 API (`pickFile()` for single picks, `pickFiles()` returning `List<PlatformFile>`, `lengthSync()`/`length()` for sizes).
* **SDK floors**: Dart `^3.10.0`, Flutter `>=3.38.0`.
* **Fix**: Files that vanish between picking and reading now fail loudly with a `FilePickerException` naming the path, instead of tripping an assert or surfacing later as a stream error.

## 0.1.0

* **Universal File Access**: Supports the modern File System Access API with a transparent `<input type="file">` fallback for Safari, Firefox, and legacy browsers.
* **Low-Level Streaming**: Direct piping of OS file buffers to Dart `Stream<Uint8List>` to ensure near-zero memory pressure.
* **Cross-Platform Support**: Seamless operation across Web (JS & Wasm), Mobile, Desktop, and CLI/Server environments.
* **Dart2Wasm Compatible**: 100% `dart:js_interop` implementation, removing all legacy `dart:html` dependencies.
