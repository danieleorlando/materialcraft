import 'package:material_ui/material_ui.dart';

import 'color_choice.dart';
import 'color_ref.dart';
import 'color_sets.dart';
import 'global_tokens.dart';
import 'presets.dart';
import 'shadow_token.dart';
import 'surface_config.dart';
import 'text_field_config.dart';
import 'theme_config.dart';
import 'theme_layers.dart';
import 'typography_config.dart';

/// MaterialCraft project file format (`.materialcraft.json`).
///
/// Saves the choices, not the result: style, colors, global properties and
/// only the edits made by hand. Reopening it regenerates everything.
const themeFileFormat = 'materialcraft-theme';
const themeFileVersion = 1;

Map<String, Object?> layeredThemeToJson(LayeredTheme t, {String? name}) => {
  'format': themeFileFormat,
  'version': themeFileVersion,
  'name': ?name,
  'style': t.base.id,
  'colors': _colorsToJson(t.colors),
  'globals': _globalsToJson(t.globals),
  'edits': _configToJson(t.edits),
};

/// Reads a project file. Throws [FormatException] if it isn't valid.
({LayeredTheme theme, String? name}) layeredThemeFromJson(Object? json) {
  if (json is! Map || json['format'] != themeFileFormat) {
    throw const FormatException('Not a MaterialCraft theme file.');
  }
  final version = json['version'];
  if (version is! int || version > themeFileVersion) {
    throw const FormatException(
      'File created with a newer version of MaterialCraft.',
    );
  }
  final preset = presetFromJson(json['style']);
  final t = LayeredTheme(base: preset);
  _colorsFromJson(t.colors, _map(json['colors']));
  _globalsFromJson(t.globals, _map(json['globals']));
  _configFromJson(t.edits, _map(json['edits']));
  t.invalidate();
  return (theme: t, name: json['name'] as String?);
}

/// The preset saved in a file, by [ThemePreset.id] (unknown = Material 3).
ThemePreset presetFromJson(Object? style) {
  for (final p in ThemePreset.all) {
    if (p.id == style) return p;
  }
  return ThemePreset.material3;
}

// --- Helper ---------------------------------------------------------------------

Map<String, Object?> _map(Object? v) =>
    v is Map ? v.cast<String, Object?>() : const {};

double? _d(Object? v) => v is num ? v.toDouble() : null;
bool? _b(Object? v) => v is bool ? v : null;
String? _s(Object? v) => v is String ? v : null;

T? _enum<T extends Enum>(List<T> values, Object? v) {
  for (final e in values) {
    if (e.name == v) return e;
  }
  return null;
}

String _hex(Color c) => hexArgb(c);
Color? _color(Object? v) {
  if (v is! String) return null;
  final n = int.tryParse(v, radix: 16);
  return n == null ? null : Color(n);
}

FontWeight? _weight(Object? v) {
  if (v is! int) return null;
  for (final w in FontWeight.values) {
    if (w.value == v) return w;
  }
  return null;
}

/// Writes only the set values into [m].
void _put(Map<String, Object?> m, String key, Object? value) {
  if (value == null) return;
  if (value is Map && value.isEmpty) return;
  m[key] = value;
}

// --- Colors -------------------------------------------------------------------------

Object? colorRefToJson(ColorRef? c) => switch (c) {
  null => null,
  RoleColor(:final role, :final alpha) => {
    'role': role.name,
    if (alpha != 1) 'alpha': alpha,
  },
  CustomColor(:final color) => {'hex': _hex(color)},
  AdaptiveColor(:final light, :final dark) => {
    'light': _hex(light),
    'dark': _hex(dark),
  },
  TokenColor(:final name, :final set) => {'token': name, 'set': ?set},
  PaletteColor(:final palette, :final name) => {
    'palette': palette,
    'name': name,
  },
  ShadcnColor(:final base, :final accent, :final name, :final alpha) => {
    'shadcn': name,
    'base': base,
    'accent': ?accent,
    if (alpha != 1) 'alpha': alpha,
  },
};

