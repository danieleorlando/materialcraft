import 'package:flutter/material.dart';

import 'color_ref.dart';
import 'shadow_token.dart';
import 'surface_config.dart';
import 'text_field_config.dart';
import 'theme_config.dart';
import 'typography_config.dart';

/// RetroUI palette names (tool/neobrutalism/global.css).
const neoPaletteNames = <String, String>{
  'yellow': 'Yellow',
  'purple': 'Purple',
  'lime': 'Lime',
  'red': 'Red',
  'lavender': 'Lavender',
  'orange': 'Orange',
  'green': 'Green',
};

/// Applies RetroUI's neobrutalism style with the [palette] palette.
///
/// Values from `components/retroui/*.tsx` and `app/global.css` of
/// github.com/neobrutalism/neobrutalism (MIT):
/// - 2px borders: black for buttons (`border-black`), the text color
///   for the rest (`border-2` = currentColor);
/// - hard shadows `4px 4px 0 0 var(--border)` (shadow-md) and similar;
/// - buttons that move down 4px on hover (3px shadow) and "sink" when pressed
///   (4px, 8px, no shadow);
/// - Archivo Black for headings and buttons, Space Grotesk for body text;
/// - radius 0 (or 8px with `.with-radius`).
void applyNeobrutalism(ThemeConfig c, String palette, {double radius = 0}) {
  ColorRef t(String name) => PaletteColor(palette, name);
  const black = CustomColor(Color(0xFF000000));
  final r = radius;

  c
    ..seedColor = PaletteColor(palette, 'primary').token.light
    ..variant = DynamicSchemeVariant.fidelity
    ..fontFamily = 'Space Grotesk'
    ..headFontFamily = 'Archivo Black'
    ..density = DensityOption.standard
    ..shrinkWrapTapTargets = true;

  c.schemeOverrides.addAll({
    SchemeRole.primary: t('primary'),
    SchemeRole.onPrimary: t('primary-foreground'),
    SchemeRole.primaryContainer: t('accent'),
    SchemeRole.onPrimaryContainer: t('accent-foreground'),
    SchemeRole.secondary: t('secondary'),
    SchemeRole.onSecondary: t('secondary-foreground'),
    SchemeRole.secondaryContainer: t('muted'),
    SchemeRole.onSecondaryContainer: t('foreground'),
    SchemeRole.tertiary: t('accent'),
    SchemeRole.onTertiary: t('accent-foreground'),
    SchemeRole.tertiaryContainer: t('accent'),
    SchemeRole.onTertiaryContainer: t('accent-foreground'),
    SchemeRole.error: t('destructive'),
    SchemeRole.onError: t('destructive-foreground'),
    SchemeRole.errorContainer: t('destructive'),
    SchemeRole.onErrorContainer: t('destructive-foreground'),
    SchemeRole.surface: t('background'),
    SchemeRole.onSurface: t('foreground'),
    SchemeRole.onSurfaceVariant: t('muted-foreground'),
    SchemeRole.surfaceContainerLowest: t('card'),
    SchemeRole.surfaceContainerLow: t('card'),
    SchemeRole.surfaceContainer: t('popover'),
    SchemeRole.surfaceContainerHigh: t('card'),
    SchemeRole.surfaceContainerHighest: t('muted'),
    // outline = hard shadow color (--border); outlineVariant = borders
    // and dividers (currentColor, i.e. the text).
    SchemeRole.outline: t('border'),
    SchemeRole.outlineVariant: t('foreground'),
    SchemeRole.inverseSurface: t('foreground'),
    SchemeRole.onInverseSurface: t('background'),
    SchemeRole.inversePrimary: t('primary'),
  });

  _typography(c.typography);
  _buttons(c, t, black, r);
  _textField(c.textField, t, r);
  _surfaces(c, t, black, r);
}

