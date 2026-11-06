import 'package:material_ui/material_ui.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

import 'color_ref.dart';

/// The 19 Material Design palette colors, offered as seeds.
const materialSeeds = <String, Color>{
  'Red': Color(0xFFF44336),
  'Pink': Color(0xFFE91E63),
  'Purple': Color(0xFF9C27B0),
  'Deep purple': Color(0xFF673AB7),
  'Indigo': Color(0xFF3F51B5),
  'Blue': Color(0xFF2196F3),
  'Light blue': Color(0xFF03A9F4),
  'Cyan': Color(0xFF00BCD4),
  'Teal': Color(0xFF009688),
  'Green': Color(0xFF4CAF50),
  'Light green': Color(0xFF8BC34A),
  'Lime': Color(0xFFCDDC39),
  'Yellow': Color(0xFFFFEB3B),
  'Amber': Color(0xFFFFC107),
  'Orange': Color(0xFFFF9800),
  'Deep orange': Color(0xFFFF5722),
  'Brown': Color(0xFF795548),
  'Grey': Color(0xFF9E9E9E),
  'Blue grey': Color(0xFF607D8B),
};

DynamicScheme _baseScheme(Hct seed, DynamicSchemeVariant v, bool dark) =>
    switch (v) {
      DynamicSchemeVariant.tonalSpot => SchemeTonalSpot(
        sourceColorHct: seed,
        isDark: dark,
        contrastLevel: 0,
      ),
      DynamicSchemeVariant.fidelity => SchemeFidelity(
        sourceColorHct: seed,
        isDark: dark,
        contrastLevel: 0,
      ),
      DynamicSchemeVariant.content => SchemeContent(
        sourceColorHct: seed,
        isDark: dark,
        contrastLevel: 0,
      ),
      DynamicSchemeVariant.monochrome => SchemeMonochrome(
        sourceColorHct: seed,
        isDark: dark,
        contrastLevel: 0,
      ),
      DynamicSchemeVariant.neutral => SchemeNeutral(
        sourceColorHct: seed,
        isDark: dark,
        contrastLevel: 0,
      ),
      DynamicSchemeVariant.vibrant => SchemeVibrant(
        sourceColorHct: seed,
        isDark: dark,
        contrastLevel: 0,
      ),
      DynamicSchemeVariant.expressive => SchemeExpressive(
        sourceColorHct: seed,
        isDark: dark,
        contrastLevel: 0,
      ),
      DynamicSchemeVariant.rainbow => SchemeRainbow(
        sourceColorHct: seed,
        isDark: dark,
        contrastLevel: 0,
      ),
      DynamicSchemeVariant.fruitSalad => SchemeFruitSalad(
        sourceColorHct: seed,
        isDark: dark,
        contrastLevel: 0,
      ),
    };

TonalPalette _palette(Color c) =>
    TonalPalette.fromHct(Hct.fromInt(c.toARGB32()));

