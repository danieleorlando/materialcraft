/// Project saving: in the browser (download, file opening,
/// autosave in localStorage); elsewhere (tests) it does nothing.
library;

export 'storage_stub.dart' if (dart.library.js_interop) 'storage_web.dart';