/// Tailwind scale (text-base 16/24…), Archivo Black for headings.
void _typography(TypographyConfig ty) {
  void set(
    TextRole role,
    double size,
    double lh,
    FontWeight w, {
    bool head = false,
  }) {
    ty.styles[role] = TypeSpec(
      size: size,
      lineHeight: lh,
      weight: w,
      letterSpacing: 0,
      headFont: head ? true : null,
      source: head ? 'font-head' : 'font-sans',
    );
  }

  const regular = FontWeight.w400; // Archivo Black only has 400
  set(TextRole.displayLarge, 48, 48, regular, head: true); // text-5xl
  set(TextRole.displayMedium, 36, 40, regular, head: true); // text-4xl
  set(TextRole.displaySmall, 30, 36, regular, head: true); // text-3xl
  set(TextRole.headlineLarge, 30, 36, regular, head: true);
  set(TextRole.headlineMedium, 24, 32, regular, head: true); // text-2xl
  set(TextRole.headlineSmall, 20, 28, regular, head: true); // text-xl
  set(TextRole.titleLarge, 20, 28, regular, head: true);
  set(TextRole.titleMedium, 18, 28, regular, head: true); // text-lg
  set(TextRole.titleSmall, 16, 24, FontWeight.w600);
  set(TextRole.bodyLarge, 18, 28, regular);
  set(TextRole.bodyMedium, 16, 24, regular); // text-base
  set(TextRole.bodySmall, 14, 20, regular); // text-sm
  set(TextRole.labelLarge, 16, 24, FontWeight.w500);
  set(TextRole.labelMedium, 14, 20, FontWeight.w500);
  set(TextRole.labelSmall, 12, 16, FontWeight.w500); // text-xs
}

