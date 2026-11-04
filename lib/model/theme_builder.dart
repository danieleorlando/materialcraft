import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:materialcraft/materialcraft.dart';

import 'color_ref.dart';
import 'shadow_token.dart';
import 'surface_config.dart';
import 'text_field_config.dart';
import 'theme_config.dart';
import 'typography_config.dart';

// NB: this logic must stay a mirror of `export/dart_exporter.dart`,
// so the preview shows exactly what the exported code produces.

ColorScheme buildColorScheme(ThemeConfig c, Brightness brightness) {
  var scheme = ColorScheme.fromSeed(
    seedColor: c.seedColor,
    brightness: brightness,
    dynamicSchemeVariant: c.variant,
  );
  for (final e in c.schemeOverrides.entries) {
    scheme = e.key.override(scheme, e.value.resolve(scheme));
  }
  return scheme;
}

ThemeData buildTheme(ThemeConfig c, Brightness brightness) {
  final cs = buildColorScheme(c, brightness);
  var base = ThemeData(
    colorScheme: cs,
    textTheme: c.typography.toTextTheme(),
    visualDensity: c.density?.value,
    materialTapTargetSize: c.shrinkWrapTapTargets
        ? MaterialTapTargetSize.shrinkWrap
        : null,
  );
  // In the export it becomes `ThemeData(fontFamily: ...)`; here we use google_fonts
  // to load the font in the web editor without bundling it.
  //
  // google_fonts registers each weight as a separate family (Inter_500, ...),
  // so every style has to be "re-fonted" after changing fontWeight,
  // otherwise the wrong weight would show.
  final font = c.fontFamily;
  TextStyle? withFont(TextStyle? s) =>
      s == null || font == null ? s : GoogleFonts.getFont(font, textStyle: s);
  if (font != null) {
    // Start from the full styles (with the right weights, so google_fonts
    // picks the correct variant) but set inherit: true back as in the
    // default text theme, otherwise AnimatedTheme can't
    // interpolate between a theme with a font and one without.
    base = base.copyWith(
      textTheme: _inheritable(
        GoogleFonts.getTextTheme(font, localizedTextTheme(base)),
      ),
    );
  }
  // Heading font for the styles that need it.
  final head = c.headFontFamily;
  TextStyle? withHead(TextStyle? s) =>
      s == null || head == null ? s : GoogleFonts.getFont(head, textStyle: s);
  if (head != null) {
    final localized = localizedTextTheme(base);
    var t = base.textTheme;
    for (final r in TextRole.values) {
      if (c.typography.styles[r]!.headFont == true) {
        t = r.replaceIn(t, withHead(r.of(localized))?.copyWith(inherit: true));
      }
    }
    base = base.copyWith(textTheme: t);
  }
  final f = c.textField;
  if (f.hasInputStyle) {
    base = base.copyWith(
      textTheme: base.textTheme.copyWith(
        bodyLarge: withFont(
          buildInputTextStyle(f, base.textTheme.bodyLarge, cs),
        ),
      ),
    );
  }
  final tt = localizedTextTheme(base);
  TextStyle? Function(TextStyle?) fontFor(ButtonConfig b) =>
      b.headFont == true && head != null ? withHead : withFont;
  ButtonStyle? style(ButtonKind k) =>
      buildButtonStyle(k, c.buttons[k]!, cs, tt, fontFor(c.buttons[k]!));

  return base.copyWith(
    inputDecorationTheme: buildInputTheme(f, cs, withFont),
    textSelectionTheme: f.cursor == null
        ? null
        : TextSelectionThemeData(cursorColor: f.cursor!.resolve(cs)),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: style(ButtonKind.elevated),
    ),
    filledButtonTheme: FilledButtonThemeData(style: style(ButtonKind.filled)),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: style(ButtonKind.outlined),
    ),
    textButtonTheme: TextButtonThemeData(style: style(ButtonKind.text)),
    iconButtonTheme: IconButtonThemeData(style: style(ButtonKind.icon)),
    floatingActionButtonTheme: _fab(c.surfaces[SurfaceKind.fab]!, cs, tt),
    extensions: [
      AppButtonStyles({
        for (final (kind, size, config) in extraButtonStyles(c))
          (AppButtonKind.values.byName(kind.name), size): buildButtonStyle(
            kind,
            config,
            cs,
            tt,
            fontFor(config),
          )!,
      }),
      ?appSwitchStyle(c.surfaces[SurfaceKind.switchControl]!, cs),
    ],
    cardTheme: _card(c.surfaces[SurfaceKind.card]!, cs),
    dialogTheme: _dialog(c.surfaces[SurfaceKind.dialog]!, cs, tt),
    bottomSheetTheme: _bottomSheet(c.surfaces[SurfaceKind.bottomSheet]!, cs),
    appBarTheme: _appBar(c.surfaces[SurfaceKind.appBar]!, cs, tt),
    navigationBarTheme: _navigationBar(
      c.surfaces[SurfaceKind.navigationBar]!,
      cs,
      tt,
    ),
    navigationRailTheme: _navigationRail(
      c.surfaces[SurfaceKind.navigationRail]!,
      cs,
      tt,
    ),
    listTileTheme: _listTile(c.surfaces[SurfaceKind.listTile]!, cs, tt),
    dividerTheme: _divider(c.surfaces[SurfaceKind.divider]!, cs),
    snackBarTheme: _snackBar(c.surfaces[SurfaceKind.snackBar]!, cs, tt),
    tooltipTheme: _tooltip(c.surfaces[SurfaceKind.tooltip]!, cs, tt),
    checkboxTheme: _checkbox(c.surfaces[SurfaceKind.checkbox]!, cs),
    radioTheme: _radio(c.surfaces[SurfaceKind.radio]!, cs),
    switchTheme: _switch(c.surfaces[SurfaceKind.switchControl]!, cs),
    sliderTheme: _slider(c.surfaces[SurfaceKind.slider]!, cs),
    tabBarTheme: _tabBar(c.surfaces[SurfaceKind.tabBar]!, cs, tt),
    chipTheme: _chip(c.surfaces[SurfaceKind.chip]!, cs, tt),
    badgeTheme: _badge(c.surfaces[SurfaceKind.badge]!, cs, tt),
    menuTheme: _menuTheme(c.surfaces[SurfaceKind.menu]!, cs),
    menuButtonTheme: _menuButtons(c.surfaces[SurfaceKind.menu]!, cs, tt),
    dropdownMenuTheme: _dropdownMenu(c.surfaces[SurfaceKind.menu]!, cs),
    popupMenuTheme: _popupMenu(c.surfaces[SurfaceKind.menu]!, cs, tt),
  );
}

