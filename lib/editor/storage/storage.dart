/// Browser helpers: project saving (download, file opening,
/// autosave in localStorage) and links; elsewhere (tests) they do nothing.
library;

export 'storage_stub.dart' if (dart.library.js_interop) 'storage_web.dart';
