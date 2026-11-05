import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../../model/share_link.dart';

const _autosaveKey = 'materialcraft.autosave.v1';

/// Last autosaved theme (null if there's none or the browser
/// blocks storage, e.g. a private window).
String? readAutosave() {
  try {
    return web.window.localStorage.getItem(_autosaveKey);
  } catch (_) {
    return null;
  }
}

void writeAutosave(String json) {
  try {
    web.window.localStorage.setItem(_autosaveKey, json);
  } catch (_) {
    // Storage full or blocked: saving to a file is still available.
  }
}

/// Downloads [text] as the file [filename].
void downloadText(
  String filename,
  String text, {
  String mimeType = 'application/json',
}) {
  final blob = web.Blob([text.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  web.document.body!.append(a);
  a.click();
  a.remove();
  web.URL.revokeObjectURL(url);
}

/// Asks the user for a file and returns its text (null if cancelled).
Future<String?> pickTextFile() {
  final done = Completer<String?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.json,application/json';
  Future<void> read() async {
    final file = input.files?.item(0);
    final text = file == null ? null : (await file.text().toDart).toDart;
    if (!done.isCompleted) done.complete(text);
  }

  input.addEventListener(
    'change',
    ((web.Event _) {
      unawaited(read());
    }).toJS,
  );
  input.addEventListener(
    'cancel',
    ((web.Event _) {
      if (!done.isCompleted) done.complete(null);
    }).toJS,
  );
  input.click();
  return done.future;
}

/// Opens [url] in a new tab.
void openUrl(String url) {
  web.window.open(url, '_blank', 'noopener');
}

/// The `?t=` value of a shared link the page was opened with.
String? readShareParam() {
  final value = Uri.base.queryParameters[shareParam];
  return value == null || value.isEmpty ? null : value;
}

/// Removes `?t=` from the address bar, so a reload doesn't reopen it.
void clearShareParam() {
  final uri = Uri.base;
  if (!uri.queryParameters.containsKey(shareParam)) return;
  final rest = Map.of(uri.queryParameters)..remove(shareParam);
  final query = rest.isEmpty ? '' : '?${Uri(queryParameters: rest).query}';
  final fragment = uri.hasFragment ? '#${uri.fragment}' : '';
  try {
    // Keeps Flutter's own history state, only the address changes.
    web.window.history.replaceState(
      web.window.history.state,
      '',
      '${uri.path}$query$fragment',
    );
  } catch (_) {
    // Not critical: a reload just reopens the shared theme.
  }
}

/// Address of the running editor, used to build shared links.
String? editorBaseUrl() => '${Uri.base.origin}${Uri.base.path}';