// ---------------------------------------------------------------------------
// Extra button styles (AppButtonStyles)
// ---------------------------------------------------------------------------

/// Effective configuration of an extra style: danger, if it hasn't been
/// configured, uses the scheme's error colors.
ButtonConfig extraButtonConfig(ButtonKind kind, ButtonConfig b) {
  if (kind != ButtonKind.danger || b.normal.fill != null) return b;
  final copy = b.withSize(ButtonSizeSpec());
  copy.states[ButtonStateKey.normal] = StateStyle()
    ..fill = kind.m3Fill
    ..fillEnd = null
    ..foreground = b.normal.foreground ?? kind.m3Foreground
    ..border = b.normal.border
    ..shadow = b.normal.shadow;
  return copy;
}

/// All extra styles, in a stable order (the same as the exporter):
/// - danger and icon secondary in medium size;
/// - every labelled button in the configured small / xs sizes.
List<(ButtonKind, AppButtonSize, ButtonConfig)> extraButtonStyles(
  ThemeConfig c,
) {
  final out = <(ButtonKind, AppButtonSize, ButtonConfig)>[];
  for (final kind in ButtonKind.values) {
    final b = extraButtonConfig(kind, c.buttons[kind]!);
    if (kind.isExtra && !b.isEmpty) out.add((kind, AppButtonSize.medium, b));
    if (kind.isIconOnly) continue;
    for (final size in ButtonSizeKey.values) {
      final spec = c.buttonSizes[size]!;
      if (spec.isEmpty) continue;
      out.add((kind, AppButtonSize.values.byName(size.name), b.withSize(spec)));
    }
  }
  return out;
}

FloatingActionButtonThemeData? _fab(
  SurfaceConfig s,
  ColorScheme cs,
  TextTheme tt,
) => s.isEmpty
    ? null
    : FloatingActionButtonThemeData(
        backgroundColor: s.background?.resolve(cs),
        foregroundColor: s.foreground?.resolve(cs),
        elevation: s.elevation,
        focusElevation: s.elevation,
        hoverElevation: s.elevation == null ? null : s.elevation! + 1,
        highlightElevation: s.elevation,
        shape: _rounded(SurfaceKind.fab, s, cs),
        extendedTextStyle: _style(s.titleStyle, tt),
      );

// ---------------------------------------------------------------------------
// Contenitori (speculare a `_surfaceThemes` dell'exporter)
// ---------------------------------------------------------------------------

/// Container border (BorderSide.none if width is 0 or not set).
BorderSide surfaceSide(SurfaceConfig s, ColorScheme cs) {
  final width = s.borderWidth ?? (s.borderColor != null ? 1.0 : 0.0);
  return width == 0
      ? BorderSide.none
      : BorderSide(
          color: s.borderColor?.resolve(cs) ?? cs.outlineVariant,
          width: width,
        );
}

OutlinedBorder? _rounded(SurfaceKind k, SurfaceConfig s, ColorScheme cs) {
  if (s.radius == null && !s.hasBorder && !s.hasShapeShadow) return null;
  final radius = s.radius ?? k.m3Radius;
  if (s.hasShapeShadow && !s.hasHardShadow) {
    // Soft CSS shadow (e.g. Tailwind's shadow-sm), outside the container.
    return HardShadowBorder(
      radius: radius,
      side: surfaceSide(s, cs),
      shadows: s.shadow!.resolve(cs.brightness),
    );
  }
  if (s.hasHardShadow) {
    final o = s.shadow!.hardOffset!;
    return HardShadowBorder(
      radius: radius,
      side: surfaceSide(s, cs),
      shadowOffset: Offset(o, o),
      shadowSpread: s.shadow!.hardSpread,
      shadowColor: s.shadowColor?.resolve(cs) ?? cs.outline,
    );
  }
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radius),
    side: surfaceSide(s, cs),
  );
}

TextStyle? _style(TextRole? role, TextTheme tt, [Color? color]) {
  if (role == null) return null;
  final style = role.of(tt);
  return color == null ? style : style?.copyWith(color: color);
}

CardThemeData? _card(SurfaceConfig s, ColorScheme cs) => s.isEmpty
    ? null
    : CardThemeData(
        color: s.background?.resolve(cs),
        elevation: s.elevation,
        shape: _rounded(SurfaceKind.card, s, cs),
      );

DialogThemeData? _dialog(SurfaceConfig s, ColorScheme cs, TextTheme tt) =>
    s.isEmpty
    ? null
    : DialogThemeData(
        backgroundColor: s.background?.resolve(cs),
        elevation: s.elevation,
        shape: _rounded(SurfaceKind.dialog, s, cs),
        titleTextStyle: _style(s.titleStyle, tt),
        contentTextStyle: _style(s.bodyStyle, tt, cs.onSurfaceVariant),
      );

BottomSheetThemeData? _bottomSheet(SurfaceConfig s, ColorScheme cs) {
  if (s.isEmpty) return null;
  final bg = s.background?.resolve(cs);
  return BottomSheetThemeData(
    backgroundColor: bg,
    modalBackgroundColor: bg,
    elevation: s.elevation,
    modalElevation: s.elevation,
    shape: s.radius == null
        ? null
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(s.radius!),
            ),
          ),
    dragHandleColor: s.accent?.resolve(cs),
  );
}

AppBarThemeData? _appBar(SurfaceConfig s, ColorScheme cs, TextTheme tt) {
  if (s.isEmpty) return null;
  final fg = s.foreground?.resolve(cs);
  final side = surfaceSide(s, cs);
  return AppBarThemeData(
    backgroundColor: s.background?.resolve(cs),
    foregroundColor: fg,
    elevation: s.elevation,
    scrolledUnderElevation: s.elevation,
    surfaceTintColor: s.background == null ? null : Colors.transparent,
    shape: side == BorderSide.none ? null : Border(bottom: side),
    titleTextStyle: _style(s.titleStyle, tt, fg),
  );
}

