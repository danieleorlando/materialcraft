import 'dart_format.dart' deferred as impl;

bool _loaded = false;

/// Loads the formatter used by `exportDart` (a deferred library on the web,
/// so the editor starts without it). Call it once before exporting.
Future<void> loadExportFormatter() async {
  if (_loaded) return;
  await impl.loadLibrary();
  _loaded = true;
}

/// Whether [loadExportFormatter] has completed.
bool get exportFormatterLoaded => _loaded;

/// Cleans up and formats exported code (see `dart_format.dart`).
///
/// [languageVersion] is the Dart version the code is written for.
String formatExport(String code, {(int, int) languageVersion = (3, 13)}) {
  if (!_loaded) {
    throw StateError('Call loadExportFormatter() before exporting.');
  }
  return impl.formatDart(code, languageVersion: languageVersion);
}