ColorRef? colorRefFromJson(Object? v) {
  if (v is! Map) return null;
  if (_enum(SchemeRole.values, v['role']) case final role?) {
    return RoleColor(role, alpha: _d(v['alpha']) ?? 1);
  }
  if (_color(v['hex']) case final c?) return CustomColor(c);
  if ((_color(v['light']), _color(v['dark'])) case (final l?, final d?)) {
    return AdaptiveColor(l, d);
  }
  if (_s(v['token']) case final name?) {
    final set = _s(v['set']);
    // Recolored sets are regenerated from the chosen colors; if one no longer
    // exists,
    // fall back to the official token.
    return TokenColor(name, boardTokensFor(set) == null ? null : set);
  }
  if ((_s(v['shadcn']), _s(v['base'])) case (final n?, final base?)) {
    final accent = _s(v['accent']);
    if (accent != null && accent.startsWith('custom-')) {
      final c = _color('FF${accent.substring(7)}');
      if (c != null) registerShadcnAccent(c);
    }
    return ShadcnColor(base, accent, n, alpha: _d(v['alpha']) ?? 1);
  }
  if ((_s(v['palette']), _s(v['name'])) case (final p?, final n?)) {
    if (p.startsWith('custom-')) {
      final c = _color('FF${p.substring(7)}');
      if (c != null) registerNeoPalette(c);
    }
    return PaletteColor(p, n);
  }
  return null;
}

Map<String, Object?> _colorsToJson(ColorChoice c) {
  final m = <String, Object?>{};
  String? h(Color? c) => c == null ? null : _hex(c);
  _put(m, 'primary', h(c.primary));
  _put(m, 'primaryName', c.primaryName);
  _put(m, 'secondary', h(c.secondary));
  _put(m, 'tertiary', h(c.tertiary));
  _put(m, 'neutral', h(c.neutral));
  _put(m, 'neutralVariant', h(c.neutralVariant));
  _put(m, 'error', h(c.error));
  _put(m, 'neutralFamily', c.neutralFamily);
  _put(m, 'neutralCustom', h(c.neutralCustom));
  return m;
}

void _colorsFromJson(ColorChoice c, Map<String, Object?> m) {
  c
    ..primary = _color(m['primary'])
    ..primaryName = _s(m['primaryName'])
    ..secondary = _color(m['secondary'])
    ..tertiary = _color(m['tertiary'])
    ..neutral = _color(m['neutral'])
    ..neutralVariant = _color(m['neutralVariant'])
    ..error = _color(m['error'])
    ..neutralFamily = _s(m['neutralFamily'])
    ..neutralCustom = _color(m['neutralCustom']);
}

// --- Global properties -------------------------------------------------------------

Map<String, Object?> _globalsToJson(GlobalTokens g) {
  final m = <String, Object?>{};
  _put(m, 'radius', g.radius);
  _put(m, 'pillButtons', g.pillButtons);
  _put(m, 'borderWidth', g.borderWidth);
  _put(m, 'shadowStyle', g.shadowStyle?.name);
  _put(m, 'shadowLevel', g.shadowLevel);
  _put(m, 'controlHeight', g.controlHeight);
  _put(m, 'press', g.press?.name);
  _put(m, 'transitionMs', g.transitionMs);
  return m;
}

void _globalsFromJson(GlobalTokens g, Map<String, Object?> m) {
  g
    ..radius = _d(m['radius'])
    ..pillButtons = _b(m['pillButtons'])
    ..borderWidth = _d(m['borderWidth'])
    ..shadowStyle = _enum(ShadowStyle.values, m['shadowStyle'])
    ..shadowLevel = m['shadowLevel'] is int ? m['shadowLevel'] as int : null
    ..controlHeight = _d(m['controlHeight'])
    ..press = _enum(PressEffect.values, m['press'])
    ..transitionMs = _d(m['transitionMs']);
}

