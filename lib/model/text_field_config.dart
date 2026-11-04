import 'package:flutter/material.dart';

import 'color_ref.dart';
import 'shadow_token.dart';

/// Text field states, in reverse precedence order
/// (disabled > error > focus > hover > normal).
enum FieldStateKey {
  normal('Normal'),
  hovered('Hover'),
  focused('Focus'),
  disabled('Disabled'),
  error('Error');

  const FieldStateKey(this.label);

  final String label;
}

/// Field appearance in a state. `null` = inherit.
class FieldStateStyle {
  ColorRef? fill;
  ColorRef? border;
  double? borderWidth;
  ColorRef? placeholder;
  ColorRef? icon;

  /// Field hard shadow (neobrutalism) and its color.
  ShadowToken? shadow;
  ColorRef? shadowColor;

  bool get isEmpty =>
      shadow == null &&
      shadowColor == null &&
      fill == null &&
      border == null &&
      borderWidth == null &&
      placeholder == null &&
      icon == null;

  void reset() {
    fill = null;
    border = null;
    borderWidth = null;
    placeholder = null;
    icon = null;
    shadow = null;
    shadowColor = null;
  }
}

/// Overrides for `TextField` / `TextFormField` (InputDecorationTheme and text).
class TextFieldConfig {
  final Map<FieldStateKey, FieldStateStyle> states = {
    for (final s in FieldStateKey.values) s: FieldStateStyle(),
  };

  StateStyleView get view => StateStyleView(this);

  // Contenitore
  double? radius;
  bool? dense;

  /// Bottom border only (UnderlineInputBorder), like Sera's fields.
  bool? underline;

  /// Distance between the left border and the start of the text.
  double? textInset;
  double? paddingEnd;
  double? paddingV;

  /// Side of the box that holds prefixIcon / suffixIcon.
  double? iconBox;

  // Typed text (textTheme.bodyLarge)
  double? inputFontSize;
  FontWeight? inputWeight;
  double? inputLineHeight;
  double? inputLetterSpacing;
  ColorRef? inputColor;
  ColorRef? cursor;

  // Helper / error text below the field
  double? helperFontSize;
  FontWeight? helperWeight;
  double? helperLetterSpacing;
  ColorRef? helperColor;
  ColorRef? errorColor;

  // Material 3 default (outlined field, not dense).
  static const double m3Radius = 4;
  static const double m3TextInset = 16; // contentPadding 12 + gapPadding 4
  static const double m3PaddingEnd = 12;
  static const double m3PaddingV = 16;
  static const double m3IconBox = 48;
  static const double m3InputFontSize = 16;
  static const double m3InputLineHeight = 24;
  static const double m3InputLetterSpacing = 0.5;
  static const double m3HelperFontSize = 12;
  static const double m3HelperLetterSpacing = 0.4;

  /// True if the border must be generated (outline per state) instead of the M3
  /// default.
  bool get customBorder =>
      underline == true ||
      radius != null ||
      states.values.any(
        (s) =>
            s.fill != null ||
            s.border != null ||
            s.borderWidth != null ||
            s.shadow != null,
      );

  bool get hasPadding =>
      textInset != null || paddingEnd != null || paddingV != null;

  bool get hasInputStyle =>
      inputFontSize != null ||
      inputWeight != null ||
      inputLineHeight != null ||
      inputLetterSpacing != null ||
      inputColor != null;

  bool get hasHelperStyle =>
      helperFontSize != null ||
      helperWeight != null ||
      helperLetterSpacing != null ||
      helperColor != null;

  bool get hasErrorStyle =>
      helperFontSize != null ||
      helperWeight != null ||
      helperLetterSpacing != null ||
      errorColor != null;

  bool get hasPlaceholder => states.values.any((s) => s.placeholder != null);
  bool get hasIconColor => states.values.any((s) => s.icon != null);

  bool get isEmpty =>
      states.values.every((s) => s.isEmpty) &&
      radius == null &&
      dense == null &&
      underline == null &&
      !hasPadding &&
      iconBox == null &&
      !hasInputStyle &&
      cursor == null &&
      !hasHelperStyle &&
      errorColor == null;

  void reset() {
    for (final s in states.values) {
      s.reset();
    }
    radius = null;
    dense = null;
    underline = null;
    textInset = null;
    paddingEnd = null;
    paddingV = null;
    iconBox = null;
    inputFontSize = null;
    inputWeight = null;
    inputLineHeight = null;
    inputLetterSpacing = null;
    inputColor = null;
    cursor = null;
    helperFontSize = null;
    helperWeight = null;
    helperLetterSpacing = null;
    helperColor = null;
    errorColor = null;
  }
}

/// Effective values per state, with inheritance and Material 3 defaults.
///
/// - Fill, placeholder and icons: states inherit from normal.
/// - Border: each state has its own M3 default (outline / onSurface /
///   primary 2px / onSurface 12% / error).
class StateStyleView {
  StateStyleView(this.c);

  final TextFieldConfig c;

  FieldStateStyle _s(FieldStateKey k) => c.states[k]!;
  FieldStateStyle get _n => _s(FieldStateKey.normal);

  ColorRef? fill(FieldStateKey k) => _s(k).fill ?? _n.fill;

  ColorRef? placeholder(FieldStateKey k) => _s(k).placeholder ?? _n.placeholder;

  ColorRef? icon(FieldStateKey k) => _s(k).icon ?? _n.icon;

  ShadowToken? shadow(FieldStateKey k) => _s(k).shadow ?? _n.shadow;

  ColorRef? shadowColor(FieldStateKey k) => _s(k).shadowColor ?? _n.shadowColor;

  ColorRef border(FieldStateKey k) =>
      _s(k).border ??
      switch (k) {
        FieldStateKey.normal => const RoleColor(SchemeRole.outline),
        FieldStateKey.hovered =>
          _n.border ?? const RoleColor(SchemeRole.onSurface),
        FieldStateKey.focused => const RoleColor(SchemeRole.primary),
        FieldStateKey.disabled => const RoleColor(
          SchemeRole.onSurface,
          alpha: 0.12,
        ),
        FieldStateKey.error => const RoleColor(SchemeRole.error),
      };

  double borderWidth(FieldStateKey k) =>
      _s(k).borderWidth ??
      switch (k) {
        FieldStateKey.focused => 2,
        _ => _n.borderWidth ?? 1,
      };
}
