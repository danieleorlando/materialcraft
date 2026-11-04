import 'dart:math' as math;

import 'color_ref.dart';
import 'shadow_token.dart';
import 'surface_config.dart';
import 'text_field_config.dart';
import 'theme_config.dart';

enum ShadowStyle {
  none('None', 'flat, no shadows'),
  soft('Soft', 'blurred, like Material and BoardUI'),
  hard('Hard', 'offset and unblurred, like Neobrutalism');

  const ShadowStyle(this.label, this.hint);

  final String label;
  final String hint;
}

enum PressEffect {
  none('None', 'the button stays still'),
  scale('Shrink', 'shrinks slightly when pressed'),
  sink('Sink', 'moves down onto its shadow when pressed');

  const PressEffect(this.label, this.hint);

  final String label;
  final String hint;
}

/// Global properties: they apply to every component. `null` = as the
/// chosen style (the preset).
///
/// They apply on top of the preset and below the edits made by hand on a
/// single component, which always win.
class GlobalTokens {
  // Forma
  /// Control radius (buttons, fields, chips, tooltips). Containers
  /// (cards, dialogs) use 1.5×, small controls (checkboxes) ¼.
  double? radius;

  /// Pill-shaped buttons, regardless of [radius].
  bool? pillButtons;

  /// Border width, where the component has a border.
  double? borderWidth;

  // Depth
  ShadowStyle? shadowStyle;

  /// -1 = lighter, 0 = normal, +1 = stronger.
  int? shadowLevel;

  // Dimensioni
  /// Height of buttons and text fields (normal size).
  double? controlHeight;

  // Movimento
  PressEffect? press;
  double? transitionMs;

  bool get isEmpty =>
      radius == null &&
      pillButtons == null &&
      borderWidth == null &&
      shadowStyle == null &&
      shadowLevel == null &&
      controlHeight == null &&
      press == null &&
      transitionMs == null;

  void reset() {
    radius = null;
    pillButtons = null;
    borderWidth = null;
    shadowStyle = null;
    shadowLevel = null;
    controlHeight = null;
    press = null;
    transitionMs = null;
  }
}

/// Container radius (cards, dialogs, bottom sheets, menus) for [r].
double containerRadius(double r) => (r * 1.5).roundToDouble();

/// Small control radius (checkboxes) for [r].
double smallRadius(double r) => (r / 4).roundToDouble().clamp(0, 6);

/// Applies [g] to [c] (which already contains the preset).
void applyGlobals(ThemeConfig c, GlobalTokens g) {
  if (g.isEmpty) return;
  _shape(c, g);
  _borders(c, g);
  _depth(c, g);
  _size(c, g);
  _motion(c, g);
}

// --- Forma -------------------------------------------------------------------

const _pill = 999.0;

void _shape(ThemeConfig c, GlobalTokens g) {
  final r = g.radius;
  final pill = g.pillButtons;
  if (r == null && pill == null) return;

  final buttonR = pill == true ? _pill : r;
  if (buttonR != null) {
    for (final b in c.buttons.values) {
      b.radius = buttonR;
    }
    for (final s in c.buttonSizes.values) {
      if (s.radius != null) s.radius = buttonR;
    }
  } else if (pill == false) {
    // No pill but the style's radius: only remove the pills.
    for (final b in c.buttons.values) {
      if (b.radius == null || b.radius! >= _pill) b.radius = 8;
    }
  }
  if (r == null) return;

  c.textField.radius = r;
  final s = c.surfaces;
  for (final k in [
    SurfaceKind.chip,
    SurfaceKind.tooltip,
    SurfaceKind.snackBar,
  ]) {
    s[k]!.radius = r;
  }
  for (final k in [
    SurfaceKind.card,
    SurfaceKind.dialog,
    SurfaceKind.bottomSheet,
    SurfaceKind.menu,
    SurfaceKind.fab,
  ]) {
    s[k]!.radius = containerRadius(r);
  }
  s[SurfaceKind.checkbox]!.radius = smallRadius(r);

  // Indicators and thumbs: only if the style already has them square / rounded.
  for (final k in [
    SurfaceKind.tabBar,
    SurfaceKind.navigationBar,
    SurfaceKind.navigationRail,
  ]) {
    if (s[k]!.innerRadius != null) s[k]!.innerRadius = r;
  }
  final slider = s[SurfaceKind.slider]!;
  if (slider.innerRadius != null) slider.innerRadius = smallRadius(r) * 2;
  final sw = s[SurfaceKind.switchControl]!;
  if (sw.hasSwitchGeometry) {
    final h = sw.height ?? 32;
    sw.radius = math.min(r, h / 2);
    sw.innerRadius = math.max(0, math.min(r, h / 2) - 4);
  }
}

// --- Borders -----------------------------------------------------------------