NavigationBarThemeData? _navigationBar(
  SurfaceConfig s,
  ColorScheme cs,
  TextTheme tt,
) {
  if (s.isEmpty) return null;
  final fg = s.foreground?.resolve(cs);
  final label = _style(s.titleStyle, tt);
  final labelOn = label?.copyWith(color: cs.onSurface);
  final labelOff = label?.copyWith(color: cs.onSurfaceVariant);
  return NavigationBarThemeData(
    backgroundColor: s.background?.resolve(cs),
    indicatorColor: s.accent?.resolve(cs),
    elevation: s.elevation,
    height: s.height,
    surfaceTintColor: s.background == null ? null : Colors.transparent,
    labelTextStyle: label == null
        ? null
        : WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? labelOn : labelOff,
          ),
    indicatorShape: _indicatorShape(s, cs),
    iconTheme: fg == null
        ? null
        : WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? IconThemeData(color: fg)
                : null,
          ),
  );
}

NavigationRailThemeData? _navigationRail(
  SurfaceConfig s,
  ColorScheme cs,
  TextTheme tt,
) {
  if (s.isEmpty) return null;
  final fg = s.foreground?.resolve(cs);
  final label = _style(s.titleStyle, tt);
  return NavigationRailThemeData(
    backgroundColor: s.background?.resolve(cs),
    indicatorColor: s.accent?.resolve(cs),
    selectedIconTheme: fg == null ? null : IconThemeData(color: fg),
    indicatorShape: _indicatorShape(s, cs),
    selectedLabelTextStyle: label?.copyWith(color: cs.onSurface),
    unselectedLabelTextStyle: label?.copyWith(color: cs.onSurfaceVariant),
  );
}

/// Shape of the NavigationBar / NavigationRail indicator.
ShapeBorder? _indicatorShape(SurfaceConfig s, ColorScheme cs) =>
    s.innerRadius == null && !s.hasBorder
    ? null
    : RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(s.innerRadius ?? 16),
        side: surfaceSide(s, cs),
      );

ListTileThemeData? _listTile(SurfaceConfig s, ColorScheme cs, TextTheme tt) =>
    s.isEmpty
    ? null
    : ListTileThemeData(
        titleTextStyle: _style(s.titleStyle, tt),
        subtitleTextStyle: _style(s.bodyStyle, tt, cs.onSurfaceVariant),
        iconColor: s.foreground?.resolve(cs),
        selectedTileColor: s.accent?.resolve(cs),
        shape: s.radius == null
            ? null
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(s.radius!),
              ),
      );

DividerThemeData? _divider(SurfaceConfig s, ColorScheme cs) => s.isEmpty
    ? null
    : DividerThemeData(
        color: s.borderColor?.resolve(cs),
        thickness: s.borderWidth,
      );

// ---------------------------------------------------------------------------
// Selection controls (checkbox, radio, switch, slider)
// ---------------------------------------------------------------------------

/// Disabled = color at 50% (like BoardUI's `opacity-50`).
Color? controlColor(Color? c, Set<WidgetState> states) =>
    c == null || !states.contains(WidgetState.disabled)
    ? c
    : c.withValues(alpha: c.a * 0.5);

CheckboxThemeData? _checkbox(SurfaceConfig s, ColorScheme cs) {
  if (s.isEmpty) return null;
  final on = s.accent?.resolve(cs);
  final off = s.background?.resolve(cs);
  final check = s.selectedForeground?.resolve(cs);
  final border = s.borderColor?.resolve(cs);
  return CheckboxThemeData(
    fillColor: on == null && off == null
        ? null
        : WidgetStateProperty.resolveWith(
            (st) =>
                controlColor(st.contains(WidgetState.selected) ? on : off, st),
          ),
    checkColor: check == null
        ? null
        : WidgetStateProperty.resolveWith((st) => controlColor(check, st)),
    side: border == null && s.borderWidth == null
        ? null
        : WidgetStateBorderSide.resolveWith(
            (st) => st.contains(WidgetState.selected)
                ? const BorderSide(color: Colors.transparent, width: 0)
                : BorderSide(
                    color: controlColor(border ?? cs.outline, st)!,
                    width: s.borderWidth ?? 1,
                  ),
          ),
    shape: s.radius == null
        ? null
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(s.radius!),
          ),
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
  );
}

RadioThemeData? _radio(SurfaceConfig s, ColorScheme cs) {
  if (s.isEmpty) return null;
  final on = s.accent?.resolve(cs);
  final off = s.borderColor?.resolve(cs);
  final bg = s.background?.resolve(cs);
  final bgOn = s.selectedForeground?.resolve(cs) ?? bg;
  return RadioThemeData(
    fillColor: on == null && off == null
        ? null
        : WidgetStateProperty.resolveWith(
            (st) =>
                controlColor(st.contains(WidgetState.selected) ? on : off, st),
          ),
    backgroundColor: bg == null && bgOn == null
        ? null
        : WidgetStateProperty.resolveWith(
            (st) =>
                controlColor(st.contains(WidgetState.selected) ? bgOn : bg, st),
          ),
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
  );
}

/// Geometry of [AppSwitch], if the switch has its own.
AppSwitchStyle? appSwitchStyle(SurfaceConfig s, ColorScheme cs) {
  if (!s.hasSwitchGeometry) return null;
  return AppSwitchStyle(
    width: s.width ?? 52,
    height: s.height ?? 32,
    thumbSize: s.thumbSize ?? 24,
    trackRadius: s.radius,
    thumbRadius: s.innerRadius,
    thumbBorder: s.borderColor != null,
    thumbShadows:
        s.shadow?.resolveWith(
          cs.brightness,
          s.shadowColor?.resolve(cs) ?? cs.outline,
        ) ??
        const [],
  );
}