/// All scheme roles with the chosen key colors, like the Material
/// Theme Builder: each fixed color generates its own tonal scale (hue and
/// chroma of the color), the others come from the primary as in `fromSeed`.
Map<SchemeRole, ColorRef> materialKeyColorRoles({
  required Color primary,
  required DynamicSchemeVariant variant,
  Color? secondary,
  Color? tertiary,
  Color? neutral,
  Color? neutralVariant,
  Color? error,
}) {
  final seed = Hct.fromInt(primary.toARGB32());
  Map<SchemeRole, Color> roles(bool dark) {
    final base = _baseScheme(seed, variant, dark);
    DynamicScheme scheme(TonalPalette primaryPalette) => DynamicScheme(
      sourceColorHct: seed,
      variant: base.variant,
      isDark: dark,
      primaryPalette: primaryPalette,
      secondaryPalette: secondary == null
          ? base.secondaryPalette
          : _palette(secondary),
      tertiaryPalette: tertiary == null
          ? base.tertiaryPalette
          : _palette(tertiary),
      neutralPalette: neutral == null ? base.neutralPalette : _palette(neutral),
      neutralVariantPalette: neutralVariant == null
          ? base.neutralVariantPalette
          : _palette(neutralVariant),
    );
    final s = scheme(base.primaryPalette);
    // The error palette can't be changed in this version: the error
    // roles use the same tones as the primary, so I derive them from a
    // scheme with the error as the primary palette.
    final e = error == null ? null : scheme(_palette(error));
    Color c(DynamicColor d, [DynamicScheme? from]) =>
        Color(d.getArgb(from ?? s));
    return {
      SchemeRole.primary: c(MaterialDynamicColors.primary),
      SchemeRole.onPrimary: c(MaterialDynamicColors.onPrimary),
      SchemeRole.primaryContainer: c(MaterialDynamicColors.primaryContainer),
      SchemeRole.onPrimaryContainer: c(
        MaterialDynamicColors.onPrimaryContainer,
      ),
      SchemeRole.secondary: c(MaterialDynamicColors.secondary),
      SchemeRole.onSecondary: c(MaterialDynamicColors.onSecondary),
      SchemeRole.secondaryContainer: c(
        MaterialDynamicColors.secondaryContainer,
      ),
      SchemeRole.onSecondaryContainer: c(
        MaterialDynamicColors.onSecondaryContainer,
      ),
      SchemeRole.tertiary: c(MaterialDynamicColors.tertiary),
      SchemeRole.onTertiary: c(MaterialDynamicColors.onTertiary),
      SchemeRole.tertiaryContainer: c(MaterialDynamicColors.tertiaryContainer),
      SchemeRole.onTertiaryContainer: c(
        MaterialDynamicColors.onTertiaryContainer,
      ),
      SchemeRole.error: e == null
          ? c(MaterialDynamicColors.error)
          : c(MaterialDynamicColors.primary, e),
      SchemeRole.onError: e == null
          ? c(MaterialDynamicColors.onError)
          : c(MaterialDynamicColors.onPrimary, e),
      SchemeRole.errorContainer: e == null
          ? c(MaterialDynamicColors.errorContainer)
          : c(MaterialDynamicColors.primaryContainer, e),
      SchemeRole.onErrorContainer: e == null
          ? c(MaterialDynamicColors.onErrorContainer)
          : c(MaterialDynamicColors.onPrimaryContainer, e),
      SchemeRole.surface: c(MaterialDynamicColors.surface),
      SchemeRole.onSurface: c(MaterialDynamicColors.onSurface),
      SchemeRole.onSurfaceVariant: c(MaterialDynamicColors.onSurfaceVariant),
      SchemeRole.surfaceContainerLowest: c(
        MaterialDynamicColors.surfaceContainerLowest,
      ),
      SchemeRole.surfaceContainerLow: c(
        MaterialDynamicColors.surfaceContainerLow,
      ),
      SchemeRole.surfaceContainer: c(MaterialDynamicColors.surfaceContainer),
      SchemeRole.surfaceContainerHigh: c(
        MaterialDynamicColors.surfaceContainerHigh,
      ),
      SchemeRole.surfaceContainerHighest: c(
        MaterialDynamicColors.surfaceContainerHighest,
      ),
      SchemeRole.outline: c(MaterialDynamicColors.outline),
      SchemeRole.outlineVariant: c(MaterialDynamicColors.outlineVariant),
      SchemeRole.inverseSurface: c(MaterialDynamicColors.inverseSurface),
      SchemeRole.onInverseSurface: c(MaterialDynamicColors.inverseOnSurface),
      SchemeRole.inversePrimary: c(MaterialDynamicColors.inversePrimary),
    };
  }

  final light = roles(false);
  final dark = roles(true);
  return {
    for (final r in SchemeRole.values)
      r: light[r] == dark[r]
          ? CustomColor(light[r]!)
          : AdaptiveColor(light[r]!, dark[r]!),
  };
}