void _borders(ThemeConfig c, GlobalTokens g) {
  final w = g.borderWidth;
  if (w == null) return;
  for (final e in c.buttons.entries) {
    final b = e.value;
    final hasBorder =
        e.key == ButtonKind.outlined ||
        (b.borderWidth ?? 0) > 0 ||
        b.normal.border != null;
    if (hasBorder) b.borderWidth = w;
  }
  final f = c.textField;
  f.states[_normalField]!.borderWidth = w;
  final focused = f.states[_focusedField]!;
  if (focused.borderWidth != null) focused.borderWidth = w;
  for (final s in c.surfaces.values) {
    if (s.borderWidth != null || s.borderColor != null) s.borderWidth = w;
  }
}

// --- Depth -------------------------------------------------------------------

/// Level of a shadow (1 = minimum, 7 = maximum), to move from one
/// family to another keeping the intensity.
int _level(ShadowToken t) => switch (t) {
  ShadowToken.none => 0,
  ShadowToken.xs2 || ShadowToken.hardXs => 1,
  ShadowToken.xs || ShadowToken.twXs || ShadowToken.hardSm => 2,
  ShadowToken.sm || ShadowToken.twSm || ShadowToken.hard => 3,
  ShadowToken.md || ShadowToken.twMd || ShadowToken.hardMd => 4,
  ShadowToken.dropdown => 5,
  ShadowToken.lg || ShadowToken.twLg || ShadowToken.hardLg => 6,
  ShadowToken.twXl => 7,
  ShadowToken.hardXl => 7,
  // The focus ring isn't a shadow: it stays as is (see map).
  ShadowToken.ring3 => 0,
};

ShadowToken _token(ShadowStyle style, int level) {
  if (style == ShadowStyle.none || level <= 0) return ShadowToken.none;
  final l = level.clamp(1, 7);
  return style == ShadowStyle.hard
      ? switch (l) {
          1 => ShadowToken.hardXs,
          2 => ShadowToken.hardSm,
          3 => ShadowToken.hard,
          4 => ShadowToken.hardMd,
          5 || 6 => ShadowToken.hardLg,
          _ => ShadowToken.hardXl,
        }
      : switch (l) {
          1 => ShadowToken.xs2,
          2 => ShadowToken.xs,
          3 => ShadowToken.sm,
          4 => ShadowToken.md,
          5 => ShadowToken.dropdown,
          _ => ShadowToken.lg,
        };
}

void _depth(ThemeConfig c, GlobalTokens g) {
  final shift = g.shadowLevel ?? 0;
  // Without a chosen type, the intensity applies to the preset's family.
  final style = g.shadowStyle;
  if (style == null && shift == 0) return;

  ShadowStyle familyOf(ShadowToken t) =>
      t.isHard ? ShadowStyle.hard : ShadowStyle.soft;
  ShadowToken? map(ShadowToken? t) {
    if (t == null) return null;
    if (t == ShadowToken.none || t == ShadowToken.ring3) return t;
    return _token(style ?? familyOf(t), _level(t) + shift);
  }

  // Buttons (only those drawn with ButtonSkin have shadows).
  for (final e in c.buttons.entries) {
    if (!e.key.allowsSkin) continue;
    final b = e.value;
    final hasAny = b.states.values.any(
      (s) => s.shadow != null && s.shadow != ShadowToken.none,
    );
    if (style == ShadowStyle.none) {
      b.normal.shadow = ShadowToken.none;
      for (final s in b.states.values) {
        if (s != b.normal) s.shadow = null;
      }
      continue;
    }
    if (hasAny) {
      for (final s in b.states.values) {
        s.shadow = map(s.shadow);
      }
    } else if (style == ShadowStyle.hard && _hardButton(e.key)) {
      b.normal
        ..shadow = _token(ShadowStyle.hard, 4 + shift)
        ..shadowColor ??= _addedShadowColor;
    } else if (e.key.m3Shadow != null && (style != null || shift != 0)) {
      b.normal.shadow = _token(
        style ?? ShadowStyle.soft,
        _level(e.key.m3Shadow!) + shift,
      );
    }
  }

  // Text fields: hard shadows only.
  final f = c.textField;
  final fieldHard = f.states.values.any((s) => s.shadow?.isHard ?? false);
  if (style == ShadowStyle.hard || (style == null && fieldHard)) {
    if (fieldHard) {
      for (final s in f.states.values) {
        s.shadow = map(s.shadow);
      }
    } else {
      f.states[_normalField]!
        ..shadow = _token(ShadowStyle.hard, 4 + shift)
        ..shadowColor ??= _addedShadowColor;
    }
  } else if (style != null) {
    for (final s in f.states.values) {
      s.shadow = null;
    }
  }

  // Containers: hard shadow with HardShadowBorder, soft with Material
  // elevation.
  const defaults = {
    SurfaceKind.card: 4,
    SurfaceKind.dialog: 6,
    SurfaceKind.menu: 4,
    SurfaceKind.fab: 4,
  };
  for (final e in c.surfaces.entries) {
    final s = e.value;
    final k = e.key;
    if (!k.props.containsKey(SurfaceProp.shadow)) continue;
    final hasHard = s.hasHardShadow;
    switch (style) {
      case ShadowStyle.none:
        s.shadow = null;
        if (k.props.containsKey(SurfaceProp.elevation)) s.elevation = 0;
      case ShadowStyle.hard:
        if (hasHard) {
          s.shadow = map(s.shadow);
        } else if (defaults[k] case final level?) {
          s
            ..shadow = _token(ShadowStyle.hard, level + shift)
            ..shadowColor ??= _addedShadowColor;
        }
        if (s.shadow != null && k.props.containsKey(SurfaceProp.elevation)) {
          s.elevation = 0;
        }
      case ShadowStyle.soft:
        s.shadow = null;
        if (k.props.containsKey(SurfaceProp.elevation)) {
          final base = hasHard ? k.m3Elevation : (s.elevation ?? k.m3Elevation);
          s.elevation = _scaleElevation(base, shift);
        }
      case null:
        if (hasHard) {
          s.shadow = map(s.shadow);
        } else if (k.props.containsKey(SurfaceProp.elevation)) {
          s.elevation = _scaleElevation(s.elevation ?? k.m3Elevation, shift);
        }
    }
  }
}