SwitchThemeData? _switch(SurfaceConfig s, ColorScheme cs) {
  if (s.isEmpty) return null;
  final on = s.accent?.resolve(cs);
  final off = s.background?.resolve(cs);
  final thumb = s.foreground?.resolve(cs);
  final thumbOn = s.selectedForeground?.resolve(cs);
  final outline = s.borderColor?.resolve(cs);
  return SwitchThemeData(
    trackColor: on == null && off == null
        ? null
        : WidgetStateProperty.resolveWith(
            (st) =>
                controlColor(st.contains(WidgetState.selected) ? on : off, st),
          ),
    thumbColor: thumb == null
        ? null
        : WidgetStateProperty.resolveWith(
            (st) => controlColor(
              st.contains(WidgetState.selected) ? thumbOn ?? thumb : thumb,
              st,
            ),
          ),
    trackOutlineColor: outline == null && off == null
        ? null
        : WidgetStateProperty.resolveWith(
            (st) => controlColor(outline ?? Colors.transparent, st),
          ),
    trackOutlineWidth: s.borderWidth == null
        ? null
        : WidgetStatePropertyAll(s.borderWidth),
    // With an (empty) icon the thumb always has the same size, on
    // or off, as in BoardUI; without one, Material shrinks it when off.
    thumbIcon: thumb == null ? null : const WidgetStatePropertyAll(Icon(null)),
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
  );
}

SliderThemeData? _slider(SurfaceConfig s, ColorScheme cs) {
  if (s.isEmpty) return null;
  final active = s.accent?.resolve(cs);
  final activeEnd = s.accentEnd?.resolve(cs);
  final inactive = s.background?.resolve(cs);
  final thumb = s.foreground?.resolve(cs);
  final customThumb =
      thumb != null ||
      s.borderColor != null ||
      s.shadow != null ||
      s.radius != null;
  final trackColors = [?active, ?activeEnd];
  final trackBorder = s.borderWidth == null ? null : s.borderColor?.resolve(cs);
  final thumbColor = thumb ?? cs.primary;
  final thumbRadius = s.radius ?? SurfaceKind.slider.m3Radius;
  final thumbBorder = s.borderColor?.resolve(cs);
  final thumbShadows =
      s.shadow?.resolveWith(
        cs.brightness,
        s.shadowColor?.resolve(cs) ?? cs.outline,
      ) ??
      const <BoxShadow>[];
  return SliderThemeData(
    activeTrackColor: active,
    inactiveTrackColor: inactive,
    disabledActiveTrackColor: controlColor(active, {WidgetState.disabled}),
    disabledInactiveTrackColor: controlColor(inactive, {WidgetState.disabled}),
    trackHeight: s.height,
    thumbColor: thumb,
    trackShape: active == null
        ? null
        : GradientSliderTrackShape(
            activeColors: trackColors,
            borderColor: trackBorder,
            borderWidth: s.trackBorderWidth ?? s.borderWidth ?? 0,
            cornerRadius: s.innerRadius,
          ),
    rangeTrackShape: active == null
        ? null
        : GradientRangeSliderTrackShape(
            activeColors: trackColors,
            borderColor: trackBorder,
            borderWidth: s.trackBorderWidth ?? s.borderWidth ?? 0,
            cornerRadius: s.innerRadius,
          ),
    thumbShape: customThumb
        ? SoftSliderThumbShape(
            radius: thumbRadius,
            color: thumbColor,
            borderColor: thumbBorder,
            borderWidth: s.borderWidth ?? 1,
            cornerRadius: s.innerRadius,
            shadows: thumbShadows,
          )
        : null,
    rangeThumbShape: customThumb
        ? SoftRangeSliderThumbShape(
            radius: thumbRadius,
            color: thumbColor,
            borderColor: thumbBorder,
            borderWidth: s.borderWidth ?? 1,
            cornerRadius: s.innerRadius,
            shadows: thumbShadows,
          )
        : null,
    overlayColor: Colors.transparent,
    tickMarkShape: SliderTickMarkShape.noTickMark,
  );
}

TooltipThemeData? _tooltip(SurfaceConfig s, ColorScheme cs, TextTheme tt) {
  if (s.isEmpty) return null;
  final width = s.borderWidth ?? (s.borderColor != null ? 1.0 : 0.0);
  final hasPadding = s.paddingH != null || s.paddingV != null;
  return TooltipThemeData(
    decoration: BoxDecoration(
      color: s.background?.resolve(cs) ?? cs.inverseSurface,
      border: width == 0
          ? null
          : Border.all(
              color: s.borderColor?.resolve(cs) ?? cs.outlineVariant,
              width: width,
            ),
      borderRadius: BorderRadius.circular(
        s.radius ?? SurfaceKind.tooltip.m3Radius,
      ),
      boxShadow: s.shadow?.resolveWith(
        cs.brightness,
        s.shadowColor?.resolve(cs) ?? cs.outline,
      ),
    ),
    textStyle: _style(
      s.bodyStyle ?? TextRole.bodySmall,
      tt,
      s.foreground?.resolve(cs) ?? cs.onInverseSurface,
    ),
    padding: hasPadding
        ? EdgeInsets.symmetric(
            horizontal: s.paddingH ?? 8,
            vertical: s.paddingV ?? 4,
          )
        : null,
  );
}

TabBarThemeData? _tabBar(SurfaceConfig s, ColorScheme cs, TextTheme tt) {
  if (s.isEmpty) return null;
  final accent = s.accent?.resolve(cs);
  final divider = s.borderColor?.resolve(cs);
  final fill = s.background?.resolve(cs);
  final filledLabel = s.selectedForeground?.resolve(cs);
  return TabBarThemeData(
    // With a fill the indicator is a solid bordered box (accent);
    // otherwise the classic underline.
    indicator: fill != null
        ? ShapeDecoration(
            color: fill,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(s.innerRadius ?? 0),
              side: accent == null
                  ? BorderSide.none
                  : BorderSide(color: accent, width: s.borderWidth ?? 2),
            ),
          )
        : accent == null && s.borderWidth == null
        ? null
        : UnderlineTabIndicator(
            borderSide: BorderSide(
              color: accent ?? cs.primary,
              width: s.borderWidth ?? 2,
            ),
          ),
    indicatorSize: TabBarIndicatorSize.tab,
    labelColor: fill != null ? filledLabel ?? accent : accent,
    unselectedLabelColor: s.foreground?.resolve(cs),
    labelStyle: _style(s.titleStyle, tt),
    unselectedLabelStyle: _style(s.bodyStyle, tt),
    dividerColor: divider,
    dividerHeight: divider == null ? null : 1,
    labelPadding: s.paddingH == null
        ? null
        : EdgeInsets.symmetric(horizontal: s.paddingH!),
  );
}

