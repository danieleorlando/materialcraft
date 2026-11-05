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

/// The `?t=` value of a shared link the page was opened with.
String? readShareParam() => null;

/// Removes `?t=` from the address bar, so a reload doesn't reopen it.
void clearShareParam() {}

/// Address of the running editor, used to build shared links.
String? editorBaseUrl() => null;