// --- Edits (ThemeConfig) ------------------------------------------------------------

Map<String, Object?> _configToJson(ThemeConfig c) {
  final m = <String, Object?>{};
  _put(m, 'seed', c.seed == null ? null : _hex(c.seed!));
  _put(m, 'schemeVariant', c.schemeVariant?.name);
  _put(m, 'fontFamily', c.fontFamily);
  _put(m, 'headFontFamily', c.headFontFamily);
  _put(m, 'schemeOverrides', {
    for (final e in c.schemeOverrides.entries)
      e.key.name: colorRefToJson(e.value),
  });
  _put(m, 'density', c.density?.name);
  _put(m, 'shrinkWrap', c.shrinkWrap);
  _put(m, 'buttons', {
    for (final e in c.buttons.entries)
      if (!e.value.isEmpty) e.key.name: _buttonToJson(e.value),
  });
  _put(m, 'buttonSizes', {
    for (final e in c.buttonSizes.entries)
      if (!e.value.isEmpty) e.key.name: _sizeToJson(e.value),
  });
  if (!c.textField.isEmpty) m['textField'] = _fieldToJson(c.textField);
  _put(m, 'typography', {
    for (final e in c.typography.styles.entries)
      if (!e.value.isEmpty) e.key.name: _typeToJson(e.value),
  });
  _put(m, 'surfaces', {
    for (final e in c.surfaces.entries)
      if (!e.value.isEmpty) e.key.name: _surfaceToJson(e.value),
  });
  return m;
}

void _configFromJson(ThemeConfig c, Map<String, Object?> m) {
  c
    ..seed = _color(m['seed'])
    ..schemeVariant = _enum(DynamicSchemeVariant.values, m['schemeVariant'])
    ..fontFamily = _s(m['fontFamily'])
    ..headFontFamily = _s(m['headFontFamily'])
    ..density = _enum(DensityOption.values, m['density'])
    ..shrinkWrap = _b(m['shrinkWrap']);
  for (final e in _map(m['schemeOverrides']).entries) {
    final role = _enum(SchemeRole.values, e.key);
    final ref = colorRefFromJson(e.value);
    if (role != null && ref != null) c.schemeOverrides[role] = ref;
  }
  for (final e in _map(m['buttons']).entries) {
    final k = _enum(ButtonKind.values, e.key);
    if (k != null) _buttonFromJson(c.buttons[k]!, _map(e.value));
  }
  for (final e in _map(m['buttonSizes']).entries) {
    final k = _enum(ButtonSizeKey.values, e.key);
    if (k != null) _sizeFromJson(c.buttonSizes[k]!, _map(e.value));
  }
  _fieldFromJson(c.textField, _map(m['textField']));
  for (final e in _map(m['typography']).entries) {
    final r = _enum(TextRole.values, e.key);
    if (r != null) _typeFromJson(c.typography.styles[r]!, _map(e.value));
  }
  for (final e in _map(m['surfaces']).entries) {
    final k = _enum(SurfaceKind.values, e.key);
    if (k != null) _surfaceFromJson(c.surfaces[k]!, _map(e.value));
  }
}

Map<String, Object?> _stateToJson(StateStyle s) {
  final m = <String, Object?>{};
  _put(m, 'fill', colorRefToJson(s.fill));
  _put(m, 'fillEnd', colorRefToJson(s.fillEnd));
  _put(m, 'foreground', colorRefToJson(s.foreground));
  _put(m, 'border', colorRefToJson(s.border));
  _put(m, 'shadow', s.shadow?.name);
  _put(m, 'shadowColor', colorRefToJson(s.shadowColor));
  _put(m, 'offsetX', s.offsetX);
  _put(m, 'offsetY', s.offsetY);
  return m;
}

