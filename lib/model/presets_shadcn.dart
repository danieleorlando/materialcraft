import 'package:flutter/material.dart';

import 'color_math.dart';
import 'color_ref.dart';
import 'shadcn_style_spec.dart';
import 'shadcn_styles.dart';
import 'shadcn_tokens.dart';
import 'shadow_token.dart';
import 'surface_config.dart';
import 'text_field_config.dart';
import 'theme_config.dart';
import 'typography_config.dart';

/// shadcn/ui base colors (the neutrals of the whole theme).
const shadcnBaseNames = <String, String>{
  'neutral': 'Neutral',
  'stone': 'Stone',
  'zinc': 'Zinc',
  'mauve': 'Mauve',
  'olive': 'Olive',
  'mist': 'Mist',
  'taupe': 'Taupe',
};

/// The shadcn/ui variants: the classic style and the 8 of the new system.
const shadcnStyleNames = <String, String>{
  'new-york': 'New York · classic (new-york-v4)',
  'vega': 'Vega · clean, neutral, familiar',
  'nova': 'Nova · reduced padding and margins',
  'maia': 'Maia · rounded, spacious',
  'lyra': 'Lyra · boxy, for mono fonts',
  'mira': 'Mira · compact',
  'luma': 'Luma · fluid, soft',
  'rhea': 'Rhea · like Luma but compact',
  'sera': 'Sera · editorial and typographic',
};

ShadcnStyleSpec shadcnSpec(String style) =>
    style == 'new-york' ? ShadcnStyleSpec.newYork : shadcnStyles[style]!;

/// shadcn/ui: base color ([base], the neutrals), optional accent
/// ([accent], official or generated with `registerShadcnAccent`) and [style],
/// one of the [shadcnStyleNames] variants. Each style's values come from the
/// sources (new-york-v4/ui for the classic one, registry/styles/style-*.css
/// for the others, see tool/gen_shadcn_styles.py).
void applyShadcn(
  ThemeConfig c, {
  String base = 'neutral',
  String? accent,
  String style = 'new-york',
}) {
  final spec = shadcnSpec(style);
  final k = _Kit(base, accent);

  c
    ..seedColor = ShadcnColor(base, accent, 'primary').token.light
    ..variant = DynamicSchemeVariant.fidelity
    ..fontFamily = spec.font
    ..density = DensityOption.standard
    ..shrinkWrapTapTargets = true;

  final t = k.t;
  c.schemeOverrides.addAll({
    SchemeRole.primary: t('primary'),
    SchemeRole.onPrimary: t('primary-foreground'),
    SchemeRole.primaryContainer: t('accent'),
    SchemeRole.onPrimaryContainer: t('accent-foreground'),
    SchemeRole.secondary: t('secondary'),
    SchemeRole.onSecondary: t('secondary-foreground'),
    SchemeRole.secondaryContainer: t('secondary'),
    SchemeRole.onSecondaryContainer: t('secondary-foreground'),
    SchemeRole.tertiary: t('accent'),
    SchemeRole.onTertiary: t('accent-foreground'),
    SchemeRole.tertiaryContainer: t('muted'),
    SchemeRole.onTertiaryContainer: t('foreground'),
    SchemeRole.error: t('destructive'),
    SchemeRole.onError: const CustomColor(Color(0xFFFFFFFF)),
    SchemeRole.errorContainer: t('destructive', alpha: 0.1),
    SchemeRole.onErrorContainer: t('destructive'),
    SchemeRole.surface: t('background'),
    SchemeRole.onSurface: t('foreground'),
    SchemeRole.onSurfaceVariant: t('muted-foreground'),
    SchemeRole.surfaceContainerLowest: t('background'),
    SchemeRole.surfaceContainerLow: t('card'),
    SchemeRole.surfaceContainer: t('popover'),
    SchemeRole.surfaceContainerHigh: t('popover'),
    SchemeRole.surfaceContainerHighest: t('muted'),
    SchemeRole.outline: t('input'),
    SchemeRole.outlineVariant: t('border'),
    SchemeRole.inverseSurface: t('foreground'),
    SchemeRole.onInverseSurface: t('background'),
    SchemeRole.inversePrimary: t('primary'),
  });

  _typography(c.typography, spec);
  _buttons(c, k, spec);
  _textField(c.textField, k, spec);
  _surfaces(c, k, spec);
}

