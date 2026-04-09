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
// HTML — minimal fallback support
// ---------------------------------------------------------------------------

@JS('document')
external _JsDocument get jsDocument;

extension type _JsDocument._(JSObject _) implements JSObject {
  @JS('createElement')
  external HTMLInputElement _createElement(String tagName);

  HTMLInputElement createInputElement() => _createElement('input');

  external HTMLBodyElement get body;

  @JS('querySelectorAll')
  external NodeList _querySelectorAll(String selector);

  NodeList querySelectorAll(String selector) => _querySelectorAll(selector);
}

extension type HTMLBodyElement._(JSObject _) implements JSObject {
  external void appendChild(JSObject child);
}

extension type NodeList._(JSObject _) implements JSObject {
  external int get length;

  @JS('item')
  external JSObject? item(int index);
}

extension type HTMLInputElement._(JSObject _) implements JSObject {
  external String get type;
  external set type(String value);

  external bool get multiple;
  external set multiple(bool value);

  external String get accept;
  external set accept(String value);

  external void click();
  external FileList? get files;
  external set files(FileList? value);

  external CSSStyleDeclaration get style;

  external void remove();
  external void addEventListener(String type, JSFunction listener);
  external void removeEventListener(String type, JSFunction listener);

  @JS('dispatchEvent')
  external bool _dispatchEvent(JSObject event);

  bool dispatchChangeEvent() {
    return _dispatchEvent(_createEvent('change'));
  }
}

extension type CSSStyleDeclaration._(JSObject _) implements JSObject {
  external String get display;
  external set display(String value);
}

@JS('Event')
extension type _JsEvent._(JSObject _) implements JSObject {
  external factory _JsEvent(String type);
}

_JsEvent _createEvent(String type) => _JsEvent(type);

extension type FileList._(JSObject _) implements JSObject {
  external int get length;
  @JS('item')
  external WebFile? item(int index);

  /// Helper to cast a JSArray to FileList for testing.
  /// In JS, FileList is an array-like object.
  static FileList fromArray(JSArray<WebFile> array) => array as FileList;
}

// ---------------------------------------------------------------------------
// window — typed access to the two globals we need
// ---------------------------------------------------------------------------

/// Minimal typed view of `window`, scoped to only what this package needs.
/// Using `@JS('window')` on a getter is the correct dart:js_interop pattern
/// for accessing a named global object.
@JS('window')
external _JsWindow get jsWindow;

extension type _JsWindow._(JSObject _) implements JSObject {
  /// Reads an arbitrary property by name — used for feature detection.
  external JSAny? operator [](String key);

  external JSPromise<JSArray<FileSystemFileHandle>> showOpenFilePicker(
    JSObject options,
  );
}

// Cache the result in a private variable
bool? _isFsaSupported;

// ---------------------------------------------------------------------------
// Feature detection
// ---------------------------------------------------------------------------

/// Returns `true` if `window.showOpenFilePicker` is a callable function.
///
/// Uses `dart:js_interop`'s `typeofEquals` / `instanceof` helpers rather than
/// an inline JS body (which is a `package:js`-only pattern and does not
/// compile under dart2wasm).
bool get isFileSystemAccessSupported {
  return _isFsaSupported ??= () {
    final picker = jsWindow['showOpenFilePicker'];
    // Check if the property exists and is a function
    if (picker == null || !picker.typeofEquals('function')) return false;

    final handleConstructor = jsWindow['FileSystemFileHandle'];

    // 1. Use .isA<JSObject> instead of 'is JSObject'
    if (handleConstructor != null && handleConstructor.isA<JSObject>()) {
      final prototype =
          (handleConstructor as JSObject).getProperty('prototype'.toJS);

      // 2. Again, use .isA<JSObject>()
      if (prototype != null && prototype.isA<JSObject>()) {
        // 3. Convert JSBoolean to Dart bool using .toDart
        return (prototype as JSObject).hasProperty('getFile'.toJS).toDart;
      }
    }

    return false;
  }();
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
    jsWindow.showOpenFilePicker(options);

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