void _stateFromJson(StateStyle s, Map<String, Object?> m) {
  s
    ..fill = colorRefFromJson(m['fill'])
    ..fillEnd = colorRefFromJson(m['fillEnd'])
    ..foreground = colorRefFromJson(m['foreground'])
    ..border = colorRefFromJson(m['border'])
    ..shadow = _enum(ShadowToken.values, m['shadow'])
    ..shadowColor = colorRefFromJson(m['shadowColor'])
    ..offsetX = _d(m['offsetX'])
    ..offsetY = _d(m['offsetY']);
}

Map<String, Object?> _buttonToJson(ButtonConfig b) {
  final m = <String, Object?>{};
  _put(m, 'states', {
    for (final e in b.states.entries)
      if (!e.value.isEmpty) e.key.name: _stateToJson(e.value),
  });
  _put(m, 'borderWidth', b.borderWidth);
  _put(m, 'radius', b.radius);
  _put(m, 'paddingH', b.paddingH);
  _put(m, 'paddingV', b.paddingV);
  _put(m, 'minHeight', b.minHeight);
  _put(m, 'minWidth', b.minWidth);
  _put(m, 'iconSize', b.iconSize);
  _put(m, 'fontSize', b.fontSize);
  _put(m, 'fontWeight', b.fontWeight?.value);
  _put(m, 'letterSpacing', b.letterSpacing);
  _put(m, 'lineHeight', b.lineHeight);
  _put(m, 'hoverUnderline', b.hoverUnderline);
  _put(m, 'headFont', b.headFont);
  _put(m, 'pressScale', b.pressScale);
  _put(m, 'focusRing', colorRefToJson(b.focusRing));
  _put(m, 'focusRingWidth', b.focusRingWidth);
  _put(m, 'focusRingOffset', b.focusRingOffset);
  _put(m, 'focusRingOffsetColor', colorRefToJson(b.focusRingOffsetColor));
  _put(m, 'transitionMs', b.transitionMs);
  return m;
}

void _buttonFromJson(ButtonConfig b, Map<String, Object?> m) {
  for (final e in _map(m['states']).entries) {
    final k = _enum(ButtonStateKey.values, e.key);
    if (k != null) _stateFromJson(b.states[k]!, _map(e.value));
  }
  b
    ..borderWidth = _d(m['borderWidth'])
    ..radius = _d(m['radius'])
    ..paddingH = _d(m['paddingH'])
    ..paddingV = _d(m['paddingV'])
    ..minHeight = _d(m['minHeight'])
    ..minWidth = _d(m['minWidth'])
    ..iconSize = _d(m['iconSize'])
    ..fontSize = _d(m['fontSize'])
    ..fontWeight = _weight(m['fontWeight'])
    ..letterSpacing = _d(m['letterSpacing'])
    ..lineHeight = _d(m['lineHeight'])
    ..hoverUnderline = _b(m['hoverUnderline'])
    ..headFont = _b(m['headFont'])
    ..pressScale = _d(m['pressScale'])
    ..focusRing = colorRefFromJson(m['focusRing'])
    ..focusRingWidth = _d(m['focusRingWidth'])
    ..focusRingOffset = _d(m['focusRingOffset'])
    ..focusRingOffsetColor = colorRefFromJson(m['focusRingOffsetColor'])
    ..transitionMs = _d(m['transitionMs']);
}

Map<String, Object?> _sizeToJson(ButtonSizeSpec s) {
  final m = <String, Object?>{};
  _put(m, 'radius', s.radius);
  _put(m, 'paddingH', s.paddingH);
  _put(m, 'paddingV', s.paddingV);
  _put(m, 'minHeight', s.minHeight);
  _put(m, 'iconSize', s.iconSize);
  _put(m, 'fontSize', s.fontSize);
  _put(m, 'fontWeight', s.fontWeight?.value);
  _put(m, 'letterSpacing', s.letterSpacing);
  _put(m, 'lineHeight', s.lineHeight);
  return m;
}

