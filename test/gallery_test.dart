// Checks every theme in gallery/: the submission workflow runs this file
// before opening a pull request, and CI runs it on every change.
import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:materialcraft_app/export/dart_exporter.dart';
import 'package:materialcraft_app/export/export_format.dart';
import 'package:materialcraft_app/model/gallery.dart';
import 'package:materialcraft_app/model/theme_builder.dart';

void main() {
  setUpAll(loadExportFormatter);

  final files = Directory('gallery').listSync().whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('the gallery folder holds only theme files', () {
    expect(files, isNotEmpty);
    for (final f in files) {
      final path = 'gallery/${f.uri.pathSegments.last}';
      expect(gallerySlugOf(path), isNotNull, reason: path);
    }
  });

  final names = <String, String>{};
  for (final f in files) {
    final path = 'gallery/${f.uri.pathSegments.last}';
    final slug = gallerySlugOf(path);
    if (slug == null) continue;
    test(path, () {
      final entry = galleryEntryFromJson(
        slug,
        jsonDecode(f.readAsStringSync()),
      );
      final other = names[entry.name.toLowerCase()];
      expect(other, isNull, reason: 'same name as $other');
      names[entry.name.toLowerCase()] = slug;

      final c = entry.theme.resolved;
      for (final font in [c.fontFamily, c.headFontFamily]) {
        if (font == null) continue;
        expect(
          GoogleFonts.asMap().containsKey(font),
          isTrue,
          reason: '"$font" is not a Google Font',
        );
      }
      expect(exportDart(c), contains('class AppTheme'));
      // Tests can't download fonts: the rest of the theme is built without.
      c
        ..fontFamily = null
        ..headFontFamily = null;
      for (final b in Brightness.values) {
        expect(buildTheme(c, b).brightness, b);
      }
    });
  }
}
