import 'package:flutter/material.dart';

/// The 15 Material 3 TextTheme styles, with their default values.
enum TextRole {
  displayLarge('Display L', 57, 64, FontWeight.w400, -0.25),
  displayMedium('Display M', 45, 52, FontWeight.w400, 0),
  displaySmall('Display S', 36, 44, FontWeight.w400, 0),
  headlineLarge('Headline L', 32, 40, FontWeight.w400, 0),
  headlineMedium('Headline M', 28, 36, FontWeight.w400, 0),
  headlineSmall('Headline S', 24, 32, FontWeight.w400, 0),
  titleLarge('Title L', 22, 28, FontWeight.w400, 0),
  titleMedium('Title M', 16, 24, FontWeight.w500, 0.15),
  titleSmall('Title S', 14, 20, FontWeight.w500, 0.1),
  bodyLarge('Body L', 16, 24, FontWeight.w400, 0.5),
  bodyMedium('Body M', 14, 20, FontWeight.w400, 0.25),
  bodySmall('Body S', 12, 16, FontWeight.w400, 0.4),
  labelLarge('Label L', 14, 20, FontWeight.w500, 0.1),
  labelMedium('Label M', 12, 16, FontWeight.w500, 0.5),
  labelSmall('Label S', 11, 16, FontWeight.w500, 0.5);

  const TextRole(
    this.label,
    this.m3Size,
    this.m3LineHeight,
    this.m3Weight,
    this.m3LetterSpacing,
  );

  final String label;
  final double m3Size;
  final double m3LineHeight;
  final FontWeight m3Weight;
  final double m3LetterSpacing;

  /// Where Material uses it by default (helps pick values).
  String get usedBy => switch (this) {
    displayLarge || displayMedium || displaySmall => 'Hero numbers and titles',
    headlineLarge || headlineMedium => 'Large page titles',
    headlineSmall => 'Dialog titles',
    titleLarge => 'AppBar title',
    titleMedium => 'Card and section titles',
    titleSmall => 'Subtitles',
    bodyLarge => 'ListTile titles, TextField text',
    bodyMedium => 'Body text, dialog content',
    bodySmall => 'ListTile subtitles, secondary text',
    labelLarge => 'Button labels',
    labelMedium => 'NavigationBar labels, chips',
    labelSmall => 'Badges, small captions',
  };

  /// [t] with this style replaced by [s].
  TextTheme replaceIn(TextTheme t, TextStyle? s) => switch (this) {
    displayLarge => t.copyWith(displayLarge: s),
    displayMedium => t.copyWith(displayMedium: s),
    displaySmall => t.copyWith(displaySmall: s),
    headlineLarge => t.copyWith(headlineLarge: s),
    headlineMedium => t.copyWith(headlineMedium: s),
    headlineSmall => t.copyWith(headlineSmall: s),
    titleLarge => t.copyWith(titleLarge: s),
    titleMedium => t.copyWith(titleMedium: s),
    titleSmall => t.copyWith(titleSmall: s),
    bodyLarge => t.copyWith(bodyLarge: s),
    bodyMedium => t.copyWith(bodyMedium: s),
    bodySmall => t.copyWith(bodySmall: s),
    labelLarge => t.copyWith(labelLarge: s),
    labelMedium => t.copyWith(labelMedium: s),
    labelSmall => t.copyWith(labelSmall: s),
  };

  TextStyle? of(TextTheme t) => switch (this) {
    displayLarge => t.displayLarge,
    displayMedium => t.displayMedium,
    displaySmall => t.displaySmall,
    headlineLarge => t.headlineLarge,
    headlineMedium => t.headlineMedium,
    headlineSmall => t.headlineSmall,
    titleLarge => t.titleLarge,
    titleMedium => t.titleMedium,
    titleSmall => t.titleSmall,
    bodyLarge => t.bodyLarge,
    bodyMedium => t.bodyMedium,
    bodySmall => t.bodySmall,
    labelLarge => t.labelLarge,
    labelMedium => t.labelMedium,
    labelSmall => t.labelSmall,
  };
}

/// Style override. `null` = Material 3 value.
class TypeSpec {
  TypeSpec({
    this.size,
    this.lineHeight,
    this.weight,
    this.letterSpacing,
    this.source,
    this.headFont,
  });

  double? size;

  /// Interlinea in pixel (in Flutter diventa `height = lineHeight / size`).
  double? lineHeight;
  FontWeight? weight;
  double? letterSpacing;

  /// Name of the source style (e.g. BoardUI's "title-2-medium"), only for
  /// labels and comments in the exported code.
  String? source;

  /// Uses the heading font (ThemeConfig.headFontFamily) instead of the
  /// main one.
  bool? headFont;

  bool get isEmpty =>
      size == null &&
      lineHeight == null &&
      weight == null &&
      letterSpacing == null &&
      headFont == null;

  double effectiveSize(TextRole r) => size ?? r.m3Size;

  /// TextStyle with only the set fields (inherit: true, like the TextTheme
  /// passed to ThemeData).
  TextStyle toStyle(TextRole r) => TextStyle(
    fontSize: size,
    height: lineHeight == null
        ? null
        : double.parse((lineHeight! / effectiveSize(r)).toStringAsFixed(3)),
    fontWeight: weight,
    letterSpacing: letterSpacing,
  );
}

class TypographyConfig {
  final Map<TextRole, TypeSpec> styles = {
    for (final r in TextRole.values) r: TypeSpec(),
  };

  bool get isEmpty => styles.values.every((s) => s.isEmpty);

  void reset() {
    for (final r in TextRole.values) {
      styles[r] = TypeSpec();
    }
  }

  /// TextTheme with only the overrides (null if there are none).
  TextTheme? toTextTheme() {
    if (isEmpty) return null;
    TextStyle? s(TextRole r) =>
        styles[r]!.isEmpty ? null : styles[r]!.toStyle(r);
    return TextTheme(
      displayLarge: s(TextRole.displayLarge),
      displayMedium: s(TextRole.displayMedium),
      displaySmall: s(TextRole.displaySmall),
      headlineLarge: s(TextRole.headlineLarge),
      headlineMedium: s(TextRole.headlineMedium),
      headlineSmall: s(TextRole.headlineSmall),
      titleLarge: s(TextRole.titleLarge),
      titleMedium: s(TextRole.titleMedium),
      titleSmall: s(TextRole.titleSmall),
      bodyLarge: s(TextRole.bodyLarge),
      bodyMedium: s(TextRole.bodyMedium),
      bodySmall: s(TextRole.bodySmall),
      labelLarge: s(TextRole.labelLarge),
      labelMedium: s(TextRole.labelMedium),
      labelSmall: s(TextRole.labelSmall),
    );
  }
}
