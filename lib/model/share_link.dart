import 'dart:convert';

import 'theme_json.dart';
import 'theme_layers.dart';

/// Shareable links: the whole theme travels in the URL,
/// `https://materialcraft.danieleorlando.me/?t=<payload>`, so no server is
/// needed.
///
/// The payload is `<link version>.<base64url of the project JSON>`. The link
/// version only describes the encoding (a later one could compress the JSON);
/// the JSON keeps its own `version`, like a `.materialcraft.json` file.
const shareParam = 't';

/// Link encoding written by this version of MaterialCraft.
const shareLinkVersion = 1;

/// Public address of the editor, used outside the browser (tests).
const publicEditorUrl = 'https://materialcraft.danieleorlando.me/';

const _brokenLink = 'This link is broken or incomplete.';
const _newerLink =
    'This link was made with a newer version of MaterialCraft. Reload the page '
    'and try again.';

/// The `?t=` value for [theme].
String encodeSharePayload(LayeredTheme theme, {String? name}) {
  final json = jsonEncode(layeredThemeToJson(theme, name: name));
  final data = base64Url.encode(utf8.encode(json)).replaceAll('=', '');
  return '$shareLinkVersion.$data';
}

/// Full link to open [theme] in the editor at [baseUrl].
String shareUrl(LayeredTheme theme, {String? name, String? baseUrl}) {
  final base = Uri.parse(baseUrl ?? publicEditorUrl);
  return base
      .replace(
        queryParameters: {shareParam: encodeSharePayload(theme, name: name)},
        fragment: '',
      )
      .toString()
      .replaceAll(RegExp(r'#$'), '');
}

/// Reads a `?t=` value. Throws [FormatException] with a message for the user
/// if the link is damaged or comes from a newer MaterialCraft.
({LayeredTheme theme, String? name}) decodeSharePayload(String payload) {
  final dot = payload.indexOf('.');
  final version = dot <= 0 ? null : int.tryParse(payload.substring(0, dot));
  if (version == null) throw const FormatException(_brokenLink);
  if (version > shareLinkVersion) throw const FormatException(_newerLink);

  final Object? json;
  try {
    final data = base64Url.normalize(payload.substring(dot + 1));
    json = jsonDecode(utf8.decode(base64Url.decode(data)));
  } on FormatException {
    throw const FormatException(_brokenLink);
  }
  if (json is! Map || json['format'] != themeFileFormat) {
    throw const FormatException(_brokenLink);
  }
  final fileVersion = json['version'];
  if (fileVersion is int && fileVersion > themeFileVersion) {
    throw const FormatException(_newerLink);
  }
  try {
    return layeredThemeFromJson(json);
  } on FormatException {
    throw const FormatException(_brokenLink);
  }
}

/// True if [a] and [b] give the same theme (the name doesn't count).
bool sameTheme(LayeredTheme a, LayeredTheme b) =>
    jsonEncode(layeredThemeToJson(a)) == jsonEncode(layeredThemeToJson(b));
