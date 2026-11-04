import 'package:flutter/material.dart';

import 'boardui_tokens.dart';
import 'color_choice.dart';
import 'color_ref.dart';
import 'color_sets.dart';
import 'material_colors.dart';
import 'presets_neobrutalism.dart';
import 'presets_shadcn.dart';
import 'shadcn_tokens.dart';
import 'shadow_token.dart';
import 'surface_config.dart';
import 'text_field_config.dart';
import 'theme_config.dart';
import 'typography_config.dart';

/// Design system family: decides how colors are generated.
enum PresetStyle { material, boardUI, neobrutalism, shadcn }

/// Starting point for the theme: resets the configuration and applies a style.
class ThemePreset {
  const ThemePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.apply,
    this.source,
    this.style = PresetStyle.material,
    this.neoPalette,
    this.neoRadius = 0,
    this.shadcnStyle = 'new-york',
  });

  /// Stable identifier, saved in project files (the [name] is
  /// interface text and may change).
  final String id;
  final String name;
  final String description;
  final String? source;
  final void Function(ThemeConfig) apply;
  final PresetStyle style;

  /// Neobrutalism only: official palette and radius (0 or 8, `.with-radius`).
  final String? neoPalette;
  final double neoRadius;

  /// shadcn/ui only: the variant (new-york or one of the 8 styles).
  final String shadcnStyle;

  /// Applies the style with the chosen colors (empty = official colors).
  void applyWithColors(ThemeConfig c, ColorChoice colors) {
    if (colors.isEmpty) {
      apply(c);
      return;
    }
    switch (style) {
      case PresetStyle.material:
        apply(c);
        final primary = colors.primary ?? c.seedColor;
        c.seedColor = primary;
        if (colors.hasMaterialKeys) {
          c.schemeOverrides.addAll(
            materialKeyColorRoles(
              primary: primary,
              variant: c.variant,
              secondary: colors.secondary,
              tertiary: colors.tertiary,
              neutral: colors.neutral,
              neutralVariant: colors.neutralVariant,
              error: colors.error,
            ),
          );
        }
      case PresetStyle.boardUI:
        applyBoardUI(
          c,
          accent: colors.primary,
          neutralFamily: colors.neutralFamily,
          neutralCustom: colors.neutralCustom,
        );
      case PresetStyle.shadcn:
        applyShadcnWithColors(c, colors, style: shadcnStyle);
      case PresetStyle.neobrutalism:
        final primary = colors.primary;
        applyNeobrutalism(
          c,
          primary == null ? neoPalette! : registerNeoPalette(primary),
          radius: neoRadius,
        );
    }
  }

  static final all = <ThemePreset>[
    material3,
    boardUI,
    shadcn,
    for (final e in shadcnStyleNames.entries)
      if (e.key != 'new-york') shadcnVariant(e.key),
    for (final e in neoPaletteNames.entries)
      ThemePreset(
        id: 'neobrutalism.${e.key}',
        name: 'Neobrutalism · ${e.value}',
        description: 'RetroUI: 2px borders, hard shadows, Archivo Black.',
        source: 'github.com/neobrutalism/neobrutalism (MIT)',
        apply: (c) => applyNeobrutalism(c, e.key),
        style: PresetStyle.neobrutalism,
        neoPalette: e.key,
      ),
    ThemePreset(
      id: 'neobrutalism.yellow-rounded',
      name: 'Neobrutalism · Rounded yellow',
      description: 'Like Yellow, with 8px corners (.with-radius).',
      source: 'github.com/neobrutalism/neobrutalism (MIT)',
      apply: (c) => applyNeobrutalism(c, 'yellow', radius: 8),
      style: PresetStyle.neobrutalism,
      neoPalette: 'yellow',
      neoRadius: 8,
    ),
  ];

  /// Neobrutalism preset by palette (used in tests).
  static ThemePreset neobrutalism(String palette) =>
      all.firstWhere((p) => p.id == 'neobrutalism.$palette');

  static final material3 = ThemePreset(
    id: 'material3',
    name: 'Material 3',
    description: "Flutter's defaults, no overrides.",
    apply: (_) {},
  );

  static final shadcn = ThemePreset(
    id: 'shadcn',
    name: 'shadcn/ui',
    description: 'new-york-v4: neutrals, thin borders, 3px focus ring, Geist.',
    source: 'github.com/shadcn-ui/ui (MIT)',
    apply: (c) => applyShadcn(c),
    style: PresetStyle.shadcn,
  );

  /// shadcn/ui variant ('new-york' = [shadcn]).
  static ThemePreset shadcnVariant(String style) {
    if (style == 'new-york') return shadcn;
    return _shadcnVariants.putIfAbsent(
      style,
      () => ThemePreset(
        id: 'shadcn.$style',
        name: 'shadcn/ui · ${shadcnStyleNames[style]!.split(' · ').first}',
        description: shadcnStyleNames[style]!.split(' · ').last,
        source: 'github.com/shadcn-ui/ui (MIT)',
        apply: (c) => applyShadcn(c, style: style),
        style: PresetStyle.shadcn,
        shadcnStyle: style,
      ),
    );
  }

  static final _shadcnVariants = <String, ThemePreset>{};

  static final boardUI = ThemePreset(
    id: 'boardui',
    name: 'BoardUI',
    description:
        'Replica of the BoardUI buttons: gradients, states, shadows, '
        'Inter.',
    source: 'github.com/BoardUI/boardui (MIT)',
    apply: _applyBoardUI,
    style: PresetStyle.boardUI,
  );

  void applyTo(ThemeConfig c) {
    c.reset();
    apply(c);
  }
}

