import 'package:flutter/material.dart';

import 'color_ref.dart';
import 'shadow_token.dart';
import 'surface_config.dart';
import 'text_field_config.dart';
import 'typography_config.dart';

/// The buttons supported by the editor.
///
/// The first five have a Material theme (`xxxButtonTheme`); the "extra" ones
/// (danger, icon secondary) don't exist in Material and are exported as
/// styles to apply with `style: context.buttonStyle(AppButtonKind.x)`.
enum ButtonKind {
  elevated(
    label: 'Elevated',
    widget: 'ElevatedButton',
    themeData: 'ElevatedButtonThemeData',
    themeField: 'elevatedButtonTheme',
    defaultBorderWidth: 0,
    defaultPaddingH: 24,
    defaultPaddingV: 0,
  ),
  filled(
    label: 'Filled',
    widget: 'FilledButton',
    themeData: 'FilledButtonThemeData',
    themeField: 'filledButtonTheme',
    defaultBorderWidth: 0,
    defaultPaddingH: 24,
    defaultPaddingV: 0,
  ),
  outlined(
    label: 'Outlined',
    widget: 'OutlinedButton',
    themeData: 'OutlinedButtonThemeData',
    themeField: 'outlinedButtonTheme',
    defaultBorderWidth: 1,
    defaultPaddingH: 24,
    defaultPaddingV: 0,
  ),
  text(
    label: 'Text',
    widget: 'TextButton',
    themeData: 'TextButtonThemeData',
    themeField: 'textButtonTheme',
    defaultBorderWidth: 0,
    defaultPaddingH: 12,
    defaultPaddingV: 8,
  ),
  icon(
    label: 'Icon button',
    widget: 'IconButton',
    themeData: 'IconButtonThemeData',
    themeField: 'iconButtonTheme',
    defaultBorderWidth: 0,
    defaultPaddingH: 8,
    defaultPaddingV: 8,
  ),
  danger(
    label: 'Danger',
    widget: 'FilledButton',
    themeData: null,
    themeField: null,
    defaultBorderWidth: 0,
    defaultPaddingH: 24,
    defaultPaddingV: 0,
  ),
  ghost(
    label: 'Ghost',
    widget: 'TextButton',
    themeData: null,
    themeField: null,
    defaultBorderWidth: 0,
    defaultPaddingH: 12,
    defaultPaddingV: 8,
  ),
  iconSecondary(
    label: 'Icon secondary',
    widget: 'IconButton',
    themeData: null,
    themeField: null,
    defaultBorderWidth: 0,
    defaultPaddingH: 8,
    defaultPaddingV: 8,
  );

  const ButtonKind({
    required this.label,
    required this.widget,
    required this.themeData,
    required this.themeField,
    required this.defaultBorderWidth,
    required this.defaultPaddingH,
    required this.defaultPaddingV,
  });

  final String label;
  final String widget;

  /// `null` for extra styles, which have no Material theme.
  final String? themeData;
  final String? themeField;
  final double defaultBorderWidth;
  final double defaultPaddingH;
  final double defaultPaddingV;

  bool get isExtra => themeField == null;

  /// Icon-only buttons: no text style, square.
  bool get isIconOnly => this == icon || this == iconSecondary;

  /// TextButton doesn't use ButtonSkin: Flutter uses it inside many widgets
  /// (menu items, SnackBar action, copy/paste toolbar) that
  /// would inherit background, shadows and focus ring. It gets per-state colors
  /// only.
  bool get allowsSkin => this != text;

  static const double defaultMinHeight = 40;
  static const double defaultRadius = 20; // M3: forma a pillola (stadium)
  static const double defaultFontSize = 14;
  static const double defaultLetterSpacing = 0.1;

  double get m3MinWidth => isIconOnly ? 40 : 64;
  double get m3IconSize => isIconOnly ? 24 : 18;

  // Material 3 defaults, used when the button switches to "skin" drawing and
  // Material no longer handles the colors by itself.