void _sizeFromJson(ButtonSizeSpec s, Map<String, Object?> m) {
  s
    ..radius = _d(m['radius'])
    ..paddingH = _d(m['paddingH'])
    ..paddingV = _d(m['paddingV'])
    ..minHeight = _d(m['minHeight'])
    ..iconSize = _d(m['iconSize'])
    ..fontSize = _d(m['fontSize'])
    ..fontWeight = _weight(m['fontWeight'])
    ..letterSpacing = _d(m['letterSpacing'])
    ..lineHeight = _d(m['lineHeight']);
}

Map<String, Object?> _fieldStateToJson(FieldStateStyle s) {
  final m = <String, Object?>{};
  _put(m, 'fill', colorRefToJson(s.fill));
  _put(m, 'border', colorRefToJson(s.border));
  _put(m, 'borderWidth', s.borderWidth);
  _put(m, 'placeholder', colorRefToJson(s.placeholder));
  _put(m, 'icon', colorRefToJson(s.icon));
  _put(m, 'shadow', s.shadow?.name);
  _put(m, 'shadowColor', colorRefToJson(s.shadowColor));
  return m;
}

void _fieldStateFromJson(FieldStateStyle s, Map<String, Object?> m) {
  s
    ..fill = colorRefFromJson(m['fill'])
    ..border = colorRefFromJson(m['border'])
    ..borderWidth = _d(m['borderWidth'])
    ..placeholder = colorRefFromJson(m['placeholder'])
    ..icon = colorRefFromJson(m['icon'])
    ..shadow = _enum(ShadowToken.values, m['shadow'])
    ..shadowColor = colorRefFromJson(m['shadowColor']);
}

Map<String, Object?> _fieldToJson(TextFieldConfig f) {
  final m = <String, Object?>{};
  _put(m, 'states', {
    for (final e in f.states.entries)
      if (!e.value.isEmpty) e.key.name: _fieldStateToJson(e.value),
  });
  _put(m, 'radius', f.radius);
  _put(m, 'dense', f.dense);
  _put(m, 'underline', f.underline);
  _put(m, 'textInset', f.textInset);
  _put(m, 'paddingEnd', f.paddingEnd);
  _put(m, 'paddingV', f.paddingV);
  _put(m, 'iconBox', f.iconBox);
  _put(m, 'inputFontSize', f.inputFontSize);
  _put(m, 'inputWeight', f.inputWeight?.value);
  _put(m, 'inputLineHeight', f.inputLineHeight);
  _put(m, 'inputLetterSpacing', f.inputLetterSpacing);
  _put(m, 'inputColor', colorRefToJson(f.inputColor));
  _put(m, 'cursor', colorRefToJson(f.cursor));
  _put(m, 'helperFontSize', f.helperFontSize);
  _put(m, 'helperWeight', f.helperWeight?.value);
  _put(m, 'helperLetterSpacing', f.helperLetterSpacing);
  _put(m, 'helperColor', colorRefToJson(f.helperColor));
  _put(m, 'errorColor', colorRefToJson(f.errorColor));
  return m;
}

void _fieldFromJson(TextFieldConfig f, Map<String, Object?> m) {
  for (final e in _map(m['states']).entries) {
    final k = _enum(FieldStateKey.values, e.key);
    if (k != null) _fieldStateFromJson(f.states[k]!, _map(e.value));
  }
  f
    ..radius = _d(m['radius'])
    ..dense = _b(m['dense'])
    ..underline = _b(m['underline'])
    ..textInset = _d(m['textInset'])
    ..paddingEnd = _d(m['paddingEnd'])
    ..paddingV = _d(m['paddingV'])
    ..iconBox = _d(m['iconBox'])
    ..inputFontSize = _d(m['inputFontSize'])
    ..inputWeight = _weight(m['inputWeight'])
    ..inputLineHeight = _d(m['inputLineHeight'])
    ..inputLetterSpacing = _d(m['inputLetterSpacing'])
    ..inputColor = colorRefFromJson(m['inputColor'])
    ..cursor = colorRefFromJson(m['cursor'])
    ..helperFontSize = _d(m['helperFontSize'])
    ..helperWeight = _weight(m['helperWeight'])
    ..helperLetterSpacing = _d(m['helperLetterSpacing'])
    ..helperColor = colorRefFromJson(m['helperColor'])
    ..errorColor = colorRefFromJson(m['errorColor']);
}