// Scales used while applying BoardUI: official (accent = blue, neutral)
// or generated from the chosen colors. Only valid during applyBoardUI.
Map<int, Color> _accent = boardPrimitives['accent']!;
Map<int, Color> _neutral = boardPrimitives['neutral']!;
String? _tokenSet;

Color _b(int shade) => _accent[shade]!; // accent-*
Color _n(int shade) => _neutral[shade]!;

/// BoardUI with a different accent and/or neutrals (null = official): the
/// 50–950 scales are generated and the 186 tokens recomputed.
void applyBoardUI(
  ThemeConfig c, {
  Color? accent,
  String? neutralFamily,
  Color? neutralCustom,
}) {
  final prev = (_accent, _neutral, _tokenSet);
  try {
    if (accent != null || neutralFamily != null || neutralCustom != null) {
      _accent = accent == null
          ? boardPrimitives['accent']!
          : accentScaleFor(accent);
      _neutral = neutralScaleFor(family: neutralFamily, custom: neutralCustom);
      _tokenSet = registerBoardSet(accent: _accent, neutral: _neutral);
    }
    _applyBoardUI(c);
  } finally {
    _accent = prev.$1;
    _neutral = prev.$2;
    _tokenSet = prev.$3;
  }
}

ColorRef _fixed(Color c) => CustomColor(c);
ColorRef _ld(Color light, Color dark) => AdaptiveColor(light, dark);

/// BoardUI semantic token (light/dark values generated from theme.css).
ColorRef _t(String name) => TokenColor(name, _tokenSet);

const _transparent = CustomColor(Color(0x00000000));