ChipThemeData? _chip(SurfaceConfig s, ColorScheme cs, TextTheme tt) {
  if (s.isEmpty) return null;
  final bg = s.background?.resolve(cs);
  final selected = s.accent?.resolve(cs);
  final fg = s.foreground?.resolve(cs);
  final selectedFg = s.selectedForeground?.resolve(cs);
  final label = _style(s.bodyStyle ?? TextRole.labelLarge, tt);
  final hasPadding = s.paddingH != null || s.paddingV != null;
  return ChipThemeData(
    color: bg == null && selected == null
        ? null
        : WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return null;
            if (states.contains(WidgetState.selected)) return selected ?? bg;
            return bg;
          }),
    // The per-state color goes in the TextStyle as a WidgetStateColor: the chip
    // merges labelStyle with its own and a WidgetStateTextStyle would lose
    // resolution (text without color, so black, even in dark).
    labelStyle: fg == null && selectedFg == null && s.bodyStyle == null
        ? null
        : label!.copyWith(
            color: fg == null && selectedFg == null
                ? null
                : WidgetStateColor.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? selectedFg ?? fg ?? cs.onSurfaceVariant
                        : fg ?? cs.onSurfaceVariant,
                  ),
          ),
    checkmarkColor: selectedFg,
    iconTheme: fg == null ? null : IconThemeData(color: fg, size: 18),
    side: s.hasBorder ? surfaceSide(s, cs) : null,
    shape: s.radius == null
        ? null
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(s.radius!),
          ),
    padding: hasPadding
        ? EdgeInsets.symmetric(
            horizontal: s.paddingH ?? 8,
            vertical: s.paddingV ?? 4,
          )
        : null,
  );
}

BadgeThemeData? _badge(SurfaceConfig s, ColorScheme cs, TextTheme tt) =>
    s.isEmpty
    ? null
    : BadgeThemeData(
        backgroundColor: s.background?.resolve(cs),
        textColor: s.foreground?.resolve(cs),
        textStyle: _style(s.bodyStyle, tt),
        largeSize: s.height,
        padding: s.paddingH == null
            ? null
            : EdgeInsets.symmetric(horizontal: s.paddingH!),
      );

MenuStyle? _menuStyle(SurfaceConfig s, ColorScheme cs) {
  final bg = s.background?.resolve(cs);
  final hasShape = s.radius != null || s.hasBorder || s.hasShapeShadow;
  if (bg == null && !hasShape && s.elevation == null && s.paddingH == null) {
    return null;
  }
  return MenuStyle(
    backgroundColor: bg == null ? null : WidgetStatePropertyAll(bg),
    surfaceTintColor: bg == null
        ? null
        : const WidgetStatePropertyAll(Colors.transparent),
    elevation: s.elevation == null ? null : WidgetStatePropertyAll(s.elevation),
    shape: hasShape
        ? WidgetStatePropertyAll(_rounded(SurfaceKind.menu, s, cs)!)
        : null,
    padding: s.paddingH == null
        ? null
        : WidgetStatePropertyAll(EdgeInsets.all(s.paddingH!)),
  );
}

MenuThemeData? _menuTheme(SurfaceConfig s, ColorScheme cs) {
  final style = _menuStyle(s, cs);
  return style == null ? null : MenuThemeData(style: style);
}

DropdownMenuThemeData? _dropdownMenu(SurfaceConfig s, ColorScheme cs) {
  final style = _menuStyle(s, cs);
  return style == null ? null : DropdownMenuThemeData(menuStyle: style);
}

MenuButtonThemeData? _menuButtons(
  SurfaceConfig s,
  ColorScheme cs,
  TextTheme tt,
) {
  final hover = s.accent?.resolve(cs);
  final fg = s.foreground?.resolve(cs);
  final text = _style(s.bodyStyle, tt);
  if (hover == null &&
      fg == null &&
      text == null &&
      s.innerRadius == null &&
      s.paddingV == null) {
    return null;
  }
  return MenuButtonThemeData(
    style: ButtonStyle(
      backgroundColor: hover == null
          ? null
          : WidgetStateProperty.resolveWith(
              (states) =>
                  states.contains(WidgetState.hovered) ||
                      states.contains(WidgetState.focused) ||
                      states.contains(WidgetState.pressed)
                  ? hover
                  : Colors.transparent,
            ),
      overlayColor: hover == null
          ? null
          : const WidgetStatePropertyAll(Colors.transparent),
      foregroundColor: fg == null ? null : WidgetStatePropertyAll(fg),
      iconColor: fg == null ? null : WidgetStatePropertyAll(fg),
      textStyle: text == null ? null : WidgetStatePropertyAll(text),
      shape: s.innerRadius == null
          ? null
          : WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(s.innerRadius!),
              ),
            ),
      padding: s.paddingV == null
          ? null
          : WidgetStatePropertyAll(EdgeInsets.all(s.paddingV!)),
    ),
  );
}

PopupMenuThemeData? _popupMenu(SurfaceConfig s, ColorScheme cs, TextTheme tt) {
  if (s.isEmpty) return null;
  final fg = s.foreground?.resolve(cs);
  final text = _style(s.bodyStyle, tt, fg);
  final bg = s.background?.resolve(cs);
  return PopupMenuThemeData(
    color: bg,
    surfaceTintColor: bg == null ? null : Colors.transparent,
    elevation: s.elevation,
    shape: _rounded(SurfaceKind.menu, s, cs),
    menuPadding: s.paddingH == null ? null : EdgeInsets.all(s.paddingH!),
    labelTextStyle: text == null ? null : WidgetStatePropertyAll(text),
  );
}

SnackBarThemeData? _snackBar(SurfaceConfig s, ColorScheme cs, TextTheme tt) {
  if (s.isEmpty) return null;
  final fg = s.foreground?.resolve(cs);
  final shape = _rounded(SurfaceKind.snackBar, s, cs);
  return SnackBarThemeData(
    backgroundColor: s.background?.resolve(cs),
    contentTextStyle: _style(
      s.bodyStyle ?? (fg == null ? null : TextRole.bodyMedium),
      tt,
      fg,
    ),
    actionTextColor: s.accent?.resolve(cs),
    elevation: s.elevation,
    shape: shape,
    // Radius and border only show on "floating" SnackBars.
    behavior: shape == null ? null : SnackBarBehavior.floating,
  );
}

