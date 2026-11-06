import 'package:material_ui/material_ui.dart';

import '../model/color_ref.dart';
import '../model/shadow_token.dart';
import '../model/surface_config.dart';
import '../model/text_field_config.dart';
import '../model/theme_builder.dart';
import '../model/theme_config.dart';
import '../model/typography_config.dart';
import 'button_skin_source.dart';
import 'export_format.dart';
import 'usage_notes.dart';

/// Generates `app_theme.dart` with the configured theme.
///
/// With [usePackage] the file imports the `materialcraft` package (ButtonSkin,
/// AppSwitch, HardShadowBorder, …); without it, the runtime sources are
/// included in the file, which stays self-contained.
///
/// [target] picks the Material library the file imports: `material_ui`
/// (Flutter 3.47+) or the framework's `flutter/material`.
///
/// Call `loadExportFormatter()` once before exporting.
///
/// Mirrors `model/theme_builder.dart`.
String exportDart(
  ThemeConfig c, {
  bool usePackage = false,
  ExportTarget target = ExportTarget.materialUi,
}) {
  _currentConfig = c;
  // Buttons drawn with ButtonSkin: the skin becomes a variable reused
  // by the theme and by the extra sizes.
  final skinKinds = [
    for (final k in ButtonKind.values)
      if (!extraButtonConfig(k, c.buttons[k]!).isEmpty &&
          extraButtonConfig(k, c.buttons[k]!).needsSkin &&
          k.allowsSkin &&
          (!k.isExtra || extraButtonStyles(c).any((e) => e.$1 == k)))
        k,
  ];
  final usesSkin = skinKinds.isNotEmpty;
  final f = c.textField;
  final usesButtonText =
      c.buttons.entries.any(
        (e) => !e.key.isIconOnly && !e.value.isEmpty && e.value.hasTextStyle,
      ) ||
      extraButtonStyles(c).any((e) => !e.$1.isIconOnly && e.$3.hasTextStyle) ||
      c.surfaces.entries.any((e) => _surfaceUsesText(e.key, e.value));
  final font = c.fontFamily;

  // --- _build body ---------------------------------------------------------
  final body = StringBuffer();

  final seedArgs = <(String?, _Expr)>[
    ('seedColor', _lit('seedColor', isConst: false)),
    ('brightness', _lit('brightness', isConst: false)),
    if (c.variant != DynamicSchemeVariant.tonalSpot)
      ('dynamicSchemeVariant', _lit('DynamicSchemeVariant.${c.variant.name}')),
  ];
  var scheme = _call(
    'ColorScheme.fromSeed',
    seedArgs,
    multiline: true,
  ).code(false, '    ');
  if (c.schemeOverrides.isNotEmpty) {
    final overrides = <(String?, _Expr)>[
      for (final e in c.schemeOverrides.entries) (e.key.name, _color(e.value)),
    ];
    scheme += _call(
      '.copyWith',
      overrides,
      multiline: true,
    ).code(false, '    ');
  }
  body.writeln('    final colorScheme = dynamicScheme ?? $scheme;');

  final baseArgs = <(String?, _Expr)>[
    ('colorScheme', _lit('colorScheme', isConst: false)),
    if (font != null) ('fontFamily', _lit("'$font'")),
    if (!c.typography.isEmpty) ('textTheme', _typography(c.typography)),
    if (c.density != null) ('visualDensity', _lit(c.density!.dart)),
    if (c.shrinkWrapTapTargets)
      ('materialTapTargetSize', _lit('MaterialTapTargetSize.shrinkWrap')),
  ];
  body.writeln(
    '    final base = ${_call('ThemeData', baseArgs, multiline: baseArgs.length > 2).code(false, '    ')};',
  );
  if (f.hasInputStyle) {
    final input = _call(
      'base.textTheme.bodyLarge?.copyWith',
      _inputStyleArgs(f),
      isConstructor: false,
    );
    body.writeln(
      '    // Style of the text typed in TextFields (also used by other widgets).',
    );
    body.writeln('    final inputTextTheme = base.textTheme.copyWith(');
    body.writeln('      bodyLarge: ${input.code(false, '      ')},');
    body.writeln('    );');
  }
  if (usesButtonText) {
    body.writeln(
      '    // Complete styles (geometry + colors) like those of Theme.of(context).',
    );
    body.writeln(
      '    final textTheme = base.typography.englishLike.merge(${f.hasInputStyle ? 'inputTextTheme' : 'base.textTheme'});',
    );
  }
  body.writeln();

  final themes = <(String?, _Expr)>[
    if (f.hasInputStyle) ('textTheme', _lit('inputTextTheme', isConst: false)),
    ..._surfaceThemes(c),
    if (!f.isEmpty) ('inputDecorationTheme', _inputTheme(f)),
    if (f.cursor != null)
      (
        'textSelectionTheme',
        _call('TextSelectionThemeData', [('cursorColor', _color(f.cursor!))]),
      ),
    for (final kind in ButtonKind.values)
      if (!kind.isExtra && !c.buttons[kind]!.isEmpty)
        (
          kind.themeField,
          _call(kind.themeData!, [
            ('style', _buttonStyle(kind, c.buttons[kind]!, skinKinds)),
          ], multiline: true),
        ),
    ('extensions', _extensions(c, skinKinds)),
  ];
  for (final k in skinKinds) {
    final b = extraButtonConfig(k, c.buttons[k]!);
    body.writeln(
      '    final ${k.name}Skin = ${_skinExpr(k, b).code(false, '    ')};',
    );
  }
  if (skinKinds.isNotEmpty) body.writeln();
  body.writeln(
    '    return ${_call('base.copyWith', themes, multiline: true).code(false, '    ')};',
  );

  final bodyText = body.toString();
  final isDarkLine = bodyText.contains('isDark')
      ? '    final isDark = brightness == Brightness.dark;\n'
      : '';

  // --- file ----------------------------------------------------------------
  final out = StringBuffer();
  out.writeln('// Generated with MaterialCraft by Daniele Orlando.');
  out.writeln('// https://materialcraft.danieleorlando.me');
  // The same instructions as the export's "How to use it" tab.
  for (final note in usageNotes(c, usePackage: usePackage, target: target)) {
    out.writeln('//');
    out.writeln('// ${note.title}${note.required ? ' (required)' : ''}');
    for (final line in _wrap(note.body, 76)) {
      out.writeln('// $line');
    }
    for (final line in note.after.split('\n')) {
      out.writeln('//   $line'.trimRight());
    }
  }
  if (font != null) {
    out.writeln('//');
    out.writeln(
      "// Instead of bundling assets, with the google_fonts package replace",
    );
    out.writeln("// `fontFamily: '$font'` with");
    out.writeln("// `textTheme: GoogleFonts.getTextTheme('$font', ...)`.");
  }
  out.writeln();
  out.writeln("import '${target.import}';");
  if (usePackage) {
    out.writeln("import 'package:materialcraft/materialcraft.dart';");
    // Re-export the package: files that import only app_theme.dart can use
    // context.buttonStyle, AppButtonKind, AppSwitch, … as the header shows.
    out.writeln();
    out.writeln("export 'package:materialcraft/materialcraft.dart';");
  }
  out.writeln();
  out.writeln(
    '/// The app theme: pass it to `MaterialApp(theme:, darkTheme:)`.',
  );
  out.writeln('abstract final class AppTheme {');
  out.writeln('  /// Seed of the generated color scheme.');
  out.writeln('  static const seedColor = Color(0x${hexArgb(c.seedColor)});');
  out.writeln();
  out.writeln('  /// Light theme.');
  out.writeln('  ///');
  out.writeln('  /// [dynamicScheme] replaces the color scheme, e.g. with the');
  out.writeln('  /// wallpaper colors of Android 12+ (package dynamic_color).');
  out.writeln('  /// Colors that the theme fixes outside the scheme stay.');
  out.writeln('  static ThemeData light([ColorScheme? dynamicScheme]) =>');
  out.writeln('      _build(Brightness.light, dynamicScheme);');
  out.writeln();
  out.writeln('  /// Dark theme; [dynamicScheme] as in [light].');
  out.writeln('  static ThemeData dark([ColorScheme? dynamicScheme]) =>');
  out.writeln('      _build(Brightness.dark, dynamicScheme);');
  out.writeln();
  out.writeln(
    '  static ThemeData _build(Brightness brightness, ColorScheme? dynamicScheme) {',
  );
  out.write(isDarkLine);
  out.write(bodyText);
  out.writeln('  }');
  // Only if the code uses it (e.g. a radius on checkboxes doesn't need it).
  if (bodyText.contains('_dim(')) {
    out.writeln();
    out.writeln('  /// Disabled controls: color at 50%.');
    out.writeln('  static Color? _dim(Color? c, Set<WidgetState> states) =>');
    out.writeln('      c == null || !states.contains(WidgetState.disabled)');
    out.writeln('          ? c');
    out.writeln('          : c.withValues(alpha: c.a * 0.5);');
  }
  out.writeln('}');
  if (!usePackage) {
    final runtime = StringBuffer();
    _writeRuntimeSources(runtime, c, usesSkin: usesSkin);
    out.write(
      target == ExportTarget.flutterMaterial
          ? legacyConstructorSyntax(runtime.toString())
          : runtime,
    );
  }

  return formatExport(out.toString(), languageVersion: target.dartVersion);
}