/// References to the tokens of a shadcn theme (base + accent).
class _Kit {
  _Kit(this.base, this.accent);

  final String base;
  final String? accent;

  ColorRef t(String name, {double alpha = 1}) =>
      ShadcnColor(base, accent, name, alpha: alpha);

  ShadcnColor _c(String name, double alpha) =>
      ShadcnColor(base, accent, name, alpha: alpha);

  /// Dark variants that use another token (e.g. dark:bg-input/30).
  ColorRef ld(String light, String dark, {double la = 1, double da = 1}) =>
      AdaptiveColor(_c(light, la).light, _c(dark, da).dark);

  /// Reference as in CSS: "muted", "input/30", "transparent".
  (String, double) _parse(String ref) {
    if (ref == 'transparent') return ('background', 0);
    final i = ref.indexOf('/');
    return i < 0
        ? (ref, 1)
        : (ref.substring(0, i), int.parse(ref.substring(i + 1)) / 100);
  }

  /// [light] and [dark] as CSS references (dark null = same as light).
  ColorRef refs(String light, String? dark) {
    final (ln, la) = _parse(light);
    final (dn, da) = _parse(dark ?? light);
    if (ln == dn && la == da) return t(ln, alpha: la);
    return ld(ln, dn, la: la, da: da);
  }

  /// color-mix(in oklch, var(--a), var(--b) p%) in light and dark.
  ColorRef mix(String a, String b, double p) {
    final x = _c(a, 1);
    final y = _c(b, 1);
    return AdaptiveColor(
      mixColors(y.light, p, x.light, MixSpace.oklab),
      mixColors(y.dark, p, x.dark, MixSpace.oklab),
    );
  }
}

ShadowToken _shadow(String s) => switch (s) {
  'xs' => ShadowToken.twXs,
  'sm' => ShadowToken.twSm,
  'md' => ShadowToken.twMd,
  'lg' => ShadowToken.twLg,
  'xl' => ShadowToken.twXl,
  _ => ShadowToken.none,
};

TextRole _role(double fontSize) =>
    fontSize <= 12 ? TextRole.bodySmall : TextRole.bodyMedium;

FontWeight _weight(int w) => FontWeight.values[(w ~/ 100 - 1).clamp(0, 8)];

/// Tailwind type scale; headings font-semibold tracking-tight.
void _typography(TypographyConfig ty, ShadcnStyleSpec spec) {
  void set(
    TextRole role,
    double size,
    double lh,
    FontWeight w, {
    bool tight = false,
    double spacing = 0,
  }) {
    ty.styles[role] = TypeSpec(
      size: size,
      lineHeight: lh,
      weight: w,
      // tracking-tight = -0,025em.
      letterSpacing: tight
          ? double.parse((-size * 0.025).toStringAsFixed(2))
          : double.parse(spacing.toStringAsFixed(2)),
      source: 'shadcn ${spec.name}',
    );
  }

  const semibold = FontWeight.w600;
  set(TextRole.displayLarge, 48, 48, FontWeight.w800, tight: true);
  set(TextRole.displayMedium, 36, 40, FontWeight.w800, tight: true);
  set(TextRole.displaySmall, 30, 36, semibold, tight: true);
  set(TextRole.headlineLarge, 30, 36, semibold, tight: true);
  set(TextRole.headlineMedium, 24, 32, semibold, tight: true);
  set(TextRole.headlineSmall, 20, 28, semibold, tight: true);
  set(TextRole.titleLarge, 18, 28, semibold);
  set(TextRole.titleMedium, 16, 24, semibold);
  set(TextRole.titleSmall, 14, 20, semibold);
  set(TextRole.bodyLarge, 16, 24, FontWeight.w400);
  set(TextRole.bodyMedium, 14, 20, FontWeight.w400);
  set(TextRole.bodySmall, 12, 16, FontWeight.w400);
  // Buttons and tabs: the style's text (text-sm, text-xs, …).
  set(
    TextRole.labelLarge,
    spec.buttonFontSize,
    spec.buttonLineHeight,
    _weight(spec.buttonWeight),
    spacing: spec.buttonTracking * spec.buttonFontSize,
  );
  set(TextRole.labelMedium, 12, 16, FontWeight.w500);
  set(TextRole.labelSmall, 12, 16, FontWeight.w500);
}