TextTheme _inheritable(TextTheme t) {
  TextStyle? i(TextStyle? s) => s?.copyWith(inherit: true);
  return TextTheme(
    displayLarge: i(t.displayLarge),
    displayMedium: i(t.displayMedium),
    displaySmall: i(t.displaySmall),
    headlineLarge: i(t.headlineLarge),
    headlineMedium: i(t.headlineMedium),
    headlineSmall: i(t.headlineSmall),
    titleLarge: i(t.titleLarge),
    titleMedium: i(t.titleMedium),
    titleSmall: i(t.titleSmall),
    bodyLarge: i(t.bodyLarge),
    bodyMedium: i(t.bodyMedium),
    bodySmall: i(t.bodySmall),
    labelLarge: i(t.labelLarge),
    labelMedium: i(t.labelMedium),
    labelSmall: i(t.labelSmall),
  );
}

/// Full text theme like the one `Theme.of` gives widgets
/// (geometry + colors, `inherit: false`).
///
/// `ThemeData.textTheme` only has colors and family (`inherit: true`):
/// starting from it would give styles without line height and weights, and
/// animated transitions would fail ("Failed to interpolate TextStyles with
/// different
/// inherit values").
TextTheme localizedTextTheme(ThemeData theme) =>
    theme.typography.englishLike.merge(theme.textTheme);

ButtonStyle? buildButtonStyle(
  ButtonKind kind,
  ButtonConfig b,
  ColorScheme cs,
  TextTheme tt, [
  TextStyle? Function(TextStyle?)? withFont,
]) {
  if (b.isEmpty) return null;
  final skin = b.needsSkin && kind.allowsSkin;
  final n = b.normal;

  // Start from labelLarge (the default M3 button style) so the
  // font family and line height are kept.
  final textStyle = b.hasTextStyle && !kind.isIconOnly
      ? (withFont ?? (s) => s)(
          tt.labelLarge?.copyWith(
            fontSize: b.fontSize,
            fontWeight: b.fontWeight,
            letterSpacing: b.letterSpacing,
            height: b.textHeight(
              tt.labelLarge?.fontSize ?? ButtonKind.defaultFontSize,
            ),
          ),
        )
      : null;

  final padding = b.hasPadding
      ? EdgeInsets.symmetric(
          horizontal: b.paddingH ?? kind.defaultPaddingH,
          vertical: b.paddingV ?? kind.defaultPaddingV,
        )
      : null;

  final minimumSize = b.hasMinSize
      ? Size(
          b.minWidth ?? kind.m3MinWidth,
          b.minHeight ?? ButtonKind.defaultMinHeight,
        )
      : null;

  Color? bg;
  Color? fg;
  BorderSide? side;
  OutlinedBorder? shape;
  if (!skin) {
    bg = n.fill?.resolve(cs);
    fg = n.foreground?.resolve(cs);
    if (b.hasSide) {
      final width = b.borderWidth ?? 1;
      side = width == 0
          ? BorderSide.none
          : BorderSide(
              color: n.border?.resolve(cs) ?? cs.outline,
              width: width,
            );
    }
    if (b.radius != null) {
      shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(b.radius!),
      );
    }
  }

  final base = switch (kind) {
    ButtonKind.elevated => ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      textStyle: textStyle,
      padding: padding,
      minimumSize: minimumSize,
      iconSize: b.iconSize,
      side: side,
      shape: shape,
    ),
    ButtonKind.filled => FilledButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      textStyle: textStyle,
      padding: padding,
      minimumSize: minimumSize,
      iconSize: b.iconSize,
      side: side,
      shape: shape,
    ),
    ButtonKind.outlined => OutlinedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      textStyle: textStyle,
      padding: padding,
      minimumSize: minimumSize,
      iconSize: b.iconSize,
      side: side,
      shape: shape,
    ),
    ButtonKind.text => TextButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      textStyle: textStyle,
      padding: padding,
      minimumSize: minimumSize,
      iconSize: b.iconSize,
      side: side,
      shape: shape,
    ),
    ButtonKind.ghost => TextButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      textStyle: textStyle,
      padding: padding,
      minimumSize: minimumSize,
      iconSize: b.iconSize,
      side: side,
      shape: shape,
    ),
    ButtonKind.danger => FilledButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      textStyle: textStyle,
      padding: padding,
      minimumSize: minimumSize,
      iconSize: b.iconSize,
      side: side,
      shape: shape,
    ),
    ButtonKind.icon || ButtonKind.iconSecondary => IconButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      padding: padding,
      minimumSize: minimumSize,
      iconSize: b.iconSize,
      side: side,
      shape: shape,
    ),
  };

  if (skin) return buildSkin(kind, b, cs).applyTo(base);
  if (kind.allowsSkin || !b.hasStateColors) return base;
  return stateColorStyle(kind, b, cs, base, textStyle);
}

/// Effective state for a set of WidgetStates: disabled > pressed >
/// hovered > focused > normal (like ButtonSkin).
ButtonStateKey buttonStateOf(Set<WidgetState> s) {
  if (s.contains(WidgetState.disabled)) return ButtonStateKey.disabled;
  if (s.contains(WidgetState.pressed)) return ButtonStateKey.pressed;
  if (s.contains(WidgetState.hovered)) return ButtonStateKey.hovered;
  if (s.contains(WidgetState.focused)) return ButtonStateKey.focused;
  return ButtonStateKey.normal;
}