  ColorRef? get m3Fill => switch (this) {
    elevated => const RoleColor(SchemeRole.surfaceContainerLow),
    filled => const RoleColor(SchemeRole.primary),
    danger => const RoleColor(SchemeRole.error),
    outlined || text || ghost || icon || iconSecondary => null,
  };

  ColorRef get m3Foreground => switch (this) {
    filled => const RoleColor(SchemeRole.onPrimary),
    danger => const RoleColor(SchemeRole.onError),
    icon || iconSecondary => const RoleColor(SchemeRole.onSurfaceVariant),
    _ => const RoleColor(SchemeRole.primary),
  };

  ColorRef? get m3Border => switch (this) {
    outlined => const RoleColor(SchemeRole.outline),
    _ => null,
  };

  ShadowToken? get m3Shadow => this == elevated ? ShadowToken.sm : null;

  ColorRef? get m3DisabledFill => switch (this) {
    elevated ||
    filled ||
    danger => const RoleColor(SchemeRole.onSurface, alpha: 0.12),
    _ => null,
  };

  ColorRef get m3DisabledForeground =>
      const RoleColor(SchemeRole.onSurface, alpha: 0.38);

  ColorRef? get m3DisabledBorder => switch (this) {
    outlined => const RoleColor(SchemeRole.onSurface, alpha: 0.12),
    _ => null,
  };
}

/// Additional button sizes (the "medium" size is the theme's).
enum ButtonSizeKey {
  large('Large'),
  small('Small'),
  xs('Extra small');

  const ButtonSizeKey(this.label);

  final String label;
}

/// Geometry of a size: applies to all labelled buttons.
/// `null` = as the button's medium size.
class ButtonSizeSpec {
  double? radius;
  double? paddingH;
  double? paddingV;
  double? minHeight;
  double? iconSize;
  double? fontSize;
  FontWeight? fontWeight;
  double? letterSpacing;

  /// Text line height in px.
  double? lineHeight;

  bool get isEmpty =>
      lineHeight == null &&
      radius == null &&
      paddingH == null &&
      paddingV == null &&
      minHeight == null &&
      iconSize == null &&
      fontSize == null &&
      fontWeight == null &&
      letterSpacing == null;

  void reset() {
    radius = null;
    paddingH = null;
    paddingV = null;
    minHeight = null;
    iconSize = null;
    fontSize = null;
    fontWeight = null;
    letterSpacing = null;
    lineHeight = null;
  }
}

/// Interactive states of a button.
enum ButtonStateKey {
  normal('Normal'),
  hovered('Hover'),
  pressed('Pressed'),
  focused('Focus'),
  disabled('Disabled');

  const ButtonStateKey(this.label);

  final String label;
}

/// Appearance of a button in a state. `null` = inherit (from the normal state
/// or the Material 3 default).
class StateStyle {
  ColorRef? fill;

  /// If set, the background is a vertical gradient [fill] → [fillEnd].
  ColorRef? fillEnd;
  ColorRef? foreground;
  ColorRef? border;
  ShadowToken? shadow;

  /// Hard shadow color (default: the scheme's outline).
  ColorRef? shadowColor;

  /// Button offset in this state (e.g. neobrutalism: on hover the
  /// button "moves down" towards its shadow).
  double? offsetX;
  double? offsetY;

  bool get isEmpty =>
      fill == null &&
      fillEnd == null &&
      foreground == null &&
      border == null &&
      shadow == null &&
      shadowColor == null &&
      offsetX == null &&
      offsetY == null;

  void reset() {
    fill = null;
    fillEnd = null;
    foreground = null;
    border = null;
    shadow = null;
    shadowColor = null;
    offsetX = null;
    offsetY = null;
  }
}

/// Visual overrides for a button type. `null` = Material 3 default.
class ButtonConfig {
  final Map<ButtonStateKey, StateStyle> states = {
    for (final s in ButtonStateKey.values) s: StateStyle(),
  };

  StateStyle get normal => states[ButtonStateKey.normal]!;

  double? borderWidth;
  double? radius;
  double? paddingH;
  double? paddingV;
  double? minHeight;
  double? minWidth;
  double? iconSize;
  double? fontSize;
  FontWeight? fontWeight;
  double? letterSpacing;