/// Rewrites the Dart 3.13 constructor syntax of the runtime sources
/// (`const new(...)`, `const new named(...)`, `factory named(...)`) with the
/// class name, for the SDKs before Flutter 3.47.
String legacyConstructorSyntax(String source) {
  final classDecl = RegExp(
    r'^(?:(?:abstract|base|final|interface|sealed)\s+)*class\s+(\w+)',
  );
  String? cls;
  return [
    for (final line in source.split('\n'))
      () {
        cls = classDecl.firstMatch(line)?.group(1) ?? cls;
        return line
            .replaceAllMapped(
              RegExp(r'^(\s+(?:const\s+)?)new\s+(\w+)\('),
              (m) => '${m[1]}$cls.${m[2]}(',
            )
            .replaceAllMapped(
              RegExp(r'^(\s+(?:const\s+)?)new\('),
              (m) => '${m[1]}$cls(',
            )
            .replaceAllMapped(
              RegExp(r'^(\s+factory\s+)(\w+)\('),
              (m) => m[2] == cls ? m[0]! : '${m[1]}$cls.${m[2]}(',
            );
      }(),
  ].join('\n');
}

/// Runtime sources (the same classes as the `materialcraft` package),
/// only those the theme uses.
void _writeRuntimeSources(
  StringBuffer out,
  ThemeConfig c, {
  required bool usesSkin,
}) {
  if (usesSkin) {
    out.writeln();
    out.writeln(
      '// ---------------------------------------------------------------------------',
    );
    out.writeln(
      '// ButtonSkin: states, gradients, CSS shadows, focus ring and press effect.',
    );
    out.writeln(
      '// ---------------------------------------------------------------------------',
    );
    out.writeln();
    out.write(buttonSkinSource);
  }
  out.writeln();
  out.writeln(
    '// ---------------------------------------------------------------------------',
  );
  out.writeln(
    '// AppButtonStyles: extra styles (danger, small / xs sizes, …).',
  );
  out.writeln(
    '// Usage: FilledButton(style: context.buttonStyle(AppButtonKind.danger), ...)',
  );
  out.writeln(
    '// ---------------------------------------------------------------------------',
  );
  out.writeln();
  out.write(appButtonStylesSource);
  if (_hardShadowUsed(c)) {
    out.writeln();
    out.writeln(
      '// ---------------------------------------------------------------------------',
    );
    out.writeln(
      '// HardShadowBorder: border with a "hard" shadow (cards, dialogs, menus, …).',
    );
    out.writeln(
      '// ---------------------------------------------------------------------------',
    );
    out.writeln();
    out.write(hardShadowBorderSource);
  }
  out.writeln();
  out.writeln(
    '// ---------------------------------------------------------------------------',
  );
  out.writeln(
    '// AppSwitch: switch with the theme geometry (square thumb, borders);',
  );
  out.writeln(
    '// without an AppSwitchStyle in the theme it renders the regular Switch.',
  );
  out.writeln(
    '// Usage: AppSwitch(value: on, onChanged: (v) => setState(() => on = v))',
  );
  out.writeln(
    '// ---------------------------------------------------------------------------',
  );
  out.writeln();
  out.write(appSwitchSource);
  if (_sliderShapesUsed(c)) {
    out.writeln();
    out.writeln(
      '// ---------------------------------------------------------------------------',
    );
    out.writeln(
      '// Slider shapes: gradient track and thumb with border and shadow.',
    );
    out.writeln(
      '// ---------------------------------------------------------------------------',
    );
    out.writeln();
    out.write(sliderShapesSource);
  }
}

_Expr _buttonStyle(
  ButtonKind kind,
  ButtonConfig b, [
  List<ButtonKind> skinKinds = const [],
]) {
  final skin = b.needsSkin && kind.allowsSkin;
  final n = b.normal;
  final args = <(String?, _Expr)>[];

  if (!skin) {
    if (n.fill != null) args.add(('backgroundColor', _color(n.fill!)));
    if (n.foreground != null) {
      args.add(('foregroundColor', _color(n.foreground!)));
    }
  }

  if (b.hasTextStyle && !kind.isIconOnly) {
    args.add(('textStyle', _textStyleExpr(b)));
  }

  if (b.hasPadding) {
    args.add((
      'padding',
      _call('EdgeInsets.symmetric', [
        ('horizontal', _num(b.paddingH ?? kind.defaultPaddingH)),
        ('vertical', _num(b.paddingV ?? kind.defaultPaddingV)),
      ]),
    ));
  }

  if (b.hasMinSize) {
    args.add((
      'minimumSize',
      _call('Size', [
        (null, _num(b.minWidth ?? kind.m3MinWidth)),
        (null, _num(b.minHeight ?? ButtonKind.defaultMinHeight)),
      ]),
    ));
  }

  if (b.iconSize != null) args.add(('iconSize', _num(b.iconSize!)));

  if (!skin) {
    if (b.hasSide) {
      final width = b.borderWidth ?? 1;
      if (width == 0) {
        args.add(('side', _lit('BorderSide.none')));
      } else {
        args.add((
          'side',
          _call('BorderSide', [
            ('color', _color(n.border ?? const RoleColor(SchemeRole.outline))),
            ('width', _num(width)),
          ]),
        ));
      }
    }
    if (b.radius != null) args.add(('shape', _shape(b.radius!)));
  }

  final styleFrom = _call(
    '${kind.widget}.styleFrom',
    args,
    multiline: true,
    isConstructor: false,
  );
  if (!skin && !kind.allowsSkin && b.hasStateColors) {
    return _stateColorStyle(kind, b, styleFrom);
  }
  if (!skin) return styleFrom;

  // <kind>Skin.applyTo(XxxButton.styleFrom(...)): the skin is a variable;
  // the sizes only change the radius with copyWith.
  final _Expr skinRef;
  if (skinKinds.contains(kind)) {
    final base = extraButtonConfig(kind, _rootConfigOf(kind, b));
    final radius = b.radius ?? ButtonKind.defaultRadius;
    final baseRadius = base.radius ?? ButtonKind.defaultRadius;
    skinRef = radius == baseRadius
        ? _lit('${kind.name}Skin', isConst: false)
        : _lit(
            '${kind.name}Skin.copyWith(radius: ${formatNum(radius)})',
            isConst: false,
          );
  } else {
    skinRef = _skinExpr(kind, b);
  }
  return _Expr(
    (inConst, indent) =>
        '${skinRef.code(false, indent)}.applyTo(${styleFrom.code(false, indent)})',
    false,
  );
}

/// labelLarge size in the exported theme (base for `height`).
double _labelLargeSize(ThemeConfig? c) =>
    c?.typography.styles[TextRole.labelLarge]?.size ??
    TextRole.labelLarge.m3Size;

