import 'dart:ui' show Color;

/// Colors chosen in the "Colors" step: `null` = the style's official colors.
///
/// The primary generates the whole palette with the style's rules; the other
/// colors are optional (and only make sense for some styles).
class ColorChoice {
  /// Main color (seed for Material, accent for BoardUI, primary
  /// for Neobrutalism).
  Color? primary;

  /// Name of the Material color chosen from the grid (label only).
  String? primaryName;

  // Material: the other key colors (null = generated from the primary).
  Color? secondary;
  Color? tertiary;
  Color? neutral;
  Color? neutralVariant;
  Color? error;

  // BoardUI: Tailwind neutral family, or a custom gray.
  String? neutralFamily;
  Color? neutralCustom;

  bool get hasMaterialKeys =>
      secondary != null ||
      tertiary != null ||
      neutral != null ||
      neutralVariant != null ||
      error != null;

  bool get isEmpty =>
      primary == null &&
      !hasMaterialKeys &&
      neutralFamily == null &&
      neutralCustom == null;

  void reset() {
    primary = null;
    primaryName = null;
    secondary = null;
    tertiary = null;
    neutral = null;
    neutralVariant = null;
    error = null;
    neutralFamily = null;
    neutralCustom = null;
  }
}
