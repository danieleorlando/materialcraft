import 'share_link.dart';
import 'theme_json.dart';
import 'theme_layers.dart';

/// Community gallery: themes in the repo's `gallery/` folder, one project
/// file per theme (`<slug>.materialcraft.json`), bundled with the app.
///
/// Each file is a normal project file plus a `gallery` block:
/// `{"author": "<GitHub login>", "description": "...", "added": "YYYY-MM-DD"}`.
const galleryFolder = 'gallery/';
const galleryFileSuffix = '.materialcraft.json';

/// URL parameter of a gallery link: `?g=<slug>`.
const galleryParam = 'g';

const maxGalleryNameLength = 40;
const maxGalleryDescriptionLength = 120;

final _slugPattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');
// GitHub logins: letters, digits and single hyphens, up to 39 characters.
final _loginPattern = RegExp(
  r'^[A-Za-z0-9](?:[A-Za-z0-9]|-(?=[A-Za-z0-9])){0,38}$',
);

class GalleryEntry {
  GalleryEntry({
    required this.slug,
    required this.name,
    required this.description,
    required this.author,
    required this.added,
    required this.theme,
  });

  final String slug;
  final String name;
  final String description;

  /// GitHub login of who made it.
  final String author;
  final DateTime added;
  final LayeredTheme theme;

  String get authorUrl => 'https://github.com/$author';
}

/// The slug of a gallery asset path, or null if it isn't a gallery theme.
String? gallerySlugOf(String assetPath) {
  if (!assetPath.startsWith(galleryFolder) ||
      !assetPath.endsWith(galleryFileSuffix)) {
    return null;
  }
  final slug = assetPath.substring(
    galleryFolder.length,
    assetPath.length - galleryFileSuffix.length,
  );
  return _slugPattern.hasMatch(slug) ? slug : null;
}

/// Reads one gallery file. Throws [FormatException] saying what's wrong, so
/// the same check serves the app, the tests and the submission workflow.
GalleryEntry galleryEntryFromJson(String slug, Object? json) {
  if (!_slugPattern.hasMatch(slug)) {
    throw FormatException(
      '"$slug": the file name must be lowercase-with-dashes.',
    );
  }
  if (json is! Map) throw FormatException('$slug: not a JSON object.');
  final loaded = layeredThemeFromJson(json);
  final meta = json['gallery'];
  if (meta is! Map) {
    throw FormatException('$slug: missing the "gallery" block.');
  }

  final name = loaded.name?.trim() ?? '';
  if (name.isEmpty || name.length > maxGalleryNameLength) {
    throw FormatException(
      '$slug: the name must be 1-$maxGalleryNameLength characters.',
    );
  }
  final description = meta['description'];
  if (description is! String ||
      description.trim().isEmpty ||
      description.length > maxGalleryDescriptionLength) {
    throw FormatException(
      '$slug: the description must be 1-$maxGalleryDescriptionLength '
      'characters.',
    );
  }
  final author = meta['author'];
  if (author is! String || !_loginPattern.hasMatch(author)) {
    throw FormatException('$slug: "author" must be a GitHub login.');
  }
  final added = meta['added'] is String
      ? DateTime.tryParse(meta['added'] as String)
      : null;
  if (added == null) {
    throw FormatException('$slug: "added" must be a date (YYYY-MM-DD).');
  }
  return GalleryEntry(
    slug: slug,
    name: name,
    description: description.trim(),
    author: author,
    added: added,
    theme: loaded.theme,
  );
}

/// Newest first, then by name.
int compareGalleryEntries(GalleryEntry a, GalleryEntry b) {
  final byDate = b.added.compareTo(a.added);
  return byDate != 0 ? byDate : a.name.compareTo(b.name);
}

/// GitHub repository that hosts the gallery.
const galleryRepoUrl = 'https://github.com/danieleorlando/materialcraft';

/// New issue on GitHub with the gallery form filled in for [theme]: the
/// submission workflow turns it into a pull request.
String gallerySubmissionUrl(LayeredTheme theme, String name) {
  var title = name.trim();
  if (title.length > maxGalleryNameLength) {
    title = title.substring(0, maxGalleryNameLength).trim();
  }
  return Uri.parse('$galleryRepoUrl/issues/new')
      .replace(
        queryParameters: {
          'template': 'gallery.yml',
          'title': '[Gallery] $title',
          'labels': 'gallery',
          'link': shareUrl(theme, name: title),
          'name': title,
        },
      )
      .toString();
}