  /// Text line height in px (null = labelLarge's).
  double? lineHeight;

  /// Underlines the label on hover (like a link).
  bool? hoverUnderline;

  /// Label in the heading font (ThemeConfig.headFontFamily).
  bool? headFont;

  // Effects (require "skin" drawing).
  double? pressScale;
  ColorRef? focusRing;
  double? focusRingWidth;
  double? focusRingOffset;
  ColorRef? focusRingOffsetColor;
  double? transitionMs;

  static const double defaultFocusRingWidth = 2;
  static const double defaultFocusRingOffset = 2;
  static const double defaultTransitionMs = 150;

  bool get isEmpty =>
      states.values.every((s) => s.isEmpty) &&
      borderWidth == null &&
      radius == null &&
      paddingH == null &&
      paddingV == null &&
      minHeight == null &&
      minWidth == null &&
      iconSize == null &&
      fontSize == null &&
      fontWeight == null &&
      letterSpacing == null &&
      lineHeight == null &&
      hoverUnderline == null &&
      headFont == null &&
      !hasEffects;

  bool get hasEffects =>
      pressScale != null ||
      focusRing != null ||
      focusRingWidth != null ||
      focusRingOffset != null ||
      focusRingOffsetColor != null ||
      transitionMs != null;

  /// True when features that `styleFrom` doesn't offer are needed (states,
  /// gradients, CSS shadows, effects): in that case `ButtonSkin` is used.
  bool get needsSkin =>
      hasEffects ||
      normal.fillEnd != null ||
      normal.shadow != null ||
      normal.offsetX != null ||
      normal.offsetY != null ||
      states.entries.any(
        (e) => e.key != ButtonStateKey.normal && !e.value.isEmpty,
      );

  /// Different colors per state without ButtonSkin (used by TextButton).
  bool get hasStateColors =>
      hoverUnderline == true ||
      states.entries.any(
        (e) => e.key != ButtonStateKey.normal && !e.value.isEmpty,
      );

  bool get hasTextStyle =>
      headFont == true ||
      hoverUnderline == true ||
      fontSize != null ||
      fontWeight != null ||
      letterSpacing != null ||
      lineHeight != null;

  /// TextStyle `height` for [lineHeight] (same precision as the export).
  double? textHeight(double baseFontSize) => lineHeight == null
      ? null
      : double.parse(
          (lineHeight! / (fontSize ?? baseFontSize)).toStringAsFixed(3),
        );
  bool get hasPadding => paddingH != null || paddingV != null;
  bool get hasMinSize => minHeight != null || minWidth != null;
  bool get hasSide => borderWidth != null || normal.border != null;

  /// Copy with the geometry of size [size] (colors, states and effects
  /// stay shared).
  ButtonConfig withSize(ButtonSizeSpec size) {
    final c = ButtonConfig();
    for (final e in states.entries) {
      c.states[e.key] = e.value;
    }
    c
      ..borderWidth = borderWidth
      ..radius = size.radius ?? radius
      ..paddingH = size.paddingH ?? paddingH
      ..paddingV = size.paddingV ?? paddingV
      ..minHeight = size.minHeight ?? minHeight
      ..minWidth = minWidth
      ..iconSize = size.iconSize ?? iconSize
      ..fontSize = size.fontSize ?? fontSize
      ..fontWeight = size.fontWeight ?? fontWeight
      ..letterSpacing = size.letterSpacing ?? letterSpacing
      ..lineHeight = size.lineHeight ?? lineHeight
      ..hoverUnderline = hoverUnderline
      ..headFont = headFont
      ..pressScale = pressScale
      ..focusRing = focusRing
      ..focusRingWidth = focusRingWidth
      ..focusRingOffset = focusRingOffset
      ..focusRingOffsetColor = focusRingOffsetColor
      ..transitionMs = transitionMs;
    return c;
  }