void _buttons(
  ThemeConfig c,
  ColorRef Function(String) t,
  ColorRef black,
  double r,
) {
  // Button.tsx: px-4 py-1.5 text-base font-head border-2, focus-visible:
  // outline-2 outline-offset-2 outline-primary, transition 200ms.
  // The border (2px) adds up in CSS: 16+2 horizontal (ButtonSkin adds it),
  // 6+2 vertical.
  void geometry(ButtonConfig b) => b
    ..radius = r
    ..borderWidth = 2
    ..paddingH = 16
    ..paddingV = 8
    ..minHeight = 40
    ..minWidth = 0
    ..iconSize = 20
    ..fontSize = 16
    ..lineHeight = 24
    ..fontWeight = FontWeight.w400
    ..letterSpacing = 0
    ..headFont = true
    ..focusRing = t('primary')
    ..focusRingWidth = 2
    ..focusRingOffset = 2
    ..transitionMs = 200;

  // shadow-md → hover:shadow + translate-y-1 → active:shadow-none +
  // translate-y-2 translate-x-1.
  void pressMotion(ButtonConfig b, {ColorRef? shadowColor}) {
    b.states[ButtonStateKey.normal]!
      ..shadow = ShadowToken.hardMd
      ..shadowColor = shadowColor;
    b.states[ButtonStateKey.hovered]!
      ..shadow = ShadowToken.hard
      ..offsetY = 4;
    b.states[ButtonStateKey.pressed]!
      ..shadow = ShadowToken.none
      ..offsetX = 4
      ..offsetY = 8;
  }

  // disabled:opacity-60
  void disabled(
    ButtonConfig b,
    SchemeRole fill,
    SchemeRole fg, {
    bool transparentFill = false,
  }) {
    b.states[ButtonStateKey.disabled]!
      ..fill = transparentFill ? null : RoleColor(fill, alpha: 0.6)
      ..foreground = RoleColor(fg, alpha: 0.6)
      ..border = const CustomColor(Color(0x99000000))
      ..shadow = ShadowToken.hardMd
      ..shadowColor = const RoleColor(SchemeRole.outline, alpha: 0.6);
  }

  // default → FilledButton
  final filled = c.buttons[ButtonKind.filled]!;
  geometry(filled);
  filled.states[ButtonStateKey.normal]!
    ..fill = t('primary')
    ..foreground = t('primary-foreground')
    ..border = black;
  filled.states[ButtonStateKey.hovered]!.fill = t('primary-hover');
  pressMotion(filled);
  disabled(filled, SchemeRole.primary, SchemeRole.onPrimary);

  // secondary → ElevatedButton (shadow in the primary color)
  final secondary = c.buttons[ButtonKind.elevated]!;
  geometry(secondary);
  secondary.states[ButtonStateKey.normal]!
    ..fill = t('secondary')
    ..foreground = t('secondary-foreground')
    ..border = black;
  pressMotion(secondary, shadowColor: t('primary'));
  disabled(secondary, SchemeRole.secondary, SchemeRole.onSecondary);

  // outline → OutlinedButton (border = currentColor)
  final outline = c.buttons[ButtonKind.outlined]!;
  geometry(outline);
  outline.states[ButtonStateKey.normal]!
    ..foreground = t('foreground')
    ..border = t('foreground');
  pressMotion(outline);
  disabled(
    outline,
    SchemeRole.surface,
    SchemeRole.onSurface,
    transparentFill: true,
  );

  // danger: like the default, on destructive.
  final danger = c.buttons[ButtonKind.danger]!;
  geometry(danger);
  danger.states[ButtonStateKey.normal]!
    ..fill = t('destructive')
    ..foreground = t('destructive-foreground')
    ..border = black;
  pressMotion(danger);
  disabled(danger, SchemeRole.error, SchemeRole.onError);

  // link → TextButton (per-state colors only)
  final link = c.buttons[ButtonKind.text]!
    ..radius = r
    ..paddingH = 4
    ..paddingV = 8
    ..minHeight = 40
    ..minWidth = 0
    ..iconSize = 20
    ..fontSize = 16
    ..lineHeight = 24
    ..fontWeight = FontWeight.w400
    ..letterSpacing = 0
    ..headFont = true
    ..hoverUnderline = true;
  link.states[ButtonStateKey.normal]!.foreground = t('foreground');
  link.states[ButtonStateKey.disabled]!.foreground = const RoleColor(
    SchemeRole.onSurface,
    alpha: 0.6,
  );

  // ghost: bg-transparent hover:bg-accent
  final ghost = c.buttons[ButtonKind.ghost]!;
  geometry(ghost);
  ghost
    ..borderWidth = 0
    ..paddingH = 18
    ..paddingV = 8;
  ghost.states[ButtonStateKey.normal]!
    ..foreground = t('foreground')
    ..shadow = ShadowToken.none;
  ghost.states[ButtonStateKey.hovered]!.fill = t('accent');
  ghost.states[ButtonStateKey.pressed]!.fill = t('accent');
  ghost.states[ButtonStateKey.disabled]!.foreground = const RoleColor(
    SchemeRole.onSurface,
    alpha: 0.6,
  );

  // Theme icon button: no border (also applies inside fields and the AppBar).
  final icon = c.buttons[ButtonKind.icon]!
    ..radius = r
    ..minHeight = 40
    ..minWidth = 40
    ..paddingH = 8
    ..paddingV = 8
    ..iconSize = 24
    ..transitionMs = 200;
  icon.states[ButtonStateKey.normal]!
    ..foreground = t('foreground')
    ..shadow = ShadowToken.none;
  icon.states[ButtonStateKey.hovered]!.fill = t('accent');
  icon.states[ButtonStateKey.pressed]!.fill = t('accent');

  // IconButton.tsx default: bg-primary border-2 border-black.
  final iconSecondary = c.buttons[ButtonKind.iconSecondary]!
    ..radius = r
    ..borderWidth = 2
    ..minHeight = 40
    ..minWidth = 40
    ..paddingH = 6
    ..paddingV = 8
    ..iconSize = 20
    ..focusRing = t('primary')
    ..transitionMs = 200;
  iconSecondary.states[ButtonStateKey.normal]!
    ..fill = t('primary')
    ..foreground = const CustomColor(Color(0xFF000000))
    ..border = black;
  iconSecondary.states[ButtonStateKey.hovered]!.fill = t('primary-hover');
  pressMotion(iconSecondary);

  // size sm: px-3 py-1 text-sm (+ border).
  c.buttonSizes[ButtonSizeKey.small]!
    ..minHeight = 32
    ..paddingH = 12
    ..paddingV = 6
    ..iconSize = 16
    ..fontSize = 14
    ..lineHeight = 20
    ..radius = r;
}