/// TextButton with per-state colors, without ButtonSkin (see
/// [ButtonKind.allowsSkin]). Mirrors the exporter's `_stateColorStyle`.
ButtonStyle stateColorStyle(
  ButtonKind kind,
  ButtonConfig b,
  ColorScheme cs,
  ButtonStyle base,
  TextStyle? textStyle,
) {
  final eff = {
    for (final k in ButtonStateKey.values) k: effectiveState(kind, b, k),
  };
  T? pick<T>(Set<WidgetState> s, T? Function(EffectiveState) f) =>
      f(eff[buttonStateOf(s)]!) ?? f(eff[ButtonStateKey.normal]!);

  final width = b.borderWidth ?? kind.defaultBorderWidth;
  final interactiveColors = [
    ButtonStateKey.hovered,
    ButtonStateKey.pressed,
    ButtonStateKey.focused,
  ].any((k) => b.states[k]!.fill != null || b.states[k]!.foreground != null);
  final fg = WidgetStateProperty.resolveWith(
    (s) => pick(s, (e) => e.foreground)?.resolve(cs),
  );

  return base.copyWith(
    backgroundColor: WidgetStateProperty.resolveWith(
      (s) => pick(s, (e) => e.fill)?.resolve(cs) ?? Colors.transparent,
    ),
    foregroundColor: fg,
    iconColor: fg,
    overlayColor: interactiveColors
        ? const WidgetStatePropertyAll(Colors.transparent)
        : null,
    side: width == 0
        ? null
        : WidgetStateProperty.resolveWith(
            (s) => BorderSide(
              color: pick(s, (e) => e.border)?.resolve(cs) ?? cs.outline,
              width: width,
            ),
          ),
    textStyle: b.hoverUnderline == true && textStyle != null
        ? WidgetStateProperty.resolveWith(
            (s) =>
                s.contains(WidgetState.hovered) &&
                    !s.contains(WidgetState.disabled)
                ? textStyle.copyWith(decoration: TextDecoration.underline)
                : textStyle,
          )
        : null,
  );
}

/// Effective values of a state for [ButtonSkin], with the Material 3 defaults
/// for the normal and disabled states.
EffectiveState effectiveState(
  ButtonKind kind,
  ButtonConfig b,
  ButtonStateKey key,
) {
  final s = b.states[key]!;
  final n = b.normal;
  Offset? offset(StateStyle st) => st.offsetX == null && st.offsetY == null
      ? null
      : Offset(st.offsetX ?? 0, st.offsetY ?? 0);
  return switch (key) {
    ButtonStateKey.normal => EffectiveState(
      fill: s.fill ?? kind.m3Fill,
      fillEnd: s.fill != null ? s.fillEnd : null,
      foreground: s.foreground ?? kind.m3Foreground,
      border: s.border ?? kind.m3Border,
      shadow: s.shadow ?? kind.m3Shadow,
      shadowColor: s.shadowColor,
      offset: offset(s),
    ),
    ButtonStateKey.disabled => EffectiveState(
      fill: s.fill ?? kind.m3DisabledFill,
      fillEnd: s.fill != null ? s.fillEnd : null,
      foreground: s.foreground ?? kind.m3DisabledForeground,
      border: s.border ?? kind.m3DisabledBorder,
      shadow: s.shadow ?? ShadowToken.none,
      shadowColor: s.shadowColor ?? n.shadowColor,
      offset: offset(s) ?? (offset(n) == null ? null : Offset.zero),
    ),
    _ => EffectiveState(
      fill: s.fill,
      fillEnd: s.fill != null ? s.fillEnd : null,
      foreground: s.foreground,
      border: s.border,
      shadow: s.shadow,
      shadowColor: s.shadowColor ?? n.shadowColor,
      offset: offset(s),
    ),
  };
}

class EffectiveState {
  const EffectiveState({
    this.fill,
    this.fillEnd,
    this.foreground,
    this.border,
    this.shadow,
    this.shadowColor,
    this.offset,
  });

  final ColorRef? fill;
  final ColorRef? fillEnd;
  final ColorRef? foreground;
  final ColorRef? border;
  final ShadowToken? shadow;
  final ColorRef? shadowColor;
  final Offset? offset;

  bool get isEmpty =>
      fill == null &&
      foreground == null &&
      border == null &&
      shadow == null &&
      offset == null;

  ButtonSkinState resolve(ColorScheme cs) => ButtonSkinState(
    colors: fill == null
        ? null
        : [fill!.resolve(cs), if (fillEnd != null) fillEnd!.resolve(cs)],
    foreground: foreground?.resolve(cs),
    border: border?.resolve(cs),
    shadows: shadow?.resolveWith(
      cs.brightness,
      shadowColor?.resolve(cs) ?? cs.outline,
    ),
    offset: offset,
  );
}