/// Values from BoardUI `styles/theme.css` and `components/base/buttons/button.tsx`.
///
/// Mapping of BoardUI variants → Material buttons:
///   primary   → FilledButton
///   secondary → OutlinedButton and ElevatedButton
///   ghost     → TextButton
/// "medium" size: h-9 (36), p-2 + label px-1 (12 × 8), rounded-2lg (10),
/// icon 20, text-body-medium (Inter 14/20, 500, tracking 0).
void _applyBoardUI(ThemeConfig c) {
  c
    ..seedColor = _b(600)
    ..variant = DynamicSchemeVariant.fidelity
    ..fontFamily = 'Inter'
    ..density = DensityOption.standard
    ..shrinkWrapTapTargets = true;

  // Full ColorScheme on the BoardUI tokens, by semantic role: so even
  // components not styled yet (checkbox, switch, chip, dialog, menu…)
  // get BoardUI colors. BoardUI has no secondary/tertiary: grays.
  c.schemeOverrides.addAll({
    SchemeRole.primary: _fixed(_b(600)), // CTA (gradiente accent 500→600)
    SchemeRole.onPrimary: _t('text-white'),
    SchemeRole.primaryContainer: _t('button-ghost-background'),
    SchemeRole.onPrimaryContainer: _t('button-ghost-foreground'),
    SchemeRole.secondary: _t('text-secondary'),
    SchemeRole.onSecondary: _t('text-white'),
    SchemeRole.secondaryContainer: _t('background-tertiary-default'),
    SchemeRole.onSecondaryContainer: _t('text-primary'),
    SchemeRole.tertiary: _t('foreground-icon-tertiary'),
    SchemeRole.onTertiary: _t('text-white'),
    SchemeRole.tertiaryContainer: _t('background-quaternary-default'),
    SchemeRole.onTertiaryContainer: _t('text-primary'),
    SchemeRole.error: _t('text-error-primary'),
    SchemeRole.onError: _t('text-white'),
    SchemeRole.errorContainer: _t('background-tertiary-error'),
    SchemeRole.onErrorContainer: _t('text-destructive'),
    // As in the BoardUI app shell: page and modal on background-full,
    // cards on background-secondary, menus/popovers on background-primary.
    SchemeRole.surface: _t('background-full'),
    SchemeRole.onSurface: _t('text-primary'),
    SchemeRole.onSurfaceVariant: _t('text-secondary'),
    SchemeRole.surfaceContainerLowest: _t('background-full'),
    SchemeRole.surfaceContainerLow: _t('background-secondary-default'),
    SchemeRole.surfaceContainer: _t('background-primary-default'),
    SchemeRole.surfaceContainerHigh: _t('background-full'),
    SchemeRole.surfaceContainerHighest: _t('background-tertiary-default'),
    SchemeRole.outline: _t('border-checkbox-default'),
    SchemeRole.outlineVariant: _t('border-button-default'),
    SchemeRole.inverseSurface: _t('text-primary'),
    SchemeRole.onInverseSurface: _t('background-primary-default'),
    SchemeRole.inversePrimary: _ld(_b(300), _b(600)),
  });

  void medium(ButtonConfig b) => b
    ..radius = 10
    ..paddingH = 12
    ..paddingV = 8
    ..minHeight = 36
    ..minWidth = 0
    ..iconSize = 20
    ..fontSize = 14
    ..fontWeight = FontWeight.w500
    ..letterSpacing = 0
    ..lineHeight =
        20 // text-body-medium 14/20
    // button-press-motion + focus-visible:ring-2 ring-offset-2 ring-accent-500
    ..pressScale = 0.98
    ..focusRing = _t('border-focus-ring')
    ..focusRingWidth = 2
    ..focusRingOffset = 2
    ..focusRingOffsetColor =
        _fixed(const Color(0xFFFFFFFF)) // ring-offset #fff
    ..transitionMs = 150; // --button-transition-ms

  // primary: bg-button-primary (gradienti 180° sulle primitive accent)
  final primary = c.buttons[ButtonKind.filled]!;
  medium(primary);
  primary.states[ButtonStateKey.normal]!
    ..fill = _fixed(_b(500))
    ..fillEnd = _fixed(_b(600))
    ..foreground = _t('text-white')
    ..shadow = ShadowToken.xs;
  primary.states[ButtonStateKey.hovered]!
    ..fill = _fixed(_b(400))
    ..fillEnd = _fixed(_b(500));
  primary.states[ButtonStateKey.pressed]!
    ..fill = _fixed(_b(600))
    ..fillEnd = _fixed(_b(700));
  primary.states[ButtonStateKey.disabled]!
    ..fill =
        _ld(_n(200), _n(700)) // --gradient-button-primary-disabled
    ..fillEnd = _ld(_n(300), _n(800))
    ..foreground = _t('button-primary-disabled-foreground')
    ..shadow = ShadowToken.none;

  // secondary: background-primary-* / border-button-* / text-primary
  void secondary(ButtonConfig b) {
    medium(b);
    b.borderWidth = 1;
    b.states[ButtonStateKey.normal]!
      ..fill = _t('background-primary-default')
      ..foreground = _t('text-primary')
      ..border = _t('border-button-default')
      ..shadow = ShadowToken.xs;
    b.states[ButtonStateKey.hovered]!
      ..fill = _t('background-primary-hover')
      ..border = _t('border-button-hover');
    b.states[ButtonStateKey.pressed]!
      ..fill = _t('background-primary-active')
      ..border = _t('border-button-active');
    b.states[ButtonStateKey.disabled]!
      ..fill = _t('background-primary-disabled')
      ..foreground = _t('text-tertiary')
      ..border = _t('border-button-default')
      ..shadow = ShadowToken.none;
  }

  secondary(c.buttons[ButtonKind.outlined]!);
  secondary(c.buttons[ButtonKind.elevated]!);

  // TextButton = BoardUI link-button (primary): no background, text
  // accent-600, underlined on hover, accent-800 when pressed. Without a
  // background,
  // Flutter widgets that use TextButton internally (menu items,
  // SnackBar action, copy/paste toolbar) stay clean.
  final link = c.buttons[ButtonKind.text]!
    ..radius =
        4 // rounded-sm
    ..paddingH = 4
    ..paddingV = 8
    ..minHeight = 36
    ..minWidth = 0
    ..iconSize = 20
    ..fontSize = 14
    ..fontWeight = FontWeight.w500
    ..letterSpacing = 0
    ..lineHeight = 20
    ..hoverUnderline = true;
  link.states[ButtonStateKey.normal]!.foreground = _fixed(_b(600));
  link.states[ButtonStateKey.pressed]!.foreground = _fixed(_b(800));
  link.states[ButtonStateKey.disabled]!.foreground = _t('text-tertiary');

  // ghost: button-ghost-* (no shadow), as an extra style.
  final ghost = c.buttons[ButtonKind.ghost]!;
  medium(ghost);
  ghost.states[ButtonStateKey.normal]!
    ..fill = _t('button-ghost-background')
    ..foreground = _t('button-ghost-foreground')
    ..shadow = ShadowToken.none;
  ghost.states[ButtonStateKey.hovered]!.fill = _t('button-ghost-hover');
  ghost.states[ButtonStateKey.pressed]!.fill = _t('button-ghost-active');
  ghost.states[ButtonStateKey.disabled]!
    ..fill = _t('button-ghost-disabled')
    ..foreground = _t('button-ghost-disabled-foreground');

  // danger: bg-button-danger (gradienti 180° red) text-text-white shadow-xs
  Color red(int shade) => tailwindPalette['red']![shade]!;
  final danger = c.buttons[ButtonKind.danger]!;
  medium(danger);
  danger.states[ButtonStateKey.normal]!
    ..fill = _fixed(red(500))
    ..fillEnd = _fixed(red(600))
    ..foreground = _t('text-white')
    ..shadow = ShadowToken.xs;
  danger.states[ButtonStateKey.hovered]!
    ..fill = _fixed(red(400))
    ..fillEnd = _fixed(red(500));
  danger.states[ButtonStateKey.pressed]!
    ..fill = _fixed(red(600))
    ..fillEnd = _fixed(red(700));
  danger.states[ButtonStateKey.disabled]!
    ..fill =
        _ld(red(100), red(900)) // --gradient-button-danger-disabled
    ..fillEnd = _ld(red(200), red(950))
    ..foreground = _t('foreground-disabled-danger')
    ..shadow = ShadowToken.none;

  // Theme icon button: no border, because IconButtonTheme also applies to
  // icons inside fields, the back button, the date picker…
  void iconGeometry(ButtonConfig b) => b
    ..radius =
        10 // rounded-2lg
    ..minHeight =
        36 // size-9
    ..minWidth = 36
    ..paddingH = 8
    ..paddingV = 8
    ..iconSize =
        20 // size-5
    ..pressScale = 0.98
    ..focusRing = _t('border-focus-ring')
    ..focusRingWidth = 2
    ..focusRingOffset = 2
    ..focusRingOffsetColor = _fixed(const Color(0xFFFFFFFF))
    ..transitionMs = 150;
  final icon = c.buttons[ButtonKind.icon]!;
  iconGeometry(icon);
  icon.states[ButtonStateKey.normal]!
    ..foreground = _t('foreground-icon-secondary')
    ..shadow = ShadowToken.none;
  icon.states[ButtonStateKey.hovered]!
    ..fill = _t('background-primary-hover')
    ..foreground = _t('foreground-icon-primary');
  icon.states[ButtonStateKey.pressed]!.fill = _t('background-primary-active');
  icon.states[ButtonStateKey.disabled]!.foreground = _t(
    'foreground-icon-disabled',
  );

  // BoardUI icon-button (secondary): white, border, shadow-xs.
  // size-9 is border-box: the 1px border must come off the horizontal padding.
  final iconSecondary = c.buttons[ButtonKind.iconSecondary]!;
  iconGeometry(iconSecondary);
  iconSecondary
    ..paddingH = 7
    ..borderWidth = 1;
  iconSecondary.states[ButtonStateKey.normal]!
    ..fill = _t('background-primary-default')
    ..foreground = _t('foreground-icon-primary')
    ..border = _t('border-button-default')
    ..shadow = ShadowToken.xs;
  iconSecondary.states[ButtonStateKey.hovered]!
    ..fill = _t('background-primary-hover')
    ..border = _t('border-button-hover');
  iconSecondary.states[ButtonStateKey.pressed]!
    ..fill = _t('background-primary-active')
    ..border = _t('border-button-active');
  iconSecondary.states[ButtonStateKey.disabled]!
    ..fill = _t('background-primary-disabled')
    ..foreground = _t('icon-button-disabled-foreground')
    ..border = _t('border-button-default')
    ..shadow = ShadowToken.none;

  // button.tsx sizes: small h-8 rounded-lg px-2 py-1.5 (+ label px-0.5),
  // icon 18; xs h-6 rounded-sm px-2 (+ label px-0.5), icon 14,
  // text-caption-1-semibold.
  c.buttonSizes[ButtonSizeKey.small]!
    ..minHeight = 32
    ..radius = 8
    ..paddingH = 10
    ..paddingV = 6
    ..iconSize = 18;
  c.buttonSizes[ButtonSizeKey.xs]!
    ..minHeight = 24
    ..radius = 4
    ..paddingH = 10
    ..paddingV = 4
    ..iconSize = 14
    ..fontSize = 12
    ..fontWeight = FontWeight.w600
    ..letterSpacing = 0.15
    ..lineHeight = 16; // text-caption-1-semibold 12/16

  _applyBoardUIInput(c.textField);
  _applyBoardUITypography(c.typography);
  _applyBoardUISurfaces(c);
}