void _buttons(ThemeConfig c, _Kit k, ShadcnStyleSpec spec) {
  final t = k.t;
  final (h, px, (fs, lh), _) = spec.sizes['default']!;
  final height = h ?? 36;
  final weight = _weight(spec.buttonWeight);
  final tracking = double.parse((spec.buttonTracking * fs).toStringAsFixed(2));

  void geometry(ButtonConfig b) {
    b
      ..radius = spec.buttonRadius
      ..paddingH = px
      ..paddingV = ((height - lh) / 2).floorToDouble()
      ..minHeight = height
      ..minWidth = 0
      ..iconSize = 16
      ..fontSize = fs
      ..lineHeight = lh
      ..fontWeight = weight
      ..letterSpacing = tracking
      ..focusRing = t('ring', alpha: spec.ringAlpha)
      ..focusRingWidth = spec.ringWidth
      ..focusRingOffset = 0
      ..transitionMs = 150;
    // active:translate-y-px
    if (spec.pressDown) b.states[ButtonStateKey.pressed]!.offsetY = 1;
  }

  void solid(ButtonConfig b, ColorRef fill, ColorRef fg, ColorRef hover) {
    geometry(b);
    b.states[ButtonStateKey.normal]!
      ..fill = fill
      ..foreground = fg
      ..shadow = ShadowToken.none;
    b.states[ButtonStateKey.hovered]!.fill = hover;
    b.states[ButtonStateKey.pressed]!.fill = hover;
  }

  void disabled(
    ButtonConfig b,
    ColorRef? fill,
    ColorRef fg, [
    ColorRef? border,
  ]) {
    b.states[ButtonStateKey.disabled]!
      ..fill = fill
      ..foreground = fg
      ..border = border;
  }

  // default → FilledButton: hover bg-primary/90 (classic) or /80 (new).
  final filled = c.buttons[ButtonKind.filled]!;
  solid(
    filled,
    t('primary'),
    t('primary-foreground'),
    t('primary', alpha: spec.primaryHoverAlpha),
  );
  disabled(
    filled,
    t('primary', alpha: 0.5),
    t('primary-foreground', alpha: 0.5),
  );

  // secondary → ElevatedButton: hover secondary/80, in the new styles
  // color-mix(secondary, foreground 5%).
  final secondary = c.buttons[ButtonKind.elevated]!;
  solid(
    secondary,
    t('secondary'),
    t('secondary-foreground'),
    spec.secondaryHoverMix
        ? k.mix('secondary', 'foreground', 0.05)
        : t('secondary', alpha: 0.8),
  );
  disabled(
    secondary,
    t('secondary', alpha: 0.5),
    t('secondary-foreground', alpha: 0.5),
  );

  // Hover text: accent-foreground with hover:bg-accent, otherwise
  // foreground (hover:text-foreground in the new styles).
  ColorRef hoverText(String? hover) =>
      hover != null && hover.startsWith('accent')
      ? t('accent-foreground')
      : t('foreground');

  // outline → OutlinedButton.
  void outlined(ButtonConfig b) {
    geometry(b);
    b.borderWidth = 1;
    b.states[ButtonStateKey.normal]!
      ..fill = k.refs(spec.outlineBg ?? 'transparent', spec.outlineBgDark)
      ..foreground = t('foreground')
      ..border = k.ld('border', 'input')
      ..shadow = spec.outlineShadow ? ShadowToken.twXs : ShadowToken.none;
    for (final s in [ButtonStateKey.hovered, ButtonStateKey.pressed]) {
      b.states[s]!
        ..fill = k.refs(spec.outlineHover ?? 'muted', spec.outlineHoverDark)
        ..foreground = hoverText(spec.outlineHover);
    }
    // focus-visible:border-ring
    b.states[ButtonStateKey.focused]!.border = t('ring');
    disabled(
      b,
      k.ld('background', 'input', la: 0.5, da: 0.15),
      t('foreground', alpha: 0.5),
      k.ld('border', 'input', la: 0.5, da: 0.5),
    );
  }

  outlined(c.buttons[ButtonKind.outlined]!);

  // destructive → danger extra style. Classic: solid (text-white,
  // dark:bg-destructive/60); new styles: soft (bg-destructive/10
  // text-destructive, dark /20, hover /20 and /30).
  final danger = c.buttons[ButtonKind.danger]!;
  if (spec.destructiveSoft) {
    solid(
      danger,
      k.ld('destructive', 'destructive', la: 0.1, da: 0.2),
      t('destructive'),
      k.ld('destructive', 'destructive', la: 0.2, da: 0.3),
    );
    disabled(
      danger,
      k.ld('destructive', 'destructive', la: 0.05, da: 0.1),
      t('destructive', alpha: 0.5),
    );
  } else {
    solid(
      danger,
      k.ld('destructive', 'destructive', da: 0.6),
      const CustomColor(Color(0xFFFFFFFF)),
      t('destructive', alpha: 0.9),
    );
    disabled(
      danger,
      k.ld('destructive', 'destructive', la: 0.5, da: 0.3),
      const CustomColor(Color(0x80FFFFFF)),
    );
  }
  danger.focusRing = k.ld('destructive', 'destructive', la: 0.2, da: 0.4);

  // link → TextButton: text-primary hover:underline.
  final link = c.buttons[ButtonKind.text]!
    ..radius = spec.buttonRadius
    ..paddingH = px
    ..paddingV = ((height - lh) / 2).floorToDouble()
    ..minHeight = height
    ..minWidth = 0
    ..iconSize = 16
    ..fontSize = fs
    ..lineHeight = lh
    ..fontWeight = weight
    ..letterSpacing = tracking
    ..hoverUnderline = true;
  link.states[ButtonStateKey.normal]!.foreground = t('primary');
  link.states[ButtonStateKey.disabled]!.foreground = t('primary', alpha: 0.5);

  // ghost: hover:bg-accent (classic) or hover:bg-muted (new).
  void ghostLike(ButtonConfig b) {
    b.states[ButtonStateKey.normal]!
      ..foreground = t('foreground')
      ..shadow = ShadowToken.none;
    for (final s in [ButtonStateKey.hovered, ButtonStateKey.pressed]) {
      b.states[s]!
        ..fill = k.refs(spec.ghostHover ?? 'muted', spec.ghostHoverDark)
        ..foreground = hoverText(spec.ghostHover);
    }
    b.states[ButtonStateKey.disabled]!.foreground = t('foreground', alpha: 0.5);
  }

  final ghost = c.buttons[ButtonKind.ghost]!;
  geometry(ghost);
  ghostLike(ghost);

  // size="icon": ghost for the theme's IconButton, outline for the secondary.
  final iconSide = spec.sizes['icon']!.$1 ?? height;
  void iconGeometry(ButtonConfig b) {
    geometry(b);
    final p = ((iconSide - 16) / 2).floorToDouble();
    b
      ..minHeight = iconSide
      ..minWidth = iconSide
      ..paddingH = p
      ..paddingV = p;
  }

  final icon = c.buttons[ButtonKind.icon]!;
  iconGeometry(icon);
  ghostLike(icon);

  final iconOutline = c.buttons[ButtonKind.iconSecondary]!;
  outlined(iconOutline);
  iconGeometry(iconOutline);

  // The style's lg / sm / xs sizes.
  void sizeSpec(ButtonSizeKey key, String name) {
    final (sh, spx, (sfs, slh), sr) = spec.sizes[name]!;
    final hh = sh ?? height;
    c.buttonSizes[key]!
      ..minHeight = hh
      ..paddingH = spx
      ..paddingV = ((hh - slh) / 2).floorToDouble().clamp(0, 99).toDouble()
      ..fontSize = sfs
      ..lineHeight = slh
      ..iconSize = sfs <= 12 ? 12 : 16
      ..radius = sr ?? spec.buttonRadius;
  }

  sizeSpec(ButtonSizeKey.large, 'lg');
  sizeSpec(ButtonSizeKey.small, 'sm');
  sizeSpec(ButtonSizeKey.xs, 'xs');
}