Map<String, Object?> _typeToJson(TypeSpec t) {
  final m = <String, Object?>{};
  _put(m, 'size', t.size);
  _put(m, 'lineHeight', t.lineHeight);
  _put(m, 'weight', t.weight?.value);
  _put(m, 'letterSpacing', t.letterSpacing);
  _put(m, 'headFont', t.headFont);
  return m;
}

void _typeFromJson(TypeSpec t, Map<String, Object?> m) {
  t
    ..size = _d(m['size'])
    ..lineHeight = _d(m['lineHeight'])
    ..weight = _weight(m['weight'])
    ..letterSpacing = _d(m['letterSpacing'])
    ..headFont = _b(m['headFont']);
}

Map<String, Object?> _surfaceToJson(SurfaceConfig s) {
  final m = <String, Object?>{};
  _put(m, 'background', colorRefToJson(s.background));
  _put(m, 'foreground', colorRefToJson(s.foreground));
  _put(m, 'borderColor', colorRefToJson(s.borderColor));
  _put(m, 'borderWidth', s.borderWidth);
  _put(m, 'radius', s.radius);
  _put(m, 'elevation', s.elevation);
  _put(m, 'accent', colorRefToJson(s.accent));
  _put(m, 'titleStyle', s.titleStyle?.name);
  _put(m, 'bodyStyle', s.bodyStyle?.name);
  _put(m, 'height', s.height);
  _put(m, 'shadow', s.shadow?.name);
  _put(m, 'paddingH', s.paddingH);
  _put(m, 'paddingV', s.paddingV);
  _put(m, 'innerRadius', s.innerRadius);
  _put(m, 'selectedForeground', colorRefToJson(s.selectedForeground));
  _put(m, 'accentEnd', colorRefToJson(s.accentEnd));
  _put(m, 'shadowColor', colorRefToJson(s.shadowColor));
  _put(m, 'width', s.width);
  _put(m, 'thumbSize', s.thumbSize);
  _put(m, 'trackBorderWidth', s.trackBorderWidth);
  return m;
}

void _surfaceFromJson(SurfaceConfig s, Map<String, Object?> m) {
  s
    ..background = colorRefFromJson(m['background'])
    ..foreground = colorRefFromJson(m['foreground'])
    ..borderColor = colorRefFromJson(m['borderColor'])
    ..borderWidth = _d(m['borderWidth'])
    ..radius = _d(m['radius'])
    ..elevation = _d(m['elevation'])
    ..accent = colorRefFromJson(m['accent'])
    ..titleStyle = _enum(TextRole.values, m['titleStyle'])
    ..bodyStyle = _enum(TextRole.values, m['bodyStyle'])
    ..height = _d(m['height'])
    ..shadow = _enum(ShadowToken.values, m['shadow'])
    ..paddingH = _d(m['paddingH'])
    ..paddingV = _d(m['paddingV'])
    ..innerRadius = _d(m['innerRadius'])
    ..selectedForeground = colorRefFromJson(m['selectedForeground'])
    ..accentEnd = colorRefFromJson(m['accentEnd'])
    ..shadowColor = colorRefFromJson(m['shadowColor'])
    ..width = _d(m['width'])
    ..thumbSize = _d(m['thumbSize'])
    ..trackBorderWidth = _d(m['trackBorderWidth']);
}
