import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

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

/// A parameter of the address the page was opened with (e.g. `?t=`).
String? readUrlParam(String name) {
  final value = Uri.base.queryParameters[name];
  return value == null || value.isEmpty ? null : value;
}

/// Removes [names] from the address bar, so a reload doesn't reopen them.
void clearUrlParams(Set<String> names) {
  final uri = Uri.base;
  if (!uri.queryParameters.keys.any(names.contains)) return;
  final rest = Map.of(uri.queryParameters)
    ..removeWhere((k, _) => names.contains(k));
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
    // Not critical: a reload just reopens the same theme.
  }
}

/// Address of the running editor, used to build shared links. The app lives
/// at the site root, also when the gallery page (/gallery) is open.
String? editorBaseUrl() => '${Uri.base.origin}/';