/// Input.tsx: px-4 py-2 rounded bg-input border-2 shadow-md,
/// focus:shadow-xs; aria-invalid: border/text/shadow destructive.
void _textField(TextFieldConfig f, ColorRef Function(String) t, double r) {
  f
    ..radius = r
    ..dense = true
    ..textInset =
        18 // 16 + 2 border
    ..paddingEnd = 18
    ..paddingV =
        10 // 8 + 2 border
    ..iconBox = 40
    ..inputFontSize = 16
    ..inputLineHeight = 24
    ..inputWeight = FontWeight.w400
    ..inputLetterSpacing = 0
    ..inputColor = t('foreground')
    ..cursor = t('foreground')
    ..helperFontSize = 14
    ..helperWeight = FontWeight.w400
    ..helperLetterSpacing = 0
    ..helperColor = t('muted-foreground')
    ..errorColor = t('destructive');

  // bg-input is white in dark too (light text on white): use card.
  f.states[FieldStateKey.normal]!
    ..fill = t('card')
    ..border = t('foreground')
    ..borderWidth = 2
    ..shadow = ShadowToken.hardMd
    ..placeholder = t('muted-foreground')
    ..icon = t('foreground');
  f.states[FieldStateKey.focused]!
    ..border = t('foreground')
    ..borderWidth = 2
    ..shadow = ShadowToken.hardXs;
  f.states[FieldStateKey.error]!
    ..border = t('destructive')
    ..shadow = ShadowToken.hardXs
    ..shadowColor = t('destructive')
    ..placeholder = t('destructive');
  f.states[FieldStateKey.disabled]!
    ..fill = const RoleColor(SchemeRole.surfaceContainerLow, alpha: 0.5)
    ..border = const RoleColor(SchemeRole.outlineVariant, alpha: 0.5)
    ..shadow = ShadowToken.none;
}

