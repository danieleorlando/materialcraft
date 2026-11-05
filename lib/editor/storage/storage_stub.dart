// Outside the browser (tests, desktop): no saving.

String? readAutosave() => null;

void writeAutosave(String json) {}

void downloadText(
  String filename,
  String text, {
  String mimeType = 'application/json',
}) {}

Future<String?> pickTextFile() async => null;

void openUrl(String url) {}

/// A parameter of the address the page was opened with (e.g. `?t=`).
String? readUrlParam(String name) => null;

/// Removes [names] from the address bar, so a reload doesn't reopen them.
void clearUrlParams(Set<String> names) {}

/// Address of the running editor, used to build shared links.
String? editorBaseUrl() => null;
