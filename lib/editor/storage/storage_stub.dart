// Outside the browser (tests, desktop): no saving.

String? readAutosave() => null;

void writeAutosave(String json) {}

void downloadText(String filename, String text) {}

Future<String?> pickTextFile() async => null;