ButtonSkin buildSkin(ButtonKind kind, ButtonConfig b, ColorScheme cs) {
  ButtonSkinState st(ButtonStateKey k) =>
      effectiveState(kind, b, k).resolve(cs);

  return ButtonSkin(
    normal: st(ButtonStateKey.normal),
    hovered: st(ButtonStateKey.hovered),
    pressed: st(ButtonStateKey.pressed),
    focused: st(ButtonStateKey.focused),
    disabled: st(ButtonStateKey.disabled),
    radius: b.radius ?? ButtonKind.defaultRadius,
    borderWidth: b.borderWidth ?? kind.defaultBorderWidth,
    pressScale: b.pressScale ?? 1,
    focusRing: b.focusRing?.resolve(cs),
    focusRingWidth: b.focusRingWidth ?? ButtonConfig.defaultFocusRingWidth,
    focusRingOffset: b.focusRingOffset ?? ButtonConfig.defaultFocusRingOffset,
    focusRingOffsetColor: b.focusRingOffsetColor?.resolve(cs),
    duration: Duration(
      milliseconds: (b.transitionMs ?? ButtonConfig.defaultTransitionMs)
          .round(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Text fields
// ---------------------------------------------------------------------------

/// State resolution order: the first matching key wins.
const fieldStateOrder = <(FieldStateKey, WidgetState)>[
  (FieldStateKey.disabled, WidgetState.disabled),
  (FieldStateKey.error, WidgetState.error),
  (FieldStateKey.focused, WidgetState.focused),
  (FieldStateKey.hovered, WidgetState.hovered),
];

/// How many states of [fieldStateOrder] to include in the map: all of them up
/// to the last one that differs from normal. A state equal to normal can't
/// be omitted if a different one comes after it, otherwise (e.g. error + focus)
/// resolution would fall back to the wrong state.
int fieldStatesToInclude(bool Function(FieldStateKey k) differs) {
  var count = 0;
  for (var i = 0; i < fieldStateOrder.length; i++) {
    if (differs(fieldStateOrder[i].$1)) count = i + 1;
  }
  return count;
}

/// Per-state resolver, mirroring the exporter's `_stateMap`.
///
/// Used with `WidgetStateXxx.resolveWith` (not fromMap): some widgets, such as
/// DropdownButton, read the theme value without resolving it, and the
/// fromMap variants throw in that case.
T Function(Set<WidgetState>) fieldResolver<T>(
  T Function(FieldStateKey k) value,
) => WidgetStateProperty<T>.fromMap(fieldStateMap(value)).resolve;

/// Per-state map, as short as possible.
WidgetStateMap<T> fieldStateMap<T>(T Function(FieldStateKey k) value) {
  final normal = value(FieldStateKey.normal);
  final n = fieldStatesToInclude((k) => value(k) != normal);
  return {
    for (final (k, s) in fieldStateOrder.take(n)) s: value(k),
    WidgetState.any: normal,
  };
}

ColorRef fieldPlaceholder(TextFieldConfig f, FieldStateKey k) =>
    f.view.placeholder(k) ??
    (k == FieldStateKey.disabled
        ? const RoleColor(SchemeRole.onSurface, alpha: 0.38)
        : const RoleColor(SchemeRole.onSurfaceVariant));

ColorRef fieldIcon(TextFieldConfig f, FieldStateKey k) =>
    f.view.icon(k) ??
    (k == FieldStateKey.disabled
        ? const RoleColor(SchemeRole.onSurface, alpha: 0.38)
        : const RoleColor(SchemeRole.onSurfaceVariant));

/// contentPadding: with an outline border Flutter adds `gapPadding` (4)
/// before the text, so we subtract it to get the requested inset.
EdgeInsetsDirectional fieldPadding(TextFieldConfig f) {
  final inset = f.textInset ?? TextFieldConfig.m3TextInset;
  final gap = f.customBorder ? 4.0 : 0.0;
  final v = f.paddingV ?? TextFieldConfig.m3PaddingV;
  return EdgeInsetsDirectional.fromSTEB(
    (inset - gap).clamp(0, double.infinity),
    v,
    f.paddingEnd ?? TextFieldConfig.m3PaddingEnd,
    v,
  );
}

TextStyle? buildInputTextStyle(
  TextFieldConfig f,
  TextStyle? base,
  ColorScheme cs,
) {
  final size = f.inputFontSize;
  final lh = f.inputLineHeight;
  final effectiveSize =
      size ?? base?.fontSize ?? TextFieldConfig.m3InputFontSize;
  return base?.copyWith(
    fontSize: size,
    fontWeight: f.inputWeight,
    height: lh == null ? null : lh / effectiveSize,
    letterSpacing: f.inputLetterSpacing,
    color: f.inputColor?.resolve(cs),
  );
}

InputDecorationThemeData? buildInputTheme(
  TextFieldConfig f,
  ColorScheme cs, [
  TextStyle? Function(TextStyle?)? withFont,
]) {
  if (f.isEmpty) return null;
  final view = f.view;
  final filled = FieldStateKey.values.any((k) => view.fill(k) != null);
  final iconBox = f.iconBox;

  InputBorder border(FieldStateKey k) {
    final width = view.borderWidth(k);
    final radius = BorderRadius.circular(f.radius ?? TextFieldConfig.m3Radius);
    final side = width == 0
        ? BorderSide.none
        : BorderSide(color: view.border(k).resolve(cs), width: width);
    if (f.underline == true) return UnderlineInputBorder(borderSide: side);
    final shadow = view.shadow(k);
    if (shadow != null && shadow != ShadowToken.none && !shadow.isHard) {
      return HardShadowInputBorder(
        borderRadius: radius,
        borderSide: side,
        shadows: shadow.resolve(cs.brightness),
      );
    }
    if (shadow != null && shadow.isHard) {
      final o = shadow.hardOffset!;
      return HardShadowInputBorder(
        borderRadius: radius,
        borderSide: side,
        shadowOffset: Offset(o, o),
        shadowColor: view.shadowColor(k)?.resolve(cs) ?? cs.outline,
        shadowSpread: shadow.hardSpread,
      );
    }
    return OutlineInputBorder(borderRadius: radius, borderSide: side);
  }

  TextStyle? subtext(ColorRef? color) => (withFont ?? (s) => s)(
    TextStyle(
      fontSize: f.helperFontSize,
      fontWeight: f.helperWeight,
      letterSpacing: f.helperLetterSpacing,
      color: color?.resolve(cs),
    ),
  );

  return InputDecorationThemeData(
    isDense: f.dense ?? false,
    contentPadding: f.hasPadding ? fieldPadding(f) : null,
    filled: filled,
    fillColor: filled
        ? WidgetStateColor.resolveWith(
            fieldResolver(
              (k) => view.fill(k)?.resolve(cs) ?? Colors.transparent,
            ),
          )
        : null,
    hoverColor: filled ? Colors.transparent : null,
    border: f.customBorder
        ? WidgetStateInputBorder.resolveWith(fieldResolver(border))
        : null,
    hintStyle: f.hasPlaceholder
        ? WidgetStateTextStyle.resolveWith(
            fieldResolver(
              (k) => TextStyle(color: fieldPlaceholder(f, k).resolve(cs)),
            ),
          )
        : null,
    prefixIconColor: f.hasIconColor
        ? WidgetStateColor.resolveWith(
            fieldResolver((k) => fieldIcon(f, k).resolve(cs)),
          )
        : null,
    suffixIconColor: f.hasIconColor
        ? WidgetStateColor.resolveWith(
            fieldResolver((k) => fieldIcon(f, k).resolve(cs)),
          )
        : null,
    prefixIconConstraints: iconBox == null
        ? null
        : BoxConstraints(minWidth: iconBox, minHeight: iconBox),
    suffixIconConstraints: iconBox == null
        ? null
        : BoxConstraints(minWidth: iconBox, minHeight: iconBox),
    helperStyle: f.hasHelperStyle ? subtext(f.helperColor) : null,
    errorStyle: f.hasErrorStyle ? subtext(f.errorColor) : null,
  );
}