/// `XxxButton.styleFrom(...).copyWith(...)` with per-state colors, mirroring
/// the builder's `stateColorStyle`.
_Expr _stateColorStyle(ButtonKind kind, ButtonConfig b, _Expr styleFrom) {
  final eff = {
    for (final k in ButtonStateKey.values) k: effectiveState(kind, b, k),
  };
  const order = [
    (ButtonStateKey.disabled, 'disabled'),
    (ButtonStateKey.pressed, 'pressed'),
    (ButtonStateKey.hovered, 'hovered'),
    (ButtonStateKey.focused, 'focused'),
  ];

  /// Closure `(states) { if ... return X; ... return N; }` for a field.
  _Expr resolver(
    ColorRef? Function(EffectiveState) f,
    String fallback, [
    String Function(String color)? wrap,
  ]) {
    String value(ButtonStateKey k, String indent) {
      final ref = f(eff[k]!) ?? f(eff[ButtonStateKey.normal]!);
      final color = ref == null ? fallback : _color(ref).code(false, indent);
      return wrap == null ? color : wrap(color);
    }

    return _code((i) {
      final normal = value(ButtonStateKey.normal, i);
      final lines = [
        for (final (k, name) in order)
          if (value(k, i) != normal)
            '$i  if (states.contains(WidgetState.$name)) return ${value(k, i)};',
        '$i  return $normal;',
      ];
      return 'WidgetStateProperty.resolveWith((states) {\n${lines.join('\n')}\n$i})';
    });
  }

  final width = b.borderWidth ?? kind.defaultBorderWidth;
  final interactiveColors = [
    ButtonStateKey.hovered,
    ButtonStateKey.pressed,
    ButtonStateKey.focused,
  ].any((k) => b.states[k]!.fill != null || b.states[k]!.foreground != null);
  final fg = resolver((e) => e.foreground, 'null');

  final copyArgs = <(String?, _Expr)>[
    ('backgroundColor', resolver((e) => e.fill, 'Colors.transparent')),
    ('foregroundColor', fg),
    ('iconColor', fg),
    if (interactiveColors)
      (
        'overlayColor',
        _lit(
          'const WidgetStatePropertyAll(Colors.transparent)',
          isConst: false,
        ),
      ),
    if (width != 0)
      (
        'side',
        resolver(
          (e) => e.border,
          'colorScheme.outline',
          (color) => 'BorderSide(color: $color, width: ${formatNum(width)})',
        ),
      ),
  ];
  final underline = b.hoverUnderline == true;
  final textArg = underline
      ? _code((i) {
          final base = _textStyleExpr(b).code(false, i);
          return 'WidgetStateProperty.resolveWith((states) => '
              'states.contains(WidgetState.hovered) && !states.contains(WidgetState.disabled) '
              '? ($base)?.copyWith(decoration: TextDecoration.underline) : $base)';
        })
      : null;
  return _Expr((inConst, indent) {
    final inner = '$indent  ';
    final lines = [
      for (final (name, e) in copyArgs) '$inner$name: ${e.code(false, inner)},',
      if (textArg != null) '${inner}textStyle: ${textArg.code(false, inner)},',
    ];
    return '${styleFrom.code(false, indent)}.copyWith(\n${lines.join('\n')}\n$indent)';
  }, false);
}

/// The same TextStyle passed to styleFrom (`textTheme.labelLarge?.copyWith`).
_Expr _textStyleExpr(ButtonConfig b) =>
    _call('textTheme.labelLarge?.copyWith', [
      if (b.headFont == true && _currentConfig?.headFontFamily != null)
        ('fontFamily', _lit("'${_currentConfig!.headFontFamily}'")),
      if (b.fontSize != null) ('fontSize', _num(b.fontSize!)),
      if (b.fontWeight != null)
        ('fontWeight', _lit('FontWeight.w${b.fontWeight!.value}')),
      if (b.letterSpacing != null) ('letterSpacing', _num(b.letterSpacing!)),
      if (b.lineHeight != null)
        ('height', _num(b.textHeight(_labelLargeSize(_currentConfig))!)),
    ], isConstructor: false);

/// The medium configuration [b] derives from (to compare the radius).
ButtonConfig _rootConfigOf(ButtonKind kind, ButtonConfig b) =>
    _currentConfig?.buttons[kind] ?? b;

ThemeConfig? _currentConfig;

_Expr _skinExpr(ButtonKind kind, ButtonConfig b) {
  final skinArgs = <(String?, _Expr)>[
    for (final key in ButtonStateKey.values)
      if (key == ButtonStateKey.normal || !effectiveState(kind, b, key).isEmpty)
        (key.name, _skinState(effectiveState(kind, b, key))),
  ];
  final radius = b.radius ?? ButtonKind.defaultRadius;
  if (radius != 20) skinArgs.add(('radius', _num(radius)));
  final borderWidth = b.borderWidth ?? kind.defaultBorderWidth;
  if (borderWidth != 0) skinArgs.add(('borderWidth', _num(borderWidth)));
  if (b.pressScale != null && b.pressScale != 1) {
    skinArgs.add(('pressScale', _num(b.pressScale!)));
  }
  if (b.focusRing != null) skinArgs.add(('focusRing', _color(b.focusRing!)));
  if (b.focusRingWidth != null && b.focusRingWidth != 2) {
    skinArgs.add(('focusRingWidth', _num(b.focusRingWidth!)));
  }
  if (b.focusRingOffset != null && b.focusRingOffset != 2) {
    skinArgs.add(('focusRingOffset', _num(b.focusRingOffset!)));
  }
  if (b.focusRingOffsetColor != null) {
    skinArgs.add(('focusRingOffsetColor', _color(b.focusRingOffsetColor!)));
  }
  final ms = (b.transitionMs ?? ButtonConfig.defaultTransitionMs).round();
  if (ms != 150) {
    skinArgs.add((
      'duration',
      _call('Duration', [('milliseconds', _lit('$ms'))]),
    ));
  }
  return _call('ButtonSkin', skinArgs, multiline: true);
}

/// `extensions: [AppButtonStyles({...})]` with danger, icon secondary and the
/// small / xs sizes (see `extraButtonStyles` in the builder).
_Expr _extensions(ThemeConfig c, List<ButtonKind> skinKinds) {
  final entries = extraButtonStyles(c);
  final sw = _appSwitchStyle(c.surfaces[SurfaceKind.switchControl]!);
  if (entries.isEmpty && sw == null) return _lit('const [AppButtonStyles()]');
  return _Expr((inConst, indent) {
    final inner = '$indent    ';
    final lines = [
      for (final (kind, size, config) in entries)
        '$inner(AppButtonKind.${kind.name}, AppButtonSize.${size.name}): '
            '${_buttonStyle(kind, config, skinKinds).code(false, inner)},',
    ];
    final buttons = entries.isEmpty
        ? '$indent  const AppButtonStyles(),'
        : '$indent  AppButtonStyles({\n${lines.join('\n')}\n$indent  }),';
    final switchLine = sw == null
        ? ''
        : '\n$indent  ${sw.code(false, '$indent  ')},';
    return '[\n$buttons$switchLine\n$indent]';
  }, false);
}

/// `AppSwitchStyle(...)` if the switch has its own geometry.
_Expr? _appSwitchStyle(SurfaceConfig s) {
  if (!s.hasSwitchGeometry) return null;
  return _call('AppSwitchStyle', [
    if (s.width != null) ('width', _num(s.width!)),
    if (s.height != null) ('height', _num(s.height!)),
    if (s.thumbSize != null) ('thumbSize', _num(s.thumbSize!)),
    if (s.radius != null) ('trackRadius', _num(s.radius!)),
    if (s.innerRadius != null) ('thumbRadius', _num(s.innerRadius!)),
    if (s.borderColor != null) ('thumbBorder', _lit('true')),
    if (s.shadow != null) ('thumbShadows', _shadows(s.shadow!, s.shadowColor)),
  ]);
}