/// styles/typography.css scale mapped onto the 15 Material styles, keeping
/// the hierarchy. BoardUI uses medium for headings and regular for
/// body text (count of text-* classes in the components).
void _applyBoardUITypography(TypographyConfig t) {
  void set(
    TextRole r,
    String source,
    double size,
    double lh,
    FontWeight w, [
    double ls = 0,
  ]) => t.styles[r] = TypeSpec(
    size: size,
    lineHeight: lh,
    weight: w,
    letterSpacing: ls,
    source: source,
  );
  const m = FontWeight.w500;
  const r = FontWeight.w400;
  set(TextRole.displayLarge, 'display-1-medium', 56, 72, m);
  set(TextRole.displayMedium, 'display-2-medium', 48, 64, m);
  set(TextRole.displaySmall, 'display-3-medium', 40, 54, m);
  set(TextRole.headlineLarge, 'display-4-medium', 32, 44, m);
  set(TextRole.headlineMedium, 'title-1-medium', 24, 34, m);
  set(TextRole.headlineSmall, 'title-2-medium', 20, 26, m);
  set(TextRole.titleLarge, 'title-2-medium', 20, 26, m); // page title
  set(TextRole.titleMedium, 'headline-medium', 16, 22, m);
  set(TextRole.titleSmall, 'body-medium', 14, 20, m);
  set(TextRole.bodyLarge, 'headline-regular', 16, 22, r);
  set(TextRole.bodyMedium, 'body-regular', 14, 20, r);
  set(TextRole.bodySmall, 'body-2-regular', 13, 18, r);
  set(TextRole.labelLarge, 'body-medium', 14, 20, m);
  set(TextRole.labelMedium, 'caption-1-medium', 12, 16, m, 0.15);
  set(TextRole.labelSmall, 'caption-2-medium', 11, 15, m, 0.2);
}