/// input: the style's height, radius, padding and text; focus-visible:ring
/// ring-ring/NN; aria-invalid:ring-destructive/20; dark:bg-input/30.
void _textField(TextFieldConfig f, _Kit k, ShadcnStyleSpec spec) {
  final t = k.t;
  final underline = spec.inputUnderline;
  // bg-input/50 with border-transparent (Luma, Rhea).
  final filled = spec.inputFillAlpha >= 0.5;
  final inset = underline ? 0.0 : spec.inputPaddingH + 1; // + border
  f
    ..radius = spec.inputRadius
    ..underline = underline ? true : null
    ..dense = true
    ..textInset = inset
    ..paddingEnd = inset
    ..paddingV = ((spec.inputHeight - spec.inputLineHeight) / 2).floorToDouble()
    ..iconBox = spec.inputHeight
    ..inputFontSize = spec.inputFontSize
    ..inputLineHeight = spec.inputLineHeight
    ..inputWeight = FontWeight.w400
    ..inputLetterSpacing = 0
    ..inputColor = t('foreground')
    ..cursor = t('foreground')
    ..helperFontSize = spec.inputFontSize
    ..helperWeight = FontWeight.w400
    ..helperLetterSpacing = 0
    ..helperColor = t('muted-foreground')
    ..errorColor = t('destructive');

  final fillDark = underline
      ? 0.0
      : spec.inputFillAlpha > 0
      ? spec.inputFillAlpha
      : 0.3;
  final border = filled ? const CustomColor(Color(0x00000000)) : t('input');
  f.states[FieldStateKey.normal]!
    ..fill = k.ld('input', 'input', la: spec.inputFillAlpha, da: fillDark)
    ..border = border
    ..borderWidth = 1
    ..shadow = spec.inputShadow ? ShadowToken.twXs : null
    ..placeholder = t('muted-foreground')
    ..icon = t('muted-foreground');
  f.states[FieldStateKey.hovered]!.border = border;
  final ring = underline ? ShadowToken.none : ShadowToken.ring3;
  f.states[FieldStateKey.focused]!
    ..border = t('ring')
    ..borderWidth = 1
    ..shadow = ring
    ..shadowColor = t('ring', alpha: spec.inputRingAlpha);
  f.states[FieldStateKey.error]!
    ..border = t('destructive')
    ..borderWidth = 1
    ..shadow = ring
    ..shadowColor = k.ld('destructive', 'destructive', la: 0.2, da: 0.4);
  f.states[FieldStateKey.disabled]!
    ..fill = k.ld(
      'input',
      'input',
      la: spec.inputFillAlpha * 0.5,
      da: fillDark * 0.5,
    )
    ..border = filled ? border : t('input', alpha: 0.5)
    ..placeholder = t('muted-foreground', alpha: 0.5)
    ..icon = t('muted-foreground', alpha: 0.5)
    ..shadow = ShadowToken.none;
}