_Expr _skinState(EffectiveState s) {
  return _call('ButtonSkinState', [
    if (s.fill != null)
      (
        'colors',
        _list([_color(s.fill!), if (s.fillEnd != null) _color(s.fillEnd!)]),
      ),
    if (s.foreground != null) ('foreground', _color(s.foreground!)),
    if (s.border != null) ('border', _color(s.border!)),
    if (s.shadow != null) ('shadows', _shadows(s.shadow!, s.shadowColor)),
    if (s.offset != null)
      (
        'offset',
        _call('Offset', [
          (null, _num(s.offset!.dx)),
          (null, _num(s.offset!.dy)),
        ]),
      ),
  ], multiline: true);
}

_Expr _shadows(ShadowToken t, [ColorRef? hardColor]) {
  if (t.isHard) {
    return _list([
      _call('BoxShadow', [
        ('color', _color(hardColor ?? const RoleColor(SchemeRole.outline))),
        (
          'offset',
          _call('Offset', [
            (null, _num(t.hardOffset!)),
            (null, _num(t.hardOffset!)),
          ]),
        ),
        if (t.hardSpread != 0) ('spreadRadius', _num(t.hardSpread)),
      ]),
    ]);
  }
  _Expr list(List<CssShadow> shadows) => _list([
    for (final s in shadows)
      _call('BoxShadow', [
        ('color', _color(CustomColor(s.toBoxShadow().color))),
        if (s.x != 0 || s.y != 0)
          ('offset', _call('Offset', [(null, _num(s.x)), (null, _num(s.y))])),
        if (s.flutterBlur != 0) ('blurRadius', _num(s.flutterBlur)),
        if (s.spread != 0) ('spreadRadius', _num(s.spread)),
      ]),
  ]);
  final light = list(t.light);
  final dark = list(t.dark);
  final l = light.code(false, '');
  final d = dark.code(false, '');
  if (l == d) return light;
  return _Expr((_, indent) => '(isDark ? $d : $l)', false);
}

// --- Tipografia ----------------------------------------------------------------

_Expr _typography(TypographyConfig t) => _call('TextTheme', [
  for (final r in TextRole.values)
    if (!t.styles[r]!.isEmpty) (r.name, _typeSpec(r, t.styles[r]!)),
], multiline: true);

_Expr _typeSpec(TextRole r, TypeSpec s) {
  final style = s.toStyle(r);
  final head = _currentConfig?.headFontFamily;
  final expr = _call('TextStyle', [
    if (s.headFont == true && head != null) ('fontFamily', _lit("'$head'")),
    if (style.fontSize != null) ('fontSize', _num(style.fontSize!)),
    if (style.height != null) ('height', _num(style.height!)),
    if (style.fontWeight != null)
      ('fontWeight', _lit('FontWeight.w${style.fontWeight!.value}')),
    if (style.letterSpacing != null)
      ('letterSpacing', _num(style.letterSpacing!)),
  ]);
  return s.source == null ? expr : _commented(s.source!, expr);
}

/// Prepends a comment to the expression (e.g. the source token's name).
_Expr _commented(String comment, _Expr e) => _Expr(
  (inConst, indent) => '/* $comment */ ${e.code(inConst, indent)}',
  e.isConst,
);

// --- Contenitori -----------------------------------------------------------------

const _variant = RoleColor(SchemeRole.onSurfaceVariant);
const _onSurface = RoleColor(SchemeRole.onSurface);

_Expr? _indicatorShapeExpr(SurfaceConfig s) =>
    s.innerRadius == null && !s.hasBorder
    ? null
    : _call('RoundedRectangleBorder', [
        (
          'borderRadius',
          _call('BorderRadius.all', [
            (
              null,
              _call('Radius.circular', [(null, _num(s.innerRadius ?? 16))]),
            ),
          ]),
        ),
        ('side', _side(s)),
      ]);

bool _surfaceUsesText(SurfaceKind k, SurfaceConfig s) =>
    !s.isEmpty &&
    (s.titleStyle != null ||
        s.bodyStyle != null ||
        k == SurfaceKind.tooltip ||
        (k == SurfaceKind.chip &&
            (s.foreground != null || s.selectedForeground != null)) ||
        (k == SurfaceKind.snackBar && s.foreground != null));

/// `textTheme.<role>` (possibly with a color), mirroring `_style`.
_Expr? _textRef(TextRole? role, [ColorRef? color]) {
  if (role == null) return null;
  final ref = 'textTheme.${role.name}';
  return color == null
      ? _lit(ref, isConst: false)
      : _call('$ref?.copyWith', [
          ('color', _color(color)),
        ], isConstructor: false);
}

_Expr _side(SurfaceConfig s) {
  final width = s.borderWidth ?? (s.borderColor != null ? 1.0 : 0.0);
  if (width == 0) return _lit('BorderSide.none');
  return _call('BorderSide', [
    (
      'color',
      _color(s.borderColor ?? const RoleColor(SchemeRole.outlineVariant)),
    ),
    ('width', _num(width)),
  ]);
}

_Expr? _roundedShape(SurfaceKind k, SurfaceConfig s) {
  if (s.radius == null && !s.hasBorder && !s.hasShapeShadow) return null;
  if (s.hasShapeShadow && !s.hasHardShadow) {
    return _call('HardShadowBorder', [
      ('radius', _num(s.radius ?? k.m3Radius)),
      ('side', _side(s)),
      ('shadows', _shadows(s.shadow!)),
    ]);
  }
  if (s.hasHardShadow) {
    final o = s.shadow!.hardOffset!;
    return _call('HardShadowBorder', [
      ('radius', _num(s.radius ?? k.m3Radius)),
      ('side', _side(s)),
      ('shadowOffset', _call('Offset', [(null, _num(o)), (null, _num(o))])),
      if (s.shadow!.hardSpread != 0)
        ('shadowSpread', _num(s.shadow!.hardSpread)),
      (
        'shadowColor',
        _color(s.shadowColor ?? const RoleColor(SchemeRole.outline)),
      ),
    ]);
  }
  return _call('RoundedRectangleBorder', [
    (
      'borderRadius',
      _call('BorderRadius.all', [
        (
          null,
          _call('Radius.circular', [(null, _num(s.radius ?? k.m3Radius))]),
        ),
      ]),
    ),
    ('side', _side(s)),
  ]);
}