/// Containers from BoardUI's application blocks (app-shell, stat-cards,
/// settings-modal, dashboard-sidebar, notification, settings-rows).
void _applyBoardUISurfaces(ThemeConfig c) {
  SurfaceConfig s(SurfaceKind k) => c.surfaces[k]!;

  // stat-cards: rounded-2xl bg-background-secondary-default, piatte.
  s(SurfaceKind.card)
    ..background = _t('background-secondary-default')
    ..radius = 16
    ..borderWidth = 0
    ..elevation = 0;

  // settings-modal: rounded-3xl bg-background-full shadow-xs.
  s(SurfaceKind.dialog)
    ..background = _t('background-full')
    ..radius = 24
    ..borderWidth = 0
    ..elevation = 1
    ..titleStyle = TextRole.titleLarge
    ..bodyStyle = TextRole.bodyMedium;

  s(SurfaceKind.bottomSheet)
    ..background = _t('background-full')
    ..radius = 24
    ..elevation = 1
    ..accent = _t('background-quaternary-default');

  // app-shell: header su background-full, titolo text-title-2-medium.
  s(SurfaceKind.appBar)
    ..background = _t('background-full')
    ..foreground = _t('text-primary')
    ..elevation = 0
    ..titleStyle = TextRole.titleLarge;

  // dashboard-sidebar: bg-background-secondary-default, selected item
  // with the accent gradient (500→600) and white text.
  s(SurfaceKind.navigationBar)
    ..background = _t('background-secondary-default')
    ..accent = _fixed(_b(600))
    ..foreground = _t('text-white')
    ..elevation = 0
    ..titleStyle = TextRole.labelMedium;
  s(SurfaceKind.navigationRail)
    ..background = _t('background-secondary-default')
    ..accent = _fixed(_b(600))
    ..foreground = _t('text-white')
    ..titleStyle = TextRole.labelMedium;

  // settings-rows: body-regular text-primary + body-2-regular text-secondary.
  s(SurfaceKind.listTile)
    ..titleStyle = TextRole.bodyMedium
    ..bodyStyle = TextRole.bodySmall
    ..foreground = _t('foreground-icon-secondary')
    ..accent = _t('background-secondary-hover')
    ..radius = 10;

  s(SurfaceKind.divider)
    ..borderColor = _t('separator-border')
    ..borderWidth = 1;

  // BoardUI has no FAB: same accent as the primary button (the FAB
  // theme doesn't support gradients), radius 16 like the cards.
  s(SurfaceKind.fab)
    ..background = _fixed(_b(600))
    ..foreground = _t('text-white')
    ..radius = 16
    ..elevation = 2
    ..titleStyle = TextRole.labelLarge;

  // tooltip.tsx: rounded-lg border border-button-default
  // bg-background-primary-default text-text-primary shadow-dropdown,
  // px-2.5 py-1.5 text-caption-1-medium.
  s(SurfaceKind.tooltip)
    ..background = _t('background-primary-default')
    ..foreground = _t('text-primary')
    ..borderColor = _t('border-button-default')
    ..borderWidth = 1
    ..radius = 8
    ..shadow = ShadowToken.dropdown
    ..bodyStyle = TextRole.labelMedium
    ..paddingH = 10
    ..paddingV = 6;

  // tabs.tsx: border-b border-separator-border, indicator h-0.5
  // bg-accent-600, selected text-body-medium text-accent-600, the others
  // text-body-regular text-text-primary, px-2.5.
  s(SurfaceKind.tabBar)
    ..accent = _fixed(_b(600))
    ..foreground = _t('text-primary')
    ..borderWidth = 2
    ..borderColor = _t('separator-border')
    ..titleStyle = TextRole.titleSmall
    ..bodyStyle = TextRole.bodyMedium
    ..paddingH = 10;

  // chip.tsx: rounded-md px-1.5 py-1 text-body-medium,
  // bg-background-secondary-default; selection like pill-tab (accent).
  s(SurfaceKind.chip)
    ..background = _t('background-secondary-default')
    ..foreground = _t('text-primary')
    ..accent = _t('pill-tab-blue-selected-background')
    ..selectedForeground = _fixed(_b(500))
    ..borderWidth = 0
    ..radius = 6
    ..bodyStyle = TextRole.titleSmall
    ..paddingH = 6
    ..paddingV = 4;

  // badge.tsx: px-1 py-px text-caption-1-semibold, bg-accent-400 text-white.
  s(SurfaceKind.badge)
    ..background = _fixed(_b(400))
    ..foreground = _t('text-white')
    ..bodyStyle = TextRole.labelMedium
    ..height = 18
    ..paddingH = 4;

  // menu-styles.ts: pannello rounded-2xl border border-button-default
  // bg-background-primary-default p-2.5 shadow-dropdown; voci rounded-2lg
  // p-2 text-body-medium, hover bg-dropdown-item-hover-background.
  s(SurfaceKind.menu)
    ..background = _t('background-primary-default')
    ..borderColor = _t('border-button-default')
    ..borderWidth = 1
    ..radius = 16
    ..elevation = 2
    ..paddingH = 10
    ..foreground = _t('text-primary')
    ..accent = _t('dropdown-item-hover-background')
    ..innerRadius = 10
    ..paddingV = 8
    ..bodyStyle = TextRole.titleSmall;

  // checkbox-glyph.tsx: rounded-sm, selected accent gradient 500→600
  // (the theme only accepts one color: accent-600), empty white with a
  // border-checkbox-default border, white check. Disabled opacity-50.
  s(SurfaceKind.checkbox)
    ..accent = _fixed(_b(600))
    ..selectedForeground = _t('text-white')
    ..background = _t('background-primary-default')
    ..borderColor = _t('border-checkbox-default')
    ..borderWidth = 1
    ..radius = 4;

  // radio.tsx: selected accent, empty white with the checkbox border.
  s(SurfaceKind.radio)
    ..accent = _fixed(_b(600))
    ..borderColor = _t('border-checkbox-default')
    ..background = _t('background-primary-default');

  // switch.tsx: off track background-tertiary (no border), on
  // accent; white thumb (control-indicator-background).
  s(SurfaceKind.switchControl)
    ..accent = _fixed(_b(600))
    ..background = _t('background-tertiary-default')
    ..foreground = _t('control-indicator-background');

  // slider.tsx: track h-1.5 background-tertiary, active accent gradient
  // 500→600, size-5 white thumb with border-button-default and shadow.
  s(SurfaceKind.slider)
    ..accent = _fixed(_b(500))
    ..accentEnd = _fixed(_b(600))
    ..background = _t('background-tertiary-default')
    ..height = 6
    ..foreground = _t('control-indicator-background')
    ..borderColor = _t('border-button-default')
    ..radius = 10
    ..shadow = ShadowToken.sm;

  // notification: rounded-2xl border border-button-default
  // bg-background-primary-default shadow-dropdown.
  s(SurfaceKind.snackBar)
    ..background = _t('background-primary-default')
    ..foreground = _t('text-primary')
    ..accent = _fixed(_b(600))
    ..borderColor = _t('border-button-default')
    ..borderWidth = 1
    ..radius = 16
    ..elevation = 2
    ..bodyStyle = TextRole.bodyMedium;
}