void _surfaces(ThemeConfig c, _Kit k, ShadcnStyleSpec spec) {
  final t = k.t;
  SurfaceConfig s(SurfaceKind kind) => c.surfaces[kind]!;
  const transparent = CustomColor(Color(0x00000000));
  final border = t('border');
  final classic = spec.name == 'new-york';

  // Border: `border` (classic) or ring-1 ring-foreground/NN (new).
  ColorRef edge((double, double)? ring) => ring == null
      ? border
      : k.ld('foreground', 'foreground', la: ring.$1, da: ring.$2);

  s(SurfaceKind.card)
    ..background = t('card')
    ..borderColor = edge(spec.cardRing)
    ..borderWidth = 1
    ..radius = spec.cardRadius
    ..elevation = 0
    ..shadow = _shadow(spec.cardShadow);

  s(SurfaceKind.dialog)
    ..background = classic ? t('background') : t('popover')
    ..borderColor = edge(spec.dialogRing)
    ..borderWidth = 1
    ..radius = spec.dialogRadius
    ..elevation = 0
    ..shadow = _shadow(spec.dialogShadow)
    ..titleStyle = TextRole.titleLarge
    ..bodyStyle = _role(spec.itemFontSize);

  s(SurfaceKind.bottomSheet)
    ..background = t('background')
    ..radius = 0
    ..elevation = 0
    ..shadow = ShadowToken.twLg
    ..accent = t('muted');

  s(SurfaceKind.appBar)
    ..background = t('background')
    ..foreground = t('foreground')
    ..borderColor = border
    ..borderWidth = 1
    ..elevation = 0
    ..titleStyle = TextRole.titleMedium;

  for (final kind in [SurfaceKind.navigationBar, SurfaceKind.navigationRail]) {
    s(kind)
      ..background = t('sidebar')
      ..accent = t('sidebar-accent')
      ..foreground = t('sidebar-accent-foreground')
      ..innerRadius = spec.itemRadius
      ..titleStyle = TextRole.labelMedium;
  }
  s(SurfaceKind.navigationBar).elevation = 0;

  s(SurfaceKind.listTile)
    ..titleStyle = _role(spec.itemFontSize)
    ..bodyStyle = TextRole.bodySmall
    ..foreground = t('foreground')
    ..accent = t('accent')
    ..radius = spec.itemRadius;

  s(SurfaceKind.divider)
    ..borderColor = border
    ..borderWidth = 1;

  s(SurfaceKind.fab)
    ..background = t('primary')
    ..foreground = t('primary-foreground')
    ..radius = spec.buttonRadius
    ..elevation = 0
    ..shadow = ShadowToken.twMd
    ..titleStyle = TextRole.labelLarge;

  s(SurfaceKind.tooltip)
    ..background = t('foreground')
    ..foreground = t('background')
    ..radius = spec.tooltipRadius
    ..bodyStyle = TextRole.bodySmall
    ..paddingH = 12
    ..paddingV = 6;

  // tabs, variant="line": Flutter's theme can't give the tab list the bg-muted
  // background (that the active trigger stands out on), so the
  // official line variant is used: after:h-0.5 bg-foreground.
  s(SurfaceKind.tabBar)
    ..accent = t('foreground')
    ..borderWidth = 2
    ..foreground = k.ld('foreground', 'muted-foreground', la: 0.6)
    ..borderColor = transparent
    ..titleStyle = TextRole.labelLarge
    ..bodyStyle = TextRole.labelLarge
    ..paddingH = 8;

  // Chips like toggle variant="outline": active bg-accent (classic) or
  // bg-muted (new).
  final toggleLh = spec.toggleFontSize <= 12 ? 16.0 : 20.0;
  s(SurfaceKind.chip)
    ..background = k.ld('input', 'input', la: 0, da: 0.3)
    ..foreground = t('foreground')
    ..accent = classic ? t('accent') : t('muted')
    ..selectedForeground = classic ? t('accent-foreground') : t('foreground')
    ..borderColor = t('input')
    ..borderWidth = 1
    ..radius = spec.toggleRadius
    ..bodyStyle = spec.toggleFontSize <= 12
        ? TextRole.labelMedium
        : TextRole.labelLarge
    ..paddingH = (spec.togglePaddingH - 2).clamp(0, 99).toDouble()
    ..paddingV = ((spec.toggleHeight - toggleLh - 2) / 2)
        .floorToDouble()
        .clamp(0, 99)
        .toDouble();

  s(SurfaceKind.badge)
    ..background = t('primary')
    ..foreground = t('primary-foreground')
    ..bodyStyle = TextRole.labelMedium
    ..height = 20
    ..paddingH = 8;

  s(SurfaceKind.menu)
    ..background = t('popover')
    ..borderColor = edge(spec.menuRing)
    ..borderWidth = 1
    ..radius = spec.menuRadius
    ..elevation = 0
    ..shadow = _shadow(spec.menuShadow)
    ..paddingH = spec.menuPadding
    ..foreground = t('popover-foreground')
    ..accent = t('accent')
    ..innerRadius = spec.itemRadius
    ..paddingV = spec.itemPaddingV
    ..bodyStyle = _role(spec.itemFontSize);

  s(SurfaceKind.snackBar)
    ..background = t('popover')
    ..foreground = t('popover-foreground')
    ..accent = t('primary')
    ..borderColor = border
    ..borderWidth = 1
    ..radius = spec.toastRadius
    ..elevation = 0
    ..bodyStyle = TextRole.bodyMedium;

  final checkFilled = spec.checkboxFillAlpha > 0;
  final checkFill = k.ld(
    'input',
    'input',
    la: spec.checkboxFillAlpha,
    da: checkFilled ? spec.checkboxFillAlpha : 0.3,
  );
  s(SurfaceKind.checkbox)
    ..accent = t('primary')
    ..selectedForeground = t('primary-foreground')
    ..background = checkFill
    ..borderColor = checkFilled ? transparent : t('input')
    ..borderWidth = 1
    ..radius = spec.checkboxRadius;

  s(SurfaceKind.radio)
    ..accent = t('primary')
    ..borderColor = checkFilled ? transparent : t('input')
    ..background = checkFill;

  s(SurfaceKind.switchControl)
    ..accent = t('primary')
    ..background = k.ld('input', 'input', da: 0.8)
    ..foreground = k.ld('background', 'foreground')
    ..selectedForeground = k.ld('background', 'primary-foreground')
    ..borderColor = transparent
    ..borderWidth = spec.switchBorder
    ..width = spec.switchWidth ?? 32
    ..height = spec.switchHeight ?? 18.4
    // AppSwitch has a square or round thumb: for Luma (24×16) the
    // height is used.
    ..thumbSize = spec.switchThumbHeight ?? 16;

  final thumbH = spec.sliderThumbHeight ?? 16;
  s(SurfaceKind.slider)
    ..accent = t('primary')
    ..background = spec.sliderTrackFillAlpha > 0
        ? t('input', alpha: spec.sliderTrackFillAlpha)
        : t('muted')
    ..height = spec.sliderTrack
    ..foreground = spec.sliderThumbFill == 'primary'
        ? t('primary')
        : const CustomColor(Color(0xFFFFFFFF))
    ..borderColor = switch (spec.sliderThumbBorder) {
      'ring' => t('ring'),
      'primary' => t('primary'),
      _ => null,
    }
    ..borderWidth = spec.sliderThumbBorder == 'none' ? null : 1
    ..trackBorderWidth = 0
    ..radius = thumbH / 2
    ..innerRadius = spec.sliderThumbRadius >= thumbH / 2
        ? null
        : spec.sliderThumbRadius
    ..shadow = _shadow(spec.sliderThumbShadow);
}

/// Official accent names, for the color grid.
Iterable<String> get shadcnAccentNames => shadcnAccents.keys;