List<(String?, _Expr)> _surfaceThemes(ThemeConfig c) {
  final out = <(String?, _Expr)>[];
  void add(
    String field,
    SurfaceKind k,
    List<(String?, _Expr?)> args, [
    String? type,
  ]) {
    final s = c.surfaces[k]!;
    if (s.isEmpty) return;
    out.add((
      field,
      _call(type ?? k.themeData, [
        for (final (name, value) in args)
          if (value != null) (name, value),
      ], multiline: true),
    ));
  }

  _Expr? col(ColorRef? r) => r == null ? null : _color(r);
  _Expr? n(double? v) => v == null ? null : _num(v);
  _Expr transparentIf(ColorRef? bg) => _lit('Colors.transparent');

  final card = c.surfaces[SurfaceKind.card]!;
  add('cardTheme', SurfaceKind.card, [
    ('color', col(card.background)),
    ('elevation', n(card.elevation)),
    ('shape', _roundedShape(SurfaceKind.card, card)),
  ]);

  final dialog = c.surfaces[SurfaceKind.dialog]!;
  add('dialogTheme', SurfaceKind.dialog, [
    ('backgroundColor', col(dialog.background)),
    ('elevation', n(dialog.elevation)),
    ('shape', _roundedShape(SurfaceKind.dialog, dialog)),
    ('titleTextStyle', _textRef(dialog.titleStyle)),
    ('contentTextStyle', _textRef(dialog.bodyStyle, _variant)),
  ]);

  final sheet = c.surfaces[SurfaceKind.bottomSheet]!;
  add('bottomSheetTheme', SurfaceKind.bottomSheet, [
    ('backgroundColor', col(sheet.background)),
    ('modalBackgroundColor', col(sheet.background)),
    ('elevation', n(sheet.elevation)),
    ('modalElevation', n(sheet.elevation)),
    (
      'shape',
      sheet.radius == null
          ? null
          : _call('RoundedRectangleBorder', [
              (
                'borderRadius',
                _call('BorderRadius.vertical', [
                  (
                    'top',
                    _call('Radius.circular', [(null, _num(sheet.radius!))]),
                  ),
                ]),
              ),
            ]),
    ),
    ('dragHandleColor', col(sheet.accent)),
  ]);

  final bar = c.surfaces[SurfaceKind.appBar]!;
  final barWidth = bar.borderWidth ?? (bar.borderColor != null ? 1.0 : 0.0);
  add('appBarTheme', SurfaceKind.appBar, [
    ('backgroundColor', col(bar.background)),
    ('foregroundColor', col(bar.foreground)),
    ('elevation', n(bar.elevation)),
    ('scrolledUnderElevation', n(bar.elevation)),
    (
      'surfaceTintColor',
      bar.background == null ? null : transparentIf(bar.background),
    ),
    ('shape', barWidth == 0 ? null : _call('Border', [('bottom', _side(bar))])),
    ('titleTextStyle', _textRef(bar.titleStyle, bar.foreground)),
  ]);

  final nav = c.surfaces[SurfaceKind.navigationBar]!;
  add('navigationBarTheme', SurfaceKind.navigationBar, [
    ('indicatorShape', _indicatorShapeExpr(nav)),
    ('backgroundColor', col(nav.background)),
    ('indicatorColor', col(nav.accent)),
    ('elevation', n(nav.elevation)),
    ('height', n(nav.height)),
    (
      'surfaceTintColor',
      nav.background == null ? null : transparentIf(nav.background),
    ),
    (
      'labelTextStyle',
      nav.titleStyle == null
          ? null
          : _Expr(
              (inConst, indent) =>
                  'WidgetStateProperty.resolveWith((states) => '
                  'states.contains(WidgetState.selected) '
                  '? ${_textRef(nav.titleStyle, _onSurface)!.code(false, indent)} '
                  ': ${_textRef(nav.titleStyle, _variant)!.code(false, indent)})',
              false,
            ),
    ),
    (
      'iconTheme',
      nav.foreground == null
          ? null
          : _Expr(
              (inConst, indent) =>
                  'WidgetStateProperty.resolveWith((states) => '
                  'states.contains(WidgetState.selected) ? '
                  'IconThemeData(color: ${_color(nav.foreground!).code(false, indent)}) : null)',
              false,
            ),
    ),
  ]);

  final rail = c.surfaces[SurfaceKind.navigationRail]!;
  add('navigationRailTheme', SurfaceKind.navigationRail, [
    ('indicatorShape', _indicatorShapeExpr(rail)),
    ('backgroundColor', col(rail.background)),
    ('indicatorColor', col(rail.accent)),
    (
      'selectedIconTheme',
      rail.foreground == null
          ? null
          : _call('IconThemeData', [('color', _color(rail.foreground!))]),
    ),
    ('selectedLabelTextStyle', _textRef(rail.titleStyle, _onSurface)),
    ('unselectedLabelTextStyle', _textRef(rail.titleStyle, _variant)),
  ]);

  final tile = c.surfaces[SurfaceKind.listTile]!;
  add('listTileTheme', SurfaceKind.listTile, [
    ('titleTextStyle', _textRef(tile.titleStyle)),
    ('subtitleTextStyle', _textRef(tile.bodyStyle, _variant)),
    ('iconColor', col(tile.foreground)),
    ('selectedTileColor', col(tile.accent)),
    (
      'shape',
      tile.radius == null
          ? null
          : _call('RoundedRectangleBorder', [
              (
                'borderRadius',
                _call('BorderRadius.all', [
                  (
                    null,
                    _call('Radius.circular', [(null, _num(tile.radius!))]),
                  ),
                ]),
              ),
            ]),
    ),
  ]);

  final div = c.surfaces[SurfaceKind.divider]!;
  add('dividerTheme', SurfaceKind.divider, [
    ('color', col(div.borderColor)),
    ('thickness', n(div.borderWidth)),
  ]);

  final fab = c.surfaces[SurfaceKind.fab]!;
  add('floatingActionButtonTheme', SurfaceKind.fab, [
    ('backgroundColor', col(fab.background)),
    ('foregroundColor', col(fab.foreground)),
    ('elevation', n(fab.elevation)),
    ('focusElevation', n(fab.elevation)),
    ('hoverElevation', fab.elevation == null ? null : _num(fab.elevation! + 1)),
    ('highlightElevation', n(fab.elevation)),
    ('shape', _roundedShape(SurfaceKind.fab, fab)),
    ('extendedTextStyle', _textRef(fab.titleStyle)),
  ]);

  _addPoint3(c, out, add, col, n);
  _addControls(c, out, add, col, n);

  final snack = c.surfaces[SurfaceKind.snackBar]!;
  final snackShape = _roundedShape(SurfaceKind.snackBar, snack);
  add('snackBarTheme', SurfaceKind.snackBar, [
    ('backgroundColor', col(snack.background)),
    (
      'contentTextStyle',
      _textRef(
        snack.bodyStyle ??
            (snack.foreground == null ? null : TextRole.bodyMedium),
        snack.foreground,
      ),
    ),
    ('actionTextColor', col(snack.accent)),
    ('elevation', n(snack.elevation)),
    ('shape', snackShape),
    ('behavior', snackShape == null ? null : _lit('SnackBarBehavior.floating')),
  ]);

  return out;
}

// --- Tooltip, tabs, chip, badge, menu ------------------------------------------

/// Free code expression (closures and the like), never const.
_Expr _code(String Function(String indent) f) => _Expr((_, i) => f(i), false);

String _c(_Expr e, String indent) => e.code(false, indent);

