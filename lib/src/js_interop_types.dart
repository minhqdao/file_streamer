// Extension types for every JS object this package touches.
// Uses dart:js_interop exclusively — zero dart:html imports.
// Compatible with dart2js AND dart2wasm.
import 'dart:js_interop';
// setProperty / getProperty / operator[] on JSObject live here, not in
// dart:js_interop itself. Wasm-compatible; the name is a warning, not a ban.
import 'dart:js_interop_unsafe';

// ---------------------------------------------------------------------------
// File System Access API
// ---------------------------------------------------------------------------

/// `FileSystemFileHandle` — returned by `window.showOpenFilePicker()`.
extension type FileSystemFileHandle._(JSObject _) implements JSObject {
  /// `FileSystemHandle.kind` — always `"file"` for this type.
  external String get kind;

  /// `FileSystemHandle.name` — the file's name (no path).
  external String get name;

  /// Resolves to the underlying `File` object.
  external JSPromise<WebFile> getFile();
}

// ---------------------------------------------------------------------------
// Web File & Blob
// ---------------------------------------------------------------------------

/// The browser's `File` object (extends `Blob`).
extension type WebFile._(JSObject _) implements JSObject {
  external String get name;
  external int get size;
  external String get type;

  /// Milliseconds since epoch.
  external double get lastModified;

  /// Returns a `ReadableStream<Uint8Array>` over the file's bytes.
  external JsReadableStream stream();
}

// ---------------------------------------------------------------------------
// Streams API
// ---------------------------------------------------------------------------

/// `ReadableStream<Uint8Array>` as returned by `File.stream()`.
extension type JsReadableStream._(JSObject _) implements JSObject {
  /// Acquires the default reader. May only be called once per stream.
  external ReadableStreamDefaultReader getReader();
}

/// `ReadableStreamDefaultReader<Uint8Array>`.
extension type ReadableStreamDefaultReader._(JSObject _) implements JSObject {
  /// Returns a Promise resolving to `{ value: Uint8Array | undefined, done: boolean }`.
  external JSPromise<ReadableStreamReadResult> read();

  /// Releases the reader's lock on the stream without cancelling it.
  external void releaseLock();

  /// Cancels the stream. Returns a Promise that resolves when done.
  external JSPromise<JSAny?> cancel([JSAny? reason]);
}

/// The plain object `{ value: Uint8Array | undefined, done: boolean }`
/// resolved by [ReadableStreamDefaultReader.read].
extension type ReadableStreamReadResult._(JSObject _) implements JSObject {
  external JSUint8Array? get value;
  external bool get done;
}

// ---------------------------------------------------------------------------
// window — typed access to the two globals we need
// ---------------------------------------------------------------------------

/// Minimal typed view of `window`, scoped to only what this package needs.
/// Using `@JS('window')` on a getter is the correct dart:js_interop pattern
/// for accessing a named global object.
@JS('window')
external _JsWindow get _jsWindow;

extension type _JsWindow._(JSObject _) implements JSObject {
  /// Reads an arbitrary property by name — used for feature detection.
  external JSAny? operator [](String key);

  external JSPromise<JSArray<FileSystemFileHandle>> showOpenFilePicker(
    JSObject options,
  );
}

// ---------------------------------------------------------------------------
// Feature detection
// ---------------------------------------------------------------------------

/// Returns `true` if `window.showOpenFilePicker` is a callable function.
///
/// Uses `dart:js_interop`'s `typeofEquals` / `instanceof` helpers rather than
/// an inline JS body (which is a `package:js`-only pattern and does not
/// compile under dart2wasm).
bool get isFileSystemAccessSupported {
  final prop = _jsWindow['showOpenFilePicker'];
  if (prop == null) return false;
  // `typeofEquals` is the Wasm-safe way to call JS `typeof`.
  return prop.typeofEquals('function');
}

// ---------------------------------------------------------------------------
// showOpenFilePicker helper
// ---------------------------------------------------------------------------

/// Calls `window.showOpenFilePicker(options)` and returns the JS Promise.
///
/// [options] is built with [buildPickerOptions] below.
JSPromise<JSArray<FileSystemFileHandle>> showOpenFilePicker(
  JSObject options,
) =>
    _jsWindow.showOpenFilePicker(options);

// ---------------------------------------------------------------------------
// Options object builders
//
// dart:js_interop extension types do NOT support named-parameter external
// factories (that is a package:js @anonymous pattern). Instead we build plain
// JSObject instances and set properties explicitly via setProperty.
// ---------------------------------------------------------------------------

/// Builds the `options` object for `window.showOpenFilePicker`.
///
/// Equivalent JS:
/// ```js
/// { multiple: false, types: [...], excludeAcceptAllOption: true }
/// ```
JSObject buildPickerOptions({
  required bool multiple,
  required JSArray<JSObject> types,
  required bool excludeAcceptAllOption,
}) {
  final obj = JSObject();
  obj.setProperty('multiple'.toJS, multiple.toJS);
  obj.setProperty('types'.toJS, types);
  obj.setProperty('excludeAcceptAllOption'.toJS, excludeAcceptAllOption.toJS);
  return obj;
}

/// Builds one entry in the `types` array.
///
/// Equivalent JS:
/// ```js
/// { description: "Images", accept: { "image/png": [".png"] } }
/// ```
JSObject buildAcceptType({
  required String description,
  required JSObject accept,
}) {
  final obj = JSObject();
  obj.setProperty('description'.toJS, description.toJS);
  obj.setProperty('accept'.toJS, accept);
  return obj;
}

/// Builds the nested `accept` record from a Dart map.
///
/// [mimeToExtensions] maps a MIME type to a list of dot-prefixed extensions,
/// e.g. `{ "image/png": [".png", ".PNG"] }`.
JSObject buildAcceptRecord(Map<String, List<String>> mimeToExtensions) {
  final obj = JSObject();
  for (final entry in mimeToExtensions.entries) {
    final exts = entry.value.map((e) => e.toJS).toList().toJS;
    obj.setProperty(entry.key.toJS, exts);
  }
  return obj;
}