bool _hardButton(ButtonKind k) =>
    k == ButtonKind.filled ||
    k == ButtonKind.elevated ||
    k == ButtonKind.outlined ||
    k == ButtonKind.danger ||
    k == ButtonKind.iconSecondary;

double _scaleElevation(double e, int shift) => switch (shift) {
  < 0 => (e / 2).roundToDouble(),
  > 0 => e == 0 ? 0 : e * 2,
  _ => e,
};

// --- Dimensioni --------------------------------------------------------------

void _size(ThemeConfig c, GlobalTokens g) {
  final h = g.controlHeight;
  if (h == null) return;
  for (final e in c.buttons.entries) {
    final b = e.value;
    if (e.key.isIconOnly) {
      final icon = b.iconSize ?? e.key.m3IconSize;
      final p = math.max(0.0, (h - icon) / 2).floorToDouble();
      b
        ..minHeight = h
        ..minWidth = h
        ..paddingH = p
        ..paddingV = p;
    } else {
      final lh = b.lineHeight ?? 20;
      b
        ..minHeight = h
        ..paddingV = math.max(0.0, (h - lh) / 2).floorToDouble();
    }
  }
  final f = c.textField;
  final lh = f.inputLineHeight ?? 24;
  f.paddingV = math.max(0.0, (h - lh) / 2).floorToDouble();
  // Below 48px a dense field is needed (no Material minimum height).
  if (h < 48) f.dense = true;
}

// --- Movimento ---------------------------------------------------------------

void _motion(ThemeConfig c, GlobalTokens g) {
  final press = g.press;
  final ms = g.transitionMs;
  if (press == null && ms == null) return;
  for (final e in c.buttons.entries) {
    if (!e.key.allowsSkin) continue;
    final b = e.value;
    if (ms != null) b.transitionMs = ms;
    if (press == null) continue;
    final moving = [
      ButtonStateKey.hovered,
      ButtonStateKey.pressed,
      ButtonStateKey.focused,
    ].map((k) => b.states[k]!);
    final hasOffsets = moving.any(
      (s) => s.offsetX != null || s.offsetY != null,
    );
    switch (press) {
      case PressEffect.none || PressEffect.scale:
        if (hasOffsets) {
          // Removes the "sink" effect: no offset and the same
          // shadow as the normal state.
          for (final s in moving) {
            s
              ..offsetX = null
              ..offsetY = null
              ..shadow = null;
          }
        }
        b.pressScale = press == PressEffect.scale ? 0.97 : null;
      case PressEffect.sink:
        b.pressScale = null;
        if (hasOffsets) continue; // the style already does it its own way
        final normal = b.normal.shadow;
        final pressed = b.states[ButtonStateKey.pressed]!;
        if (normal != null && normal.isHard) {
          final o = normal.hardOffset!;
          pressed
            ..offsetX = o
            ..offsetY = o
            ..shadow = ShadowToken.none;
        } else {
          pressed
            ..offsetY = 1
            ..shadow = ShadowToken.none;
        }
    }
  }
}

const _normalField = FieldStateKey.normal;
const _focusedField = FieldStateKey.focused;

/// Color of the hard shadows added where the style had none: the text
/// color, clearly visible in light and dark (outline would be too faint).
const _addedShadowColor = RoleColor(SchemeRole.onSurface);