void _addPoint3(
  ThemeConfig c,
  List<(String?, _Expr)> out,
  void Function(String, SurfaceKind, List<(String?, _Expr?)>, [String?]) add,
  _Expr? Function(ColorRef?) col,
  _Expr? Function(double?) n,
) {
  // Tooltip
  final tip = c.surfaces[SurfaceKind.tooltip]!;
  final tipWidth = tip.borderWidth ?? (tip.borderColor != null ? 1.0 : 0.0);
  add('tooltipTheme', SurfaceKind.tooltip, [
    (
      'decoration',
      _call('BoxDecoration', [
        (
          'color',
          _color(tip.background ?? const RoleColor(SchemeRole.inverseSurface)),
        ),
        if (tipWidth != 0)
          (
            'border',
            _call('Border.all', [
              (
                'color',
                _color(
                  tip.borderColor ?? const RoleColor(SchemeRole.outlineVariant),
                ),
              ),
              ('width', _num(tipWidth)),
            ]),
          ),
        (
          'borderRadius',
          _call('BorderRadius.all', [
            (
              null,
              _call('Radius.circular', [
                (null, _num(tip.radius ?? SurfaceKind.tooltip.m3Radius)),
              ]),
            ),
          ]),
        ),
        if (tip.shadow != null)
          ('boxShadow', _shadows(tip.shadow!, tip.shadowColor)),
      ]),
    ),
    (
      'textStyle',
      _textRef(
        tip.bodyStyle ?? TextRole.bodySmall,
        tip.foreground ?? const RoleColor(SchemeRole.onInverseSurface),
      ),
    ),
    (
      'padding',
      tip.paddingH == null && tip.paddingV == null
          ? null
          : _call('EdgeInsets.symmetric', [
              ('horizontal', _num(tip.paddingH ?? 8)),
              ('vertical', _num(tip.paddingV ?? 4)),
            ]),
    ),
  ]);

  // TabBar
  final tab = c.surfaces[SurfaceKind.tabBar]!;
  add('tabBarTheme', SurfaceKind.tabBar, [
    (
      'indicator',
      tab.background != null
          ? _call('ShapeDecoration', [
              ('color', _color(tab.background!)),
              (
                'shape',
                _call('RoundedRectangleBorder', [
                  (
                    'borderRadius',
                    _call('BorderRadius.all', [
                      (
                        null,
                        _call('Radius.circular', [
                          (null, _num(tab.innerRadius ?? 0)),
                        ]),
                      ),
                    ]),
                  ),
                  (
                    'side',
                    tab.accent == null
                        ? _lit('BorderSide.none')
                        : _call('BorderSide', [
                            ('color', _color(tab.accent!)),
                            ('width', _num(tab.borderWidth ?? 2)),
                          ]),
                  ),
                ]),
              ),
            ])
          : tab.accent == null && tab.borderWidth == null
          ? null
          : _call('UnderlineTabIndicator', [
              (
                'borderSide',
                _call('BorderSide', [
                  (
                    'color',
                    _color(tab.accent ?? const RoleColor(SchemeRole.primary)),
                  ),
                  ('width', _num(tab.borderWidth ?? 2)),
                ]),
              ),
            ]),
    ),
    ('indicatorSize', _lit('TabBarIndicatorSize.tab')),
    (
      'labelColor',
      tab.background != null
          ? col(tab.selectedForeground ?? tab.accent)
          : col(tab.accent),
    ),
    ('unselectedLabelColor', col(tab.foreground)),
    ('labelStyle', _textRef(tab.titleStyle)),
    ('unselectedLabelStyle', _textRef(tab.bodyStyle)),
    ('dividerColor', col(tab.borderColor)),
    ('dividerHeight', tab.borderColor == null ? null : _num(1)),
    (
      'labelPadding',
      tab.paddingH == null
          ? null
          : _call('EdgeInsets.symmetric', [
              ('horizontal', _num(tab.paddingH!)),
            ]),
    ),
  ]);

  // Chip
  final chip = c.surfaces[SurfaceKind.chip]!;
  final label = _textRef(chip.bodyStyle ?? TextRole.labelLarge)!;
  add('chipTheme', SurfaceKind.chip, [
    (
      'color',
      chip.background == null && chip.accent == null
          ? null
          : _code((i) {
              final bg = chip.background == null
                  ? 'null'
                  : _c(_color(chip.background!), i);
              final sel = chip.accent == null
                  ? bg
                  : _c(_color(chip.accent!), i);
              return 'WidgetStateProperty.resolveWith((states) {\n'
                  '$i  if (states.contains(WidgetState.disabled)) return null;\n'
                  '$i  if (states.contains(WidgetState.selected)) return $sel;\n'
                  '$i  return $bg;\n'
                  '$i})';
            }),
    ),
    (
      'labelStyle',
      chip.foreground == null &&
              chip.selectedForeground == null &&
              chip.bodyStyle == null
          ? null
          : _code((i) {
              if (chip.foreground == null && chip.selectedForeground == null) {
                return _c(label, i);
              }
              final fg = chip.foreground == null
                  ? 'colorScheme.onSurfaceVariant'
                  : _c(_color(chip.foreground!), i);
              final sel = chip.selectedForeground == null
                  ? fg
                  : _c(_color(chip.selectedForeground!), i);
              // WidgetStateColor inside the TextStyle: the chip resolves it per
              // state (a WidgetStateTextStyle would be lost in the merge).
              return '${_c(label, i)}?.copyWith(color: WidgetStateColor.resolveWith((states) => '
                  'states.contains(WidgetState.selected) ? $sel : $fg))';
            }),
    ),
    ('checkmarkColor', col(chip.selectedForeground)),
    (
      'iconTheme',
      chip.foreground == null
          ? null
          : _call('IconThemeData', [
              ('color', _color(chip.foreground!)),
              ('size', _num(18)),
            ]),
    ),
    ('side', chip.hasBorder ? _side(chip) : null),
    (
      'shape',
      chip.radius == null
          ? null
          : _call('RoundedRectangleBorder', [
              (
                'borderRadius',
                _call('BorderRadius.all', [
                  (
                    null,
                    _call('Radius.circular', [(null, _num(chip.radius!))]),
                  ),
                ]),
              ),
            ]),
    ),
    (
      'padding',
      chip.paddingH == null && chip.paddingV == null
          ? null
          : _call('EdgeInsets.symmetric', [
              ('horizontal', _num(chip.paddingH ?? 8)),
              ('vertical', _num(chip.paddingV ?? 4)),
            ]),
    ),
  ]);

  // Badge
  final badge = c.surfaces[SurfaceKind.badge]!;
  add('badgeTheme', SurfaceKind.badge, [
    ('backgroundColor', col(badge.background)),
    ('textColor', col(badge.foreground)),
    ('textStyle', _textRef(badge.bodyStyle)),
    ('largeSize', n(badge.height)),
    (
      'padding',
      badge.paddingH == null
          ? null
          : _call('EdgeInsets.symmetric', [
              ('horizontal', _num(badge.paddingH!)),
            ]),
    ),
  ]);

  // Menu: MenuStyle shared by MenuTheme and DropdownMenuTheme.
  final m = c.surfaces[SurfaceKind.menu]!;
  final hasShape = m.radius != null || m.hasBorder;
  final menuStyleArgs = <(String?, _Expr)>[
    if (m.background != null) ...[
      (
        'backgroundColor',
        _call('WidgetStatePropertyAll', [(null, _color(m.background!))]),
      ),
      (
        'surfaceTintColor',
        _lit(
          'const WidgetStatePropertyAll(Colors.transparent)',
          isConst: false,
        ),
      ),
    ],
    if (m.elevation != null)
      (
        'elevation',
        _call('WidgetStatePropertyAll', [(null, _num(m.elevation!))]),
      ),
    if (hasShape)
      (
        'shape',
        _call('WidgetStatePropertyAll', [
          (null, _roundedShape(SurfaceKind.menu, m)!),
        ]),
      ),
    if (m.paddingH != null)
      (
        'padding',
        _call('WidgetStatePropertyAll', [
          (null, _call('EdgeInsets.all', [(null, _num(m.paddingH!))])),
        ]),
      ),
  ];
  if (menuStyleArgs.isNotEmpty) {
    final menuStyle = _call('MenuStyle', menuStyleArgs, multiline: true);
    out.add((
      'menuTheme',
      _call('MenuThemeData', [('style', menuStyle)], multiline: true),
    ));
    out.add((
      'dropdownMenuTheme',
      _call('DropdownMenuThemeData', [
        ('menuStyle', menuStyle),
      ], multiline: true),
    ));
  }
  final itemArgs = <(String?, _Expr)>[
    if (m.accent != null) ...[
      (
        'backgroundColor',
        _code(
          (i) =>
              'WidgetStateProperty.resolveWith((states) => '
              'states.contains(WidgetState.hovered) || '
              'states.contains(WidgetState.focused) || '
              'states.contains(WidgetState.pressed) '
              '? ${_c(_color(m.accent!), i)} : Colors.transparent)',
        ),
      ),
      (
        'overlayColor',
        _lit(
          'const WidgetStatePropertyAll(Colors.transparent)',
          isConst: false,
        ),
      ),
    ],
    if (m.foreground != null) ...[
      (
        'foregroundColor',
        _call('WidgetStatePropertyAll', [(null, _color(m.foreground!))]),
      ),
      (
        'iconColor',
        _call('WidgetStatePropertyAll', [(null, _color(m.foreground!))]),
      ),
    ],
    if (m.bodyStyle != null)
      (
        'textStyle',
        _call('WidgetStatePropertyAll', [
          (null, _textRef(m.bodyStyle)!),
        ], isConstructor: false),
      ),
    if (m.innerRadius != null)
      (
        'shape',
        _call('WidgetStatePropertyAll', [
          (
            null,
            _call('RoundedRectangleBorder', [
              (
                'borderRadius',
                _call('BorderRadius.all', [
                  (
                    null,
                    _call('Radius.circular', [(null, _num(m.innerRadius!))]),
                  ),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    if (m.paddingV != null)
      (
        'padding',
        _call('WidgetStatePropertyAll', [
          (null, _call('EdgeInsets.all', [(null, _num(m.paddingV!))])),
        ]),
      ),
  ];
  if (itemArgs.isNotEmpty) {
    out.add((
      'menuButtonTheme',
      _call('MenuButtonThemeData', [
        ('style', _call('ButtonStyle', itemArgs, multiline: true)),
      ], multiline: true),
    ));
  }
  add('popupMenuTheme', SurfaceKind.menu, [
    ('color', col(m.background)),
    (
      'surfaceTintColor',
      m.background == null ? null : _lit('Colors.transparent'),
    ),
    ('elevation', n(m.elevation)),
    ('shape', _roundedShape(SurfaceKind.menu, m)),
    (
      'menuPadding',
      m.paddingH == null
          ? null
          : _call('EdgeInsets.all', [(null, _num(m.paddingH!))]),
    ),
    (
      'labelTextStyle',
      m.bodyStyle == null && m.foreground == null
          ? null
          : _call('WidgetStatePropertyAll', [
              (null, _textRef(m.bodyStyle, m.foreground)!),
            ], isConstructor: false),
    ),
  ], 'PopupMenuThemeData');
}

// --- Checkbox, radio, switch, slider --------------------------------------------

bool _hardShadowUsed(ThemeConfig c) =>
    c.surfaces.values.any((s) => !s.isEmpty && s.hasShapeShadow) ||
    (!c.textField.isEmpty &&
        c.textField.states.values.any(
          (s) => s.shadow != null && s.shadow != ShadowToken.none,
        ));

bool _sliderShapesUsed(ThemeConfig c) {
  final s = c.surfaces[SurfaceKind.slider]!;
  return s.accent != null ||
      s.foreground != null ||
      s.borderColor != null ||
      s.shadow != null ||
      s.radius != null;
}

/// `WidgetStateProperty.resolveWith((states) => _dim(<on or off>, states))`.
_Expr _onOff(ColorRef? on, ColorRef? off) => _code((i) {
  final a = on == null ? 'null' : _c(_color(on), i);
  final b = off == null ? 'null' : _c(_color(off), i);
  return a == b
      ? 'WidgetStateProperty.resolveWith((states) => _dim($a, states))'
      : 'WidgetStateProperty.resolveWith((states) => '
            '_dim(states.contains(WidgetState.selected) ? $a : $b, states))';
});

void _addControls(
  ThemeConfig c,
  List<(String?, _Expr)> out,
  void Function(String, SurfaceKind, List<(String?, _Expr?)>, [String?]) add,
  _Expr? Function(ColorRef?) col,
  _Expr? Function(double?) n,
) {
  final noOverlay = _lit(
    'const WidgetStatePropertyAll(Colors.transparent)',
    isConst: false,
  );

  final cb = c.surfaces[SurfaceKind.checkbox]!;
  add('checkboxTheme', SurfaceKind.checkbox, [
    (
      'fillColor',
      cb.accent == null && cb.background == null
          ? null
          : _onOff(cb.accent, cb.background),
    ),
    (
      'checkColor',
      cb.selectedForeground == null
          ? null
          : _onOff(cb.selectedForeground, cb.selectedForeground),
    ),
    (
      'side',
      cb.borderColor == null && cb.borderWidth == null
          ? null
          : _code((i) {
              final color = _c(
                _color(cb.borderColor ?? const RoleColor(SchemeRole.outline)),
                i,
              );
              return 'WidgetStateBorderSide.resolveWith((states) => '
                  'states.contains(WidgetState.selected) '
                  '? const BorderSide(color: Colors.transparent, width: 0) '
                  ': BorderSide(color: _dim($color, states)!, width: ${formatNum(cb.borderWidth ?? 1)}))';
            }),
    ),
    (
      'shape',
      cb.radius == null
          ? null
          : _call('RoundedRectangleBorder', [
              (
                'borderRadius',
                _call('BorderRadius.all', [
                  (null, _call('Radius.circular', [(null, _num(cb.radius!))])),
                ]),
              ),
            ]),
    ),
    ('overlayColor', noOverlay),
  ]);

  final radio = c.surfaces[SurfaceKind.radio]!;
  add('radioTheme', SurfaceKind.radio, [
    (
      'fillColor',
      radio.accent == null && radio.borderColor == null
          ? null
          : _onOff(radio.accent, radio.borderColor),
    ),
    (
      'backgroundColor',
      radio.background == null && radio.selectedForeground == null
          ? null
          : _onOff(
              radio.selectedForeground ?? radio.background,
              radio.background,
            ),
    ),
    ('overlayColor', noOverlay),
  ]);

  final sw = c.surfaces[SurfaceKind.switchControl]!;
  add('switchTheme', SurfaceKind.switchControl, [
    (
      'trackColor',
      sw.accent == null && sw.background == null
          ? null
          : _onOff(sw.accent, sw.background),
    ),
    (
      'thumbColor',
      sw.foreground == null
          ? null
          : _onOff(sw.selectedForeground ?? sw.foreground, sw.foreground),
    ),
    (
      'trackOutlineColor',
      sw.borderColor == null && sw.background == null
          ? null
          : _code((i) {
              final outline = sw.borderColor == null
                  ? 'Colors.transparent'
                  : _c(_color(sw.borderColor!), i);
              return 'WidgetStateProperty.resolveWith((states) => _dim($outline, states))';
            }),
    ),
    (
      'trackOutlineWidth',
      sw.borderWidth == null
          ? null
          : _call('WidgetStatePropertyAll', [(null, _num(sw.borderWidth!))]),
    ),
    (
      'thumbIcon',
      // Empty icon: the thumb stays the same size on or off.
      sw.foreground == null
          ? null
          : _lit('const WidgetStatePropertyAll(Icon(null))', isConst: false),
    ),
    ('overlayColor', noOverlay),
  ]);

  final sl = c.surfaces[SurfaceKind.slider]!;
  _Expr? dimmed(ColorRef? r) => r == null
      ? null
      : _code((i) => '_dim(${_c(_color(r), i)}, const {WidgetState.disabled})');
  _Expr? trackShape(String type) => sl.accent == null
      ? null
      : _call(type, [
          (
            'activeColors',
            _list([
              _color(sl.accent!),
              if (sl.accentEnd != null) _color(sl.accentEnd!),
            ]),
          ),
          if ((sl.trackBorderWidth ?? sl.borderWidth) case final w?
              when sl.borderColor != null && w > 0) ...[
            ('borderColor', _color(sl.borderColor!)),
            ('borderWidth', _num(w)),
          ],
          if (sl.innerRadius != null) ('cornerRadius', _num(sl.innerRadius!)),
        ]);
  _Expr? thumbShape(String type) =>
      sl.foreground == null &&
          sl.borderColor == null &&
          sl.shadow == null &&
          sl.radius == null
      ? null
      : _call(type, [
          ('radius', _num(sl.radius ?? SurfaceKind.slider.m3Radius)),
          (
            'color',
            _color(sl.foreground ?? const RoleColor(SchemeRole.primary)),
          ),
          if (sl.borderColor != null) ('borderColor', _color(sl.borderColor!)),
          if (sl.borderWidth != null && sl.borderWidth != 1)
            ('borderWidth', _num(sl.borderWidth!)),
          if (sl.innerRadius != null) ('cornerRadius', _num(sl.innerRadius!)),
          if (sl.shadow != null)
            ('shadows', _shadows(sl.shadow!, sl.shadowColor)),
        ]);
  add('sliderTheme', SurfaceKind.slider, [
    ('activeTrackColor', col(sl.accent)),
    ('inactiveTrackColor', col(sl.background)),
    ('disabledActiveTrackColor', dimmed(sl.accent)),
    ('disabledInactiveTrackColor', dimmed(sl.background)),
    ('trackHeight', n(sl.height)),
    ('thumbColor', col(sl.foreground)),
    ('trackShape', trackShape('GradientSliderTrackShape')),
    ('rangeTrackShape', trackShape('GradientRangeSliderTrackShape')),
    ('thumbShape', thumbShape('SoftSliderThumbShape')),
    ('rangeThumbShape', thumbShape('SoftRangeSliderThumbShape')),
    ('overlayColor', _lit('Colors.transparent')),
    ('tickMarkShape', _lit('SliderTickMarkShape.noTickMark')),
  ]);
}

// --- Text fields -------------------------------------------------------------

List<(String?, _Expr)> _inputStyleArgs(TextFieldConfig f) {
  final size = f.inputFontSize;
  final lh = f.inputLineHeight;
  final effectiveSize = size ?? TextFieldConfig.m3InputFontSize;
  return [
    if (size != null) ('fontSize', _num(size)),
    if (f.inputWeight != null)
      ('fontWeight', _lit('FontWeight.w${f.inputWeight!.value}')),
    if (lh != null)
      ('height', _num(double.parse((lh / effectiveSize).toStringAsFixed(4)))),
    if (f.inputLetterSpacing != null)
      ('letterSpacing', _num(f.inputLetterSpacing!)),
    if (f.inputColor != null) ('color', _color(f.inputColor!)),
  ];
}

/// `WidgetStateXxx.resolveWith((states) { if ... return ...; })` with the
/// states that differ from normal, in the same order as [fieldStateOrder].
///
/// resolveWith is used, not fromMap: some widgets (e.g. DropdownButton)
/// read the theme value directly, without resolving it per state, and the
/// fromMap variants throw in that case.
_Expr _stateMap(String type, _Expr Function(FieldStateKey k) value) {
  final normal = value(FieldStateKey.normal);
  final normalCode = normal.code(false, '');
  final n = fieldStatesToInclude((k) => value(k).code(false, '') != normalCode);
  return _Expr((inConst, indent) {
    final inner = '$indent  ';
    final lines = [
      for (final (k, s) in fieldStateOrder.take(n))
        '${inner}if (states.contains(WidgetState.${s.name})) '
            'return ${value(k).code(false, inner)};',
      '${inner}return ${normal.code(false, inner)};',
    ];
    return '$type.resolveWith((states) {\n${lines.join('\n')}\n$indent})';
  }, false);
}

_Expr _inputTheme(TextFieldConfig f) {
  final view = f.view;
  final filled = FieldStateKey.values.any((k) => view.fill(k) != null);
  final args = <(String?, _Expr)>[];

  if (f.dense != null) args.add(('isDense', _lit('${f.dense}')));
  if (f.hasPadding) {
    final p = fieldPadding(f);
    args.add((
      'contentPadding',
      _call('EdgeInsetsDirectional.fromSTEB', [
        (null, _num(p.start)),
        (null, _num(p.top)),
        (null, _num(p.end)),
        (null, _num(p.bottom)),
      ]),
    ));
  }
  if (filled) {
    args.add(('filled', _lit('true')));
    args.add((
      'fillColor',
      _stateMap('WidgetStateColor', (k) {
        final fill = view.fill(k);
        return fill == null ? _lit('Colors.transparent') : _color(fill);
      }),
    ));
    args.add(('hoverColor', _lit('Colors.transparent')));
  }
  if (f.customBorder) {
    final radius = f.radius ?? TextFieldConfig.m3Radius;
    args.add((
      'border',
      _stateMap('WidgetStateInputBorder', (k) {
        final width = view.borderWidth(k);
        final shadow = view.shadow(k);
        if (f.underline == true) {
          return _call('UnderlineInputBorder', [
            (
              'borderSide',
              width == 0
                  ? _lit('BorderSide.none')
                  : _call('BorderSide', [
                      ('color', _color(view.border(k))),
                      ('width', _num(width)),
                    ]),
            ),
          ]);
        }
        final hard = shadow != null && shadow.isHard;
        final soft =
            shadow != null && shadow != ShadowToken.none && !shadow.isHard;
        return _call(
          hard || soft ? 'HardShadowInputBorder' : 'OutlineInputBorder',
          [
            if (soft) ('shadows', _shadows(shadow)),
            if (hard) ...[
              (
                'shadowOffset',
                _call('Offset', [
                  (null, _num(shadow.hardOffset!)),
                  (null, _num(shadow.hardOffset!)),
                ]),
              ),
              (
                'shadowColor',
                _color(
                  view.shadowColor(k) ?? const RoleColor(SchemeRole.outline),
                ),
              ),
              if (shadow.hardSpread != 0)
                ('shadowSpread', _num(shadow.hardSpread)),
            ],
            (
              'borderRadius',
              _call('BorderRadius.all', [
                (null, _call('Radius.circular', [(null, _num(radius))])),
              ]),
            ),
            (
              'borderSide',
              width == 0
                  ? _lit('BorderSide.none')
                  : _call('BorderSide', [
                      ('color', _color(view.border(k))),
                      ('width', _num(width)),
                    ]),
            ),
          ],
        );
      }),
    ));
  }
  if (f.hasPlaceholder) {
    args.add((
      'hintStyle',
      _stateMap(
        'WidgetStateTextStyle',
        (k) => _call('TextStyle', [('color', _color(fieldPlaceholder(f, k)))]),
      ),
    ));
  }
  if (f.hasIconColor) {
    for (final name in ['prefixIconColor', 'suffixIconColor']) {
      args.add((
        name,
        _stateMap('WidgetStateColor', (k) => _color(fieldIcon(f, k))),
      ));
    }
  }
  if (f.iconBox != null) {
    for (final name in ['prefixIconConstraints', 'suffixIconConstraints']) {
      args.add((
        name,
        _call('BoxConstraints', [
          ('minWidth', _num(f.iconBox!)),
          ('minHeight', _num(f.iconBox!)),
        ]),
      ));
    }
  }
  _Expr subtext(ColorRef? color) => _call('TextStyle', [
    if (f.helperFontSize != null) ('fontSize', _num(f.helperFontSize!)),
    if (f.helperWeight != null)
      ('fontWeight', _lit('FontWeight.w${f.helperWeight!.value}')),
    if (f.helperLetterSpacing != null)
      ('letterSpacing', _num(f.helperLetterSpacing!)),
    if (color != null) ('color', _color(color)),
  ]);
  if (f.hasHelperStyle) args.add(('helperStyle', subtext(f.helperColor)));
  if (f.hasErrorStyle) args.add(('errorStyle', subtext(f.errorColor)));

  return _call('InputDecorationThemeData', args, multiline: true);
}

_Expr _shape(double radius) => _call('RoundedRectangleBorder', [
  (
    'borderRadius',
    _call('BorderRadius.all', [
      (null, _call('Radius.circular', [(null, _num(radius))])),
    ]),
  ),
]);

// --- Mini expression generator with `const` handling ------------------------

/// A Dart expression. [code] receives `inConst` (already inside a const
/// context: no redundant `const`) and the current indentation.
class _Expr {
  const _Expr(this.code, this.isConst);

  final String Function(bool inConst, String indent) code;
  final bool isConst;
}

_Expr _lit(String s, {bool isConst = true}) => _Expr((_, _) => s, isConst);

_Expr _num(double v) => _lit(formatNum(v));

_Expr _color(ColorRef r) =>
    _Expr((inConst, _) => r.toDart(inConst: inConst), r.isConst);

/// Constructor or method call. If all arguments are constant and
/// [isConstructor] is true, the expression becomes `const`.
_Expr _call(
  String name,
  List<(String?, _Expr)> args, {
  bool multiline = false,
  bool isConstructor = true,
}) {
  final allConst = isConstructor && args.every((a) => a.$2.isConst);
  return _Expr((inConst, indent) {
    final childConst = allConst || inConst;
    final prefix = allConst && !inConst ? 'const ' : '';
    String arg((String?, _Expr) a, String ind) {
      final value = a.$2.code(childConst, ind);
      return a.$1 == null ? value : '${a.$1}: $value';
    }

    if (!multiline || args.isEmpty) {
      return '$prefix$name(${args.map((a) => arg(a, indent)).join(', ')})';
    }
    final inner = '$indent  ';
    final lines = args.map((a) => '$inner${arg(a, inner)},').join('\n');
    return '$prefix$name(\n$lines\n$indent)';
  }, allConst);
}

_Expr _list(List<_Expr> items) {
  final allConst = items.every((i) => i.isConst);
  return _Expr((inConst, indent) {
    final prefix = allConst && !inConst ? 'const ' : '';
    final parts = items
        .map((i) => i.code(allConst || inConst, indent))
        .join(', ');
    return '$prefix[$parts]';
  }, allConst);
}

/// Splits [text] into lines of at most [width] characters.
List<String> _wrap(String text, int width) {
  final lines = <String>[];
  var line = '';
  for (final word in text.split(' ')) {
    if (line.isNotEmpty && line.length + 1 + word.length > width) {
      lines.add(line);
      line = word;
    } else {
      line = line.isEmpty ? word : '$line $word';
    }
  }
  if (line.isNotEmpty) lines.add(line);
  return lines;
}