void _surfaces(
  ThemeConfig c,
  ColorRef Function(String) t,
  ColorRef black,
  double r,
) {
  SurfaceConfig s(SurfaceKind k) => c.surfaces[k]!;
  final border = t('foreground');

  // Card.tsx: border-2 rounded shadow-md bg-card.
  s(SurfaceKind.card)
    ..background = t('card')
    ..borderColor = border
    ..borderWidth = 2
    ..radius = r
    ..elevation = 0
    ..shadow = ShadowToken.hardMd;

  // Dialog.tsx: border-2 bg-background shadow-lg.
  s(SurfaceKind.dialog)
    ..background = t('background')
    ..borderColor = border
    ..borderWidth = 2
    ..radius = r
    ..elevation = 0
    ..shadow = ShadowToken.hardLg
    ..titleStyle = TextRole.titleLarge
    ..bodyStyle = TextRole.bodyMedium;

  s(SurfaceKind.bottomSheet)
    ..background = t('background')
    ..radius = r
    ..elevation = 0
    ..accent = border;

  // TopNav: border-b-2.
  s(SurfaceKind.appBar)
    ..background = t('background')
    ..foreground = t('foreground')
    ..borderColor = border
    ..borderWidth = 2
    ..elevation = 0
    ..titleStyle = TextRole.titleLarge;

  // Indicator like the active tab: bg-primary with border.
  for (final k in [SurfaceKind.navigationBar, SurfaceKind.navigationRail]) {
    s(k)
      ..background = t('background')
      ..accent = t('primary')
      ..foreground = t('primary-foreground')
      ..borderColor = border
      ..borderWidth = 2
      ..innerRadius = r
      ..titleStyle = TextRole.labelMedium;
  }
  s(SurfaceKind.navigationBar).elevation = 0;

  s(SurfaceKind.listTile)
    ..titleStyle = TextRole.bodyMedium
    ..bodyStyle = TextRole.bodySmall
    ..foreground = t('foreground')
    ..accent = t('accent')
    ..radius = r;

  s(SurfaceKind.divider)
    ..borderColor = border
    ..borderWidth = 2;

  s(SurfaceKind.fab)
    ..background = t('primary')
    ..foreground = t('primary-foreground')
    ..borderColor = black
    ..borderWidth = 2
    ..radius = r
    ..elevation = 0
    ..shadow = ShadowToken.hardMd
    ..titleStyle = TextRole.labelLarge;

  // Tooltip.tsx: border-2 bg-background px-3 py-1.5 text-xs.
  s(SurfaceKind.tooltip)
    ..background = t('background')
    ..foreground = t('foreground')
    ..borderColor = border
    ..borderWidth = 2
    ..radius = r
    ..bodyStyle = TextRole.labelSmall
    ..paddingH = 12
    ..paddingV = 6;

  // Tab.tsx: attivo border-2 bg-primary text-primary-foreground.
  s(SurfaceKind.tabBar)
    ..background = t('primary')
    ..accent = border
    ..selectedForeground = t('primary-foreground')
    ..foreground = t('foreground')
    ..borderWidth = 2
    ..innerRadius = r
    ..titleStyle = TextRole.titleSmall
    ..bodyStyle = TextRole.bodyMedium
    ..paddingH = 16;

  // Badges like labels: 2px border, selection bg-primary.
  s(SurfaceKind.chip)
    ..background = t('card')
    ..foreground = t('foreground')
    ..accent = t('primary')
    ..selectedForeground = t('primary-foreground')
    ..borderColor = border
    ..borderWidth = 2
    ..radius = r
    ..bodyStyle = TextRole.labelMedium
    ..paddingH = 8
    ..paddingV = 4;

  s(SurfaceKind.badge)
    ..background = t('primary')
    ..foreground = t('primary-foreground')
    ..bodyStyle = TextRole.labelSmall
    ..height = 20
    ..paddingH = 6;

  // Menu.tsx: bg-popover border-2 shadow-md; voci px-2 py-1.5 text-sm,
  // hover:bg-primary.
  s(SurfaceKind.menu)
    ..background = t('popover')
    ..borderColor = border
    ..borderWidth = 2
    ..radius = r
    ..elevation = 0
    ..shadow = ShadowToken.hardMd
    ..paddingH = 4
    ..foreground = t('foreground')
    ..accent = t('primary')
    ..innerRadius = r
    ..paddingV = 8
    ..bodyStyle = TextRole.bodySmall;

  // Sonner.tsx: bg-background border.
  s(SurfaceKind.snackBar)
    ..background = t('background')
    ..foreground = t('foreground')
    ..accent = t('foreground')
    ..borderColor = border
    ..borderWidth = 2
    ..radius = r
    ..elevation = 0
    ..bodyStyle = TextRole.bodyMedium;

  // Checkbox.tsx: border-2 rounded, selezionato bg-primary.
  s(SurfaceKind.checkbox)
    ..accent = t('primary')
    ..selectedForeground = t('primary-foreground')
    ..background = t('card')
    ..borderColor = border
    ..borderWidth = 2
    ..radius = r;

  // Radio.tsx: border-2, selected bg-primary with a bg-border dot.
  s(SurfaceKind.radio)
    ..accent = border
    ..borderColor = border
    ..background = t('card')
    ..selectedForeground = t('primary');

  // Switch.tsx: track border-2 border-foreground, on bg-primary;
  // thumb bg-primary when off, bg-background when on.
  s(SurfaceKind.switchControl)
    ..accent = t('primary')
    ..background = t('background')
    ..foreground = t('primary')
    ..selectedForeground = t('background')
    ..borderColor = border
    ..borderWidth = 2
    // h-6 w-11 (border-box), thumb h-4 w-4 border-2, sharp corners.
    ..width = 44
    ..height = 24
    ..thumbSize = 16
    ..radius = r
    ..innerRadius = r;

  // Slider.tsx: traccia h-3 border-2 bg-background, range bg-primary;
  // cursore 18px border-2 bg-background shadow-sm.
  s(SurfaceKind.slider)
    ..accent = t('primary')
    ..background = t('background')
    ..height = 12
    ..foreground = t('background')
    ..borderColor = border
    ..borderWidth = 2
    ..radius = 9
    ..innerRadius = r
    ..shadow = ShadowToken.hardSm;
}