/// Values from BoardUI `components/base/input/input.tsx` (medium size).
///
/// Field: rounded-2lg (10), p-2 + input pl-1 (text at 12px), h 36,
/// bg-background-tertiary, ring-2 ring-inset (transparent → hover → focus),
/// text text-body-regular (Inter 14/20, 400). Error: red background, no
/// ring. Hint: text-caption-1-medium (12/16, 500, tracking 0.15).
void _applyBoardUIInput(TextFieldConfig f) {
  f
    ..radius = 10
    ..dense = true
    ..textInset = 12
    ..paddingEnd = 8
    ..paddingV = 8
    ..iconBox = 32
    ..inputFontSize = 14
    ..inputWeight = FontWeight.w400
    ..inputLineHeight = 20
    ..inputLetterSpacing = 0
    ..inputColor = _t('text-primary')
    ..cursor =
        _t('text-primary') // caret = text color
    ..helperFontSize = 12
    ..helperWeight = FontWeight.w500
    ..helperLetterSpacing = 0.15
    ..helperColor = _t('text-secondary')
    ..errorColor = _t('text-error-primary');

  f.states[FieldStateKey.normal]!
    ..fill = _t('background-tertiary-default')
    ..border = _transparent
    ..borderWidth = 2
    ..placeholder = _t('text-tertiary')
    ..icon = _t('foreground-icon-tertiary');
  f.states[FieldStateKey.hovered]!.border = _t('border-button-hover');
  f.states[FieldStateKey.focused]!
    ..border = _t('border-button-active')
    ..borderWidth = 2
    ..placeholder = _t('text-primary'); // focus:placeholder:text-primary
  f.states[FieldStateKey.disabled]!
    ..fill = _t('input-disabled-background')
    ..border = _transparent
    ..placeholder = _t('input-disabled-text')
    ..icon = _t('input-disabled-foreground');
  f.states[FieldStateKey.error]!
    ..fill = _t('background-tertiary-error')
    ..border =
        _transparent // invalid: nessun ring
    ..placeholder = _t('text-error-placeholder')
    ..icon = _t('foreground-icon-error');
}

/// shadcn/ui with the chosen colors: base color from the neutrals (if it's one
/// of the 7),
/// official accent if the primary is an accent's, otherwise
/// generated from the color.
void applyShadcnWithColors(
  ThemeConfig c,
  ColorChoice colors, {
  String style = 'new-york',
}) {
  final family = colors.neutralFamily;
  final base = family != null && shadcnBaseColors.containsKey(family)
      ? family
      : 'neutral';
  final primary = colors.primary;
  String? accent;
  if (primary != null) {
    for (final e in shadcnAccents.entries) {
      if (e.value['primary']!.light == primary) accent = e.key;
    }
    accent ??= registerShadcnAccent(primary);
  }
  applyShadcn(c, base: base, accent: accent, style: style);
}