  void reset() {
    for (final s in states.values) {
      s.reset();
    }
    borderWidth = null;
    radius = null;
    paddingH = null;
    paddingV = null;
    minHeight = null;
    minWidth = null;
    iconSize = null;
    fontSize = null;
    fontWeight = null;
    letterSpacing = null;
    lineHeight = null;
    hoverUnderline = null;
    headFont = null;
    pressScale = null;
    focusRing = null;
    focusRingWidth = null;
    focusRingOffset = null;
    focusRingOffsetColor = null;
    transitionMs = null;
  }
}

enum DensityOption {
  standard('Standard', 'VisualDensity.standard', VisualDensity.standard),
  comfortable(
    'Comfortable',
    'VisualDensity.comfortable',
    VisualDensity.comfortable,
  ),
  compact('Compact', 'VisualDensity.compact', VisualDensity.compact);

  const DensityOption(this.label, this.dart, this.value);

  final String label;
  final String dart;
  final VisualDensity value;
}

/// Full configuration of the theme being edited.
class ThemeConfig {
  static const defaultSeed = Color(0xFF6750A4);

  /// Available fonts (Google Fonts names). `null` = Material default (Roboto).
  static const fontFamilies = [
    'Roboto',
    'Inter',
    'Geist',
    'Figtree',
    'Noto Sans',
    'JetBrains Mono',
    'DM Sans',
    'Manrope',
    'Plus Jakarta Sans',
    'Poppins',
    'Nunito',
    'Lato',
    'Open Sans',
    'Work Sans',
    'Space Grotesk',
    'Archivo Black',
    'Archivo',
    'Space Mono',
  ];

  /// `null` = not set (in an edits layer: inherit).
  Color? seed;
  DynamicSchemeVariant? schemeVariant;

  Color get seedColor => seed ?? defaultSeed;
  set seedColor(Color v) => seed = v;
  DynamicSchemeVariant get variant =>
      schemeVariant ?? DynamicSchemeVariant.tonalSpot;
  set variant(DynamicSchemeVariant v) => schemeVariant = v;
  String? fontFamily;

  /// Font for headings and, if required, buttons (e.g. Archivo Black).
  String? headFontFamily;

  /// ColorScheme roles replaced after `fromSeed`.
  final Map<SchemeRole, ColorRef> schemeOverrides = {};

  /// `null` = Flutter's adaptive density (compact on desktop and desktop web).
  DensityOption? density;

  /// If true, no 48px minimum tap target around buttons.
  bool? shrinkWrap;
  bool get shrinkWrapTapTargets => shrinkWrap ?? false;
  set shrinkWrapTapTargets(bool v) => shrinkWrap = v;

  final Map<ButtonKind, ButtonConfig> buttons = {
    for (final k in ButtonKind.values) k: ButtonConfig(),
  };

  final TextFieldConfig textField = TextFieldConfig();

  final Map<ButtonSizeKey, ButtonSizeSpec> buttonSizes = {
    for (final k in ButtonSizeKey.values) k: ButtonSizeSpec(),
  };

  final TypographyConfig typography = TypographyConfig();

  final Map<SurfaceKind, SurfaceConfig> surfaces = {
    for (final k in SurfaceKind.values) k: SurfaceConfig(),
  };

  bool get globalsModified =>
      seed != null ||
      schemeVariant != null ||
      fontFamily != null ||
      headFontFamily != null ||
      schemeOverrides.isNotEmpty ||
      density != null ||
      shrinkWrap != null;

  bool get isDefault =>
      !globalsModified &&
      buttons.values.every((b) => b.isEmpty) &&
      textField.isEmpty &&
      buttonSizes.values.every((s) => s.isEmpty) &&
      typography.isEmpty &&
      surfaces.values.every((s) => s.isEmpty);

  void reset() {
    seed = null;
    schemeVariant = null;
    fontFamily = null;
    headFontFamily = null;
    schemeOverrides.clear();
    density = null;
    shrinkWrap = null;
    for (final b in buttons.values) {
      b.reset();
    }
    textField.reset();
    for (final s in buttonSizes.values) {
      s.reset();
    }
    typography.reset();
    for (final s in surfaces.values) {
      s.reset();
    }
  }
}
