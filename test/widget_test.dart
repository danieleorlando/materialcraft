import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:materialcraft_app/export/button_skin_source.dart';
import 'package:materialcraft_app/export/dart_exporter.dart';
import 'package:materialcraft_app/export/usage_notes.dart';
import 'package:materialcraft_app/editor/export_dialog.dart';
import 'package:materialcraft_app/editor/editor_controller.dart';
import 'package:materialcraft_app/editor/editor_page.dart';
import 'package:materialcraft_app/main.dart';
import 'package:materialcraft_app/model/boardui_tokens.dart';
import 'package:materialcraft_app/model/color_ref.dart';
import 'package:materialcraft_app/model/presets.dart';
import 'package:materialcraft_app/model/shadow_token.dart';
import 'package:materialcraft_app/model/surface_config.dart';
import 'package:materialcraft_app/model/text_field_config.dart';
import 'package:materialcraft_app/model/theme_builder.dart';
import 'package:materialcraft_app/model/theme_config.dart';
import 'package:materialcraft_app/model/theme_layers.dart';
import 'package:materialcraft_app/model/theme_json.dart';
import 'package:materialcraft_app/editor/new_theme_wizard.dart';
import 'package:materialcraft_app/editor/preview_showcases.dart';
import 'dart:convert';
import 'package:materialcraft_app/model/boardui_token_defs.dart';
import 'package:materialcraft_app/model/color_math.dart';
import 'package:materialcraft_app/model/color_sets.dart';
import 'package:materialcraft_app/model/shadcn_tokens.dart';
import 'package:materialcraft_app/model/presets_shadcn.dart';
import 'package:materialcraft_app/model/shadcn_styles.dart';
import 'package:materialcraft_app/model/material_colors.dart';
import 'package:materialcraft_app/model/global_tokens.dart';
import 'package:materialcraft_app/model/typography_config.dart';
import 'package:materialcraft/materialcraft.dart';
import 'package:materialcraft_app/model/neobrutalism_tokens.dart';
import 'package:materialcraft_app/model/presets_neobrutalism.dart';

/// BoardUI preset without fonts: in tests google_fonts can't download Inter.
ThemeConfig boardUiNoFont() {
  final c = ThemeConfig();
  ThemePreset.boardUI.applyTo(c);
  c.fontFamily = null;
  return c;
}

Widget host(ThemeData theme, Widget child) => MaterialApp(
  theme: theme,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  _layerTests();
  _colorTests();
  _projectTests();
  _shadcnFoundationTests();
  _shadcnPresetTests();
  _shadcnVariantTests();
  testWidgets('editor starts and shows the sections', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialCraftApp());
    expect(
      find.textContaining('MaterialCraft', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Export code'), findsOneWidget);
    expect(find.text('Filled button'), findsOneWidget);

    await tester.tap(find.text('Colors').first);
    await tester.pumpAndSettle();
    expect(find.text('Custom color'), findsOneWidget);
    await tester.tap(find.text('Global properties').first);
    await tester.pumpAndSettle();
    expect(find.text('Pill-shaped buttons'), findsOneWidget);
  });

  testWidgets('About: author, services and links', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialCraftApp());
    await tester.tap(find.text('by Daniele Orlando'));
    await tester.pumpAndSettle();
    expect(find.text('Made by Daniele Orlando'), findsOneWidget);
    expect(find.text('Work with me'), findsOneWidget);
    expect(find.text('LinkedIn'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('export without overrides returns the base theme', () {
    final code = exportDart(ThemeConfig());
    expect(code, contains('abstract final class AppTheme'));
    // The extension is always there, so context.buttonStyle(...) compiles with
    // any exported theme.
    // Even without overrides, danger has a style (error colors).
    expect(
      code,
      contains(
        '(AppButtonKind.danger, AppButtonSize.medium): FilledButton.styleFrom(',
      ),
    );
    expect(code, contains('backgroundColor: colorScheme.error'));
    expect(code, contains('class AppButtonStyles'));
    expect(code, isNot(contains('class ButtonSkin')));
    expect(code, isNot(contains('isDark')));
  });

  test('simple overrides only use styleFrom', () {
    final c = ThemeConfig()..variant = DynamicSchemeVariant.vibrant;
    c.buttons[ButtonKind.filled]!
      ..normal.fill = const RoleColor(SchemeRole.tertiary)
      ..radius = 8
      ..fontWeight = FontWeight.w700;
    c.buttons[ButtonKind.outlined]!
      ..borderWidth = 2
      ..normal.border = const CustomColor(Color(0xFFFF0000));

    final code = exportDart(c);
    expect(code, contains('DynamicSchemeVariant.vibrant'));
    expect(code, contains('backgroundColor: colorScheme.tertiary'));
    expect(code, contains('Radius.circular(8)'));
    expect(code, contains('fontWeight: FontWeight.w700'));
    expect(
      code,
      contains('side: const BorderSide(color: Color(0xFFFF0000), width: 2)'),
    );
    expect(code, isNot(contains('ButtonSkin')));

    final theme = buildTheme(c, Brightness.light);
    final bg = theme.filledButtonTheme.style!.backgroundColor!.resolve({});
    expect(bg, theme.colorScheme.tertiary);
  });

  test('exported sources are aligned with the runtime', () {
    String strip(String path) => File(path).readAsStringSync().replaceFirst(
      "import 'package:flutter/material.dart';\n\n",
      '',
    );
    expect(
      buttonSkinSource,
      strip('packages/materialcraft/lib/src/button_skin.dart'),
      reason: 'Run tool/gen_skin_source.sh',
    );
    expect(
      appButtonStylesSource,
      strip('packages/materialcraft/lib/src/app_button_styles.dart'),
      reason: 'Run tool/gen_skin_source.sh',
    );
    expect(
      sliderShapesSource,
      strip('packages/materialcraft/lib/src/slider_shapes.dart'),
      reason: 'Run tool/gen_skin_source.sh',
    );
    expect(
      hardShadowBorderSource,
      strip('packages/materialcraft/lib/src/hard_shadow_border.dart'),
      reason: 'Run tool/gen_skin_source.sh',
    );
    expect(
      appSwitchSource,
      strip('packages/materialcraft/lib/src/app_switch.dart'),
      reason: 'Run tool/gen_skin_source.sh',
    );
  });

  test(
    'package export: imports materialcraft and does not include the runtime',
    () {
      for (final p in ThemePreset.all) {
        final c = ThemeConfig();
        p.apply(c);
        final code = exportDart(c, usePackage: true);
        expect(
          code,
          contains("import 'package:materialcraft/materialcraft.dart';"),
          reason: p.name,
        );
        for (final cls in [
          'class ButtonSkin ',
          'class AppButtonStyles ',
          'class AppSwitch ',
          'class HardShadowBorder ',
          'class SoftSliderThumbShape ',
        ]) {
          expect(code, isNot(contains(cls)), reason: '${p.name}: $cls');
        }
        // The theme body is identical to the standalone one.
        final standalone = exportDart(c);
        final theme = RegExp(r'abstract final class AppTheme \{[\s\S]*?\n\}\n');
        expect(
          theme.firstMatch(code)!.group(0),
          theme.firstMatch(standalone)!.group(0),
          reason: p.name,
        );
      }
      expect(
        exportDart(ThemeConfig()),
        isNot(contains('package:materialcraft')),
      );
      final notes = usageNotes(ThemeConfig(), usePackage: true);
      expect(notes.first.id, 'package');
      expect(notes.first.required, isTrue);
      expect(
        usageNotes(ThemeConfig()).map((n) => n.id),
        isNot(contains('package')),
      );
      // AppSwitch comes from the package, not from the exported file.
      expect(
        switchNote(usePackage: true).body,
        contains('materialcraft package'),
      );
      expect(switchNote().body, contains('included in app_theme.dart'));
    },
  );

  test('CSS shadows converted to the equivalent Flutter blur', () {
    // CSS sigma = blur / 2; Flutter sigma = r * 0.57735 + 0.5.
    expect(const CssShadow(0, 1, 2, 0, .05).flutterBlur, closeTo(0.866, 1e-3));
    expect(const CssShadow(0, 1, 0, 0, .05).flutterBlur, 0);
    expect(
      const CssShadow(0, 10, 15, -3, .1).flutterBlur,
      closeTo(12.124, 1e-3),
    );
  });

  group('preset BoardUI', () {
    test('export: gradients, states, light/dark, ButtonSkin included', () {
      final c = ThemeConfig();
      ThemePreset.boardUI.applyTo(c);
      final code = exportDart(c);
      expect(code, contains("fontFamily: 'Inter'"));
      expect(code, contains('final isDark = brightness == Brightness.dark;'));
      expect(
        code,
        contains('colors: const [Color(0xFF2B7FFF), Color(0xFF155DFC)]'),
      );
      expect(code, contains('pressScale: 0.98'));
      expect(code, contains('class ButtonSkin {'));
      expect(
        code,
        contains('materialTapTargetSize: MaterialTapTargetSize.shrinkWrap'),
      );

      ThemePreset.material3.applyTo(c);
      expect(c.isDefault, isTrue);
    });

    test('per-state colors of the primary', () {
      final c = boardUiNoFont();
      final cs = buildColorScheme(c, Brightness.light);
      final skin = buildSkin(
        ButtonKind.filled,
        c.buttons[ButtonKind.filled]!,
        cs,
      );
      final blue = tailwindPalette['blue']!;
      final neutral = tailwindPalette['neutral']!;
      expect(skin.resolve({}).colors, [blue[500], blue[600]]);
      expect(skin.resolve({WidgetState.hovered}).colors, [
        blue[400],
        blue[500],
      ]);
      expect(skin.resolve({WidgetState.hovered, WidgetState.pressed}).colors, [
        blue[600],
        blue[700],
      ]);
      expect(skin.resolve({WidgetState.disabled}).colors, [
        neutral[200],
        neutral[300],
      ]);
      expect(skin.resolve({WidgetState.disabled}).foreground, neutral[400]);
      expect(skin.resolve({WidgetState.disabled}).shadows, isEmpty);
      // Focus doesn't change color: there's the ring.
      expect(skin.resolve({WidgetState.focused}).colors, [
        blue[500],
        blue[600],
      ]);
    });

    test('dark mode uses the dark tokens', () {
      final c = boardUiNoFont();
      final cs = buildColorScheme(c, Brightness.dark);
      final skin = buildSkin(
        ButtonKind.outlined,
        c.buttons[ButtonKind.outlined]!,
        cs,
      );
      final neutral = tailwindPalette['neutral']!;
      expect(skin.resolve({}).colors, [neutral[800]]);
      expect(skin.resolve({WidgetState.hovered}).colors, [
        neutral[700]!.withValues(alpha: 0.6),
      ]);
      expect(cs.surface, boardTokens['background-full']!.dark);
    });

    testWidgets('metrics: height 36, the border adds 2px', (tester) async {
      final theme = buildTheme(boardUiNoFont(), Brightness.light);
      await tester.pumpWidget(
        host(
          theme,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                key: const Key('p'),
                onPressed: () {},
                child: const Text('Save'),
              ),
              OutlinedButton(
                key: const Key('s'),
                onPressed: () {},
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );
      final primary = tester.getSize(find.byKey(const Key('p')));
      final secondary = tester.getSize(find.byKey(const Key('s')));
      expect(primary.height, 36);
      expect(secondary.height, 36);
      expect(secondary.width, primary.width + 2);
    });

    testWidgets('press: scale 0.98 and no rendering errors', (tester) async {
      final theme = buildTheme(boardUiNoFont(), Brightness.light);
      await tester.pumpWidget(
        host(theme, FilledButton(onPressed: () {}, child: const Text('Save'))),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(FilledButton)),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        0.98,
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keyboard focus shows the ring', (tester) async {
      final theme = buildTheme(boardUiNoFont(), Brightness.light);
      await tester.pumpWidget(
        host(theme, FilledButton(onPressed: () {}, child: const Text('Save'))),
      );
      Finder ring() => find.descendant(
        of: find.byType(FilledButton),
        matching: find.byType(Positioned),
      );
      expect(ring(), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(ring(), findsNWidgets(2)); // offset bianco + ring accent-500
      expect(tester.takeException(), isNull);
    });
  });

  group('text field BoardUI', () {
    final neutral = tailwindPalette['neutral']!;
    final red = tailwindPalette['red']!;

    InputDecorationThemeData input(Brightness b) =>
        buildTheme(boardUiNoFont(), b).inputDecorationTheme;

    testWidgets('metrics: 36px, text at 12px, icon in a 32 box', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          buildTheme(boardUiNoFont(), Brightness.light),
          const SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: Key('a'),
                  decoration: InputDecoration(hintText: 'Email'),
                ),
                TextField(
                  key: Key('b'),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      final a = find.byKey(const Key('a'));
      final b = find.byKey(const Key('b'));
      expect(tester.getSize(a).height, 36);
      expect(tester.getSize(b).height, 36);
      expect(
        (tester.getTopLeft(find.text('Email')) - tester.getTopLeft(a)).dx,
        12,
      );
      expect(tester.getSize(find.text('Email')).height, 20); // Inter 14/20
      expect(tester.takeException(), isNull);
    });

    test('fill per state (light)', () {
      final fill = input(Brightness.light).fillColor! as WidgetStateColor;
      expect(fill.resolve({}), neutral[200]);
      expect(fill.resolve({WidgetState.hovered}), neutral[200]);
      expect(fill.resolve({WidgetState.disabled}), neutral[100]);
      expect(fill.resolve({WidgetState.error, WidgetState.focused}), red[100]);
      expect(input(Brightness.light).hoverColor, Colors.transparent);
    });

    test('inset 2px ring: transparent, hover, focus; error without ring', () {
      final border = input(Brightness.light).border! as WidgetStateInputBorder;
      BorderSide side(Set<WidgetState> s) => border.resolve(s).borderSide;
      expect(side({}).color, const Color(0x00000000));
      expect(side({}).width, 2);
      expect(side({WidgetState.hovered}).color, neutral[300]);
      expect(
        side({WidgetState.focused, WidgetState.hovered}).color,
        neutral[400],
      );
      expect(
        side({WidgetState.error, WidgetState.focused}).color,
        const Color(0x00000000),
      );
      expect(
        (border.resolve({}) as OutlineInputBorder).borderRadius,
        BorderRadius.circular(10),
      );
    });

    test('placeholder: becomes text-primary on focus, red on error', () {
      final hint = input(Brightness.light).hintStyle! as WidgetStateTextStyle;
      expect(hint.resolve({}).color, neutral[400]);
      expect(hint.resolve({WidgetState.focused}).color, neutral[950]);
      expect(hint.resolve({WidgetState.error}).color, red[400]);
    });

    test('dark mode', () {
      final fill = input(Brightness.dark).fillColor! as WidgetStateColor;
      expect(fill.resolve({}), neutral[800]);
      expect(
        fill.resolve({WidgetState.error}),
        red[950]!.withValues(alpha: 0.6),
      );
    });

    test('export', () {
      final c = ThemeConfig();
      ThemePreset.boardUI.applyTo(c);
      final code = exportDart(c);
      expect(code, contains('inputDecorationTheme: InputDecorationThemeData('));
      expect(
        code,
        contains('border: WidgetStateInputBorder.resolveWith((states) {'),
      );
      expect(code, contains('bodyLarge: base.textTheme.bodyLarge?.copyWith('));
      expect(code, contains('textTheme: inputTextTheme'));
      expect(code, contains('textSelectionTheme: TextSelectionThemeData('));
    });

    test('an unmodified field does not generate InputDecorationTheme', () {
      final c = ThemeConfig();
      expect(c.textField.isEmpty, isTrue);
      expect(exportDart(c), isNot(contains('inputDecorationTheme')));
      c.textField.states[FieldStateKey.normal]!.fill = const CustomColor(
        Color(0xFFEEEEEE),
      );
      expect(exportDart(c), contains('inputDecorationTheme'));
    });
  });

  testWidgets('animated M3 ⇄ BoardUI transition without errors', (
    tester,
  ) async {
    // Regression: "Failed to interpolate TextStyles with different inherit
    // values" when the preview theme changed.
    final m3 = buildTheme(ThemeConfig(), Brightness.light);
    final board = buildTheme(boardUiNoFont(), Brightness.light);
    Widget app(ThemeData t) => MaterialApp(
      home: AnimatedTheme(
        data: t,
        duration: const Duration(milliseconds: 150),
        child: Scaffold(
          body: Wrap(
            children: [
              ElevatedButton(onPressed: () {}, child: const Text('a')),
              FilledButton(onPressed: () {}, child: const Text('b')),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('c'),
              ),
              TextButton(onPressed: () {}, child: const Text('d')),
              const SizedBox(
                width: 200,
                child: TextField(
                  decoration: InputDecoration(hintText: 'e', helperText: 'f'),
                ),
              ),
              // Regression: DropdownButton reads
              // inputDecorationTheme.border.isOutline without resolving it.
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<int>(
                  initialValue: 1,
                  items: const [DropdownMenuItem(value: 1, child: Text('one'))],
                  onChanged: (_) {},
                ),
              ),
              const DropdownMenu<int>(
                dropdownMenuEntries: [
                  DropdownMenuEntry(value: 1, label: 'one'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpWidget(app(m3));
    for (final t in [board, m3, board]) {
      await tester.pumpWidget(app(t));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 30));
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('animated font change (Roboto ⇄ Inter) without errors', (
    tester,
  ) async {
    // Regression: the google_fonts text theme had inherit: false and
    // AnimatedTheme couldn't interpolate it with the default one.
    final a = ThemeConfig();
    final b = ThemeConfig()..fontFamily = 'Inter';
    final themes = [
      buildTheme(a, Brightness.light),
      buildTheme(b, Brightness.light),
    ];
    expect(themes[1].textTheme.labelLarge!.inherit, isTrue);
    Widget app(ThemeData t) => MaterialApp(
      home: AnimatedTheme(
        data: t,
        child: Scaffold(
          body: FilledButton(onPressed: () {}, child: const Text('x')),
        ),
      ),
    );
    await tester.pumpWidget(app(themes[0]));
    for (final t in [themes[1], themes[0]]) {
      await tester.pumpWidget(app(t));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 30));
        expect(tester.takeException(), isNull);
      }
    }
  });

  test('the button text style is complete (line height 20, inherit false)', () {
    final theme = buildTheme(boardUiNoFont(), Brightness.light);
    final style = theme.filledButtonTheme.style!.textStyle!.resolve(
      <WidgetState>{},
    )!;
    expect(style.inherit, isFalse);
    expect(style.fontSize! * style.height!, closeTo(20, 0.05)); // M3: 14 × 1.43
    expect(style.fontWeight, FontWeight.w500);
  });

  group('BoardUI tokens', () {
    test('generated from theme.css: references and color-mix resolved', () {
      final n = tailwindPalette['neutral']!;
      expect(boardTokens['text-primary']!.light, n[950]);
      expect(boardTokens['text-primary']!.dark, n[50]);
      // color-mix(in srgb, neutral-800 30%, transparent) in dark
      expect(
        boardTokens['input-disabled-background']!.dark.toARGB32(),
        n[800]!.withValues(alpha: 0.3).toARGB32(),
      );
      // alias accent-* = blue-*
      expect(tailwindPalette['accent']![600], tailwindPalette['blue']![600]);
      expect(boardTokens.length, greaterThan(150));
    });

    test('the preset covers every ColorScheme role', () {
      final c = boardUiNoFont();
      expect(c.schemeOverrides.keys.toSet(), SchemeRole.values.toSet());
      final light = buildColorScheme(c, Brightness.light);
      final dark = buildColorScheme(c, Brightness.dark);
      // As in the BoardUI app shell: white page, gray cards.
      final page = boardTokens['background-full']!;
      final card = boardTokens['background-secondary-default']!;
      expect(light.surface, page.light);
      expect(dark.surface, page.dark);
      expect(light.surfaceContainerLow, card.light);
      expect(dark.surfaceContainerHigh, page.dark); // dialog
      expect(light.error, boardTokens['text-error-primary']!.light);
    });

    test('TokenColor: resolution by brightness and commented export', () {
      const t = TokenColor('text-primary');
      expect(t.label, 'text-primary');
      expect(t.isConst, isFalse);
      expect(
        t.toDart(),
        '/* text-primary */ (isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0A0A0A))',
      );
      const w = TokenColor('text-white'); // same in light and dark
      expect(w.isConst, isTrue);
      expect(w.toDart(inConst: true), '/* text-white */ Color(0xFFFFFFFF)');
    });
  });

  group('BoardUI typography and containers', () {
    test('type scale: sizes, line height, weight', () {
      final t = buildTheme(boardUiNoFont(), Brightness.light).textTheme;
      // title-2-medium: 20/26, 500
      expect(t.titleLarge!.fontSize, 20);
      expect(
        t.titleLarge!.fontSize! * t.titleLarge!.height!,
        closeTo(26, 0.01),
      );
      expect(t.titleLarge!.fontWeight, FontWeight.w500);
      // body-regular: 14/20, 400
      expect(t.bodyMedium!.fontSize, 14);
      expect(
        t.bodyMedium!.fontSize! * t.bodyMedium!.height!,
        closeTo(20, 0.01),
      );
      // caption-1-medium: tracking 0.15
      expect(t.labelMedium!.letterSpacing, 0.15);
      // inherit: true like the default text theme (animated transitions).
      expect(t.titleLarge!.inherit, isTrue);
    });

    test('card, dialog, snackbar, divider', () {
      final theme = buildTheme(boardUiNoFont(), Brightness.light);
      final card = theme.cardTheme;
      expect(card.color, boardTokens['background-secondary-default']!.light);
      expect(card.elevation, 0);
      expect(
        (card.shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(16),
      );
      expect(
        (theme.dialogTheme.shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(24),
      );
      expect(theme.dialogTheme.titleTextStyle!.fontSize, 20);
      final snack = theme.snackBarTheme;
      expect(snack.behavior, SnackBarBehavior.floating);
      expect(
        (snack.shape! as RoundedRectangleBorder).side.color,
        boardTokens['border-button-default']!.light,
      );
      expect(theme.dividerTheme.color, boardTokens['separator-border']!.light);
      // ListTile subtitles in secondary gray, as in Material.
      expect(
        theme.listTileTheme.subtitleTextStyle!.color,
        theme.colorScheme.onSurfaceVariant,
      );
    });

    testWidgets('full screen with every container, light and dark', (
      tester,
    ) async {
      for (final b in Brightness.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildTheme(boardUiNoFont(), b),
            home: Scaffold(
              appBar: AppBar(title: const Text('Titolo')),
              body: ListView(
                children: [
                  const Card(
                    child: ListTile(title: Text('a'), subtitle: Text('b')),
                  ),
                  const Divider(),
                  const AlertDialog(title: Text('Dialog'), content: Text('c')),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 300,
                          child: NavigationRail(
                            selectedIndex: 0,
                            labelType: NavigationRailLabelType.all,
                            destinations: const [
                              NavigationRailDestination(
                                icon: Icon(Icons.home),
                                label: Text('Home'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.settings),
                                label: Text('Opzioni'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: 0,
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
                  NavigationDestination(icon: Icon(Icons.list), label: 'Lista'),
                ],
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }
    });

    test('export: TextTheme with style names and sub-themes', () {
      final c = ThemeConfig();
      ThemePreset.boardUI.applyTo(c);
      final code = exportDart(c);
      expect(code, contains('textTheme: const TextTheme('));
      expect(code, contains('/* title-2-medium */ TextStyle(fontSize: 20'));
      expect(code, contains('cardTheme: CardThemeData('));
      expect(code, contains('snackBarTheme: SnackBarThemeData('));
      expect(code, contains('behavior: SnackBarBehavior.floating'));
      expect(code, contains('appBarTheme: AppBarThemeData('));
    });
  });

  testWidgets('editor: every section, M3 and BoardUI', (tester) async {
    tester.view.physicalSize = const Size(1600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialCraftApp());
    final state = tester.state<EditorPageState>(find.byType(EditorPage));
    Future<void> visitAll() async {
      for (final section in <EditorSection>[
        const StyleSection(),
        const GlobalSection(),
        const GeneralSection(),
        const TypographySection(),
        const ButtonSizesSection(),
        for (final k in ButtonKind.values) ButtonSection(k),
        for (final k in SurfaceKind.values) SurfaceSection(k),
      ]) {
        final label = section.toString();
        state.controller.select(section);
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 60));
        }
        expect(tester.takeException(), isNull, reason: label);
      }
    }

    await visitAll();
    // BoardUI preset without fonts (no network in tests).
    // BoardUI preset without fonts (no network in tests).
    state.controller.theme.setBase(
      ThemePreset(
        id: 'boardui-test',
        name: 'BoardUI (test)',
        description: '',
        apply: (c) {
          ThemePreset.boardUI.apply(c);
          c.fontFamily = null;
        },
      ),
    );
    state.controller.update(() {});
    await tester.pump(const Duration(milliseconds: 300));
    await visitAll();
  });

  group('BoardUI extra buttons', () {
    testWidgets('sizes, icon button, danger: metrics', (tester) async {
      await tester.pumpWidget(
        host(
          buildTheme(boardUiNoFont(), Brightness.light),
          Builder(
            builder: (context) {
              ButtonStyle? st(
                AppButtonKind k, [
                AppButtonSize s = AppButtonSize.medium,
              ]) => context.buttonStyle(k, size: s);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    key: const Key('sm'),
                    style: st(AppButtonKind.outlined, AppButtonSize.small),
                    onPressed: () {},
                    child: const Text('Small'),
                  ),
                  FilledButton(
                    key: const Key('xs'),
                    style: st(AppButtonKind.filled, AppButtonSize.xs),
                    onPressed: () {},
                    child: const Text('Xs'),
                  ),
                  FilledButton(
                    key: const Key('danger'),
                    style: st(AppButtonKind.danger),
                    onPressed: () {},
                    child: const Text('Delete'),
                  ),
                  IconButton(
                    key: const Key('icon'),
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    key: const Key('icon2'),
                    style: st(AppButtonKind.iconSecondary),
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                  ),
                ],
              );
            },
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('sm'))).height, 32);
      expect(tester.getSize(find.byKey(const Key('xs'))).height, 24);
      expect(tester.getSize(find.byKey(const Key('danger'))).height, 36);
      expect(tester.getSize(find.byKey(const Key('icon'))), const Size(36, 36));
      expect(
        tester.getSize(find.byKey(const Key('icon2'))),
        const Size(36, 36),
      );
      expect(tester.takeException(), isNull);
    });

    test('danger: red gradient per state', () {
      final c = boardUiNoFont();
      final cs = buildColorScheme(c, Brightness.light);
      final skin = buildSkin(
        ButtonKind.danger,
        c.buttons[ButtonKind.danger]!,
        cs,
      );
      final red = tailwindPalette['red']!;
      expect(skin.resolve({}).colors, [red[500], red[600]]);
      expect(skin.resolve({WidgetState.hovered}).colors, [red[400], red[500]]);
    });

    test('FAB and extension in the export', () {
      final theme = buildTheme(boardUiNoFont(), Brightness.light);
      expect(
        theme.floatingActionButtonTheme.backgroundColor,
        tailwindPalette['blue']![600],
      );
      final ext = theme.extension<AppButtonStyles>()!;
      expect(ext.style(AppButtonKind.danger), isNotNull);
      expect(ext.style(AppButtonKind.filled), isNull); // medium = theme
      expect(ext.style(AppButtonKind.filled, AppButtonSize.small), isNotNull);

      final c = ThemeConfig();
      ThemePreset.boardUI.applyTo(c);
      final code = exportDart(c);
      expect(code, contains('final filledSkin = ButtonSkin('));
      expect(code, contains('filledSkin.copyWith(radius: 8).applyTo('));
      expect(code, contains('iconButtonTheme: IconButtonThemeData('));
      expect(
        code,
        contains('floatingActionButtonTheme: FloatingActionButtonThemeData('),
      );
    });
  });

  group('tooltip, tabs, chip, badge, menu BoardUI', () {
    test('theme values', () {
      final theme = buildTheme(boardUiNoFont(), Brightness.light);
      final tip = theme.tooltipTheme.decoration! as BoxDecoration;
      expect(tip.color, boardTokens['background-primary-default']!.light);
      expect(tip.borderRadius, BorderRadius.circular(8));
      expect(tip.boxShadow, ShadowToken.dropdown.resolve(Brightness.light));
      expect(theme.tooltipTheme.textStyle!.fontSize, 12);

      final tabs = theme.tabBarTheme;
      expect((tabs.indicator! as UnderlineTabIndicator).borderSide.width, 2);
      expect(tabs.labelColor, tailwindPalette['blue']![600]);
      expect(tabs.dividerColor, boardTokens['separator-border']!.light);

      final chip = theme.chipTheme;
      expect(
        chip.color!.resolve({WidgetState.selected}),
        boardTokens['pill-tab-blue-selected-background']!.light,
      );
      expect(
        chip.color!.resolve({}),
        boardTokens['background-secondary-default']!.light,
      );
      final label = chip.labelStyle!.color! as WidgetStateColor;
      expect(
        label.resolve({WidgetState.selected}),
        tailwindPalette['blue']![500],
      );
      expect(label.resolve({}), boardTokens['text-primary']!.light);

      expect(theme.badgeTheme.largeSize, 18);

      final menu = theme.menuTheme.style!;
      expect(
        (menu.shape!.resolve({})! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(16),
      );
      final item = theme.menuButtonTheme.style!;
      expect(
        item.backgroundColor!.resolve({WidgetState.hovered}),
        boardTokens['dropdown-item-hover-background']!.light,
      );
      expect(item.backgroundColor!.resolve({}), Colors.transparent);
    });

    testWidgets('rendering with menus and popups open, light and dark', (
      tester,
    ) async {
      for (final b in Brightness.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildTheme(boardUiNoFont(), b),
            home: DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: AppBar(
                  bottom: const TabBar(
                    tabs: [
                      Tab(text: 'One'),
                      Tab(text: 'Two'),
                    ],
                  ),
                ),
                body: Column(
                  children: [
                    FilterChip(
                      label: const Text('Filtro'),
                      selected: true,
                      onSelected: (_) {},
                    ),
                    const Chip(label: Text('Chip')),
                    const Badge(label: Text('3'), child: Icon(Icons.inbox)),
                    const Tooltip(message: 'Suggerimento', child: Text('Tip')),
                    MenuAnchor(
                      menuChildren: [
                        MenuItemButton(
                          onPressed: () {},
                          child: const Text('Voce'),
                        ),
                      ],
                      builder: (_, menu, _) => TextButton(
                        onPressed: menu.open,
                        child: const Text('Apri menu'),
                      ),
                    ),
                    PopupMenuButton<int>(
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 1, child: Text('Popup')),
                      ],
                    ),
                    const DropdownMenu<int>(
                      dropdownMenuEntries: [
                        DropdownMenuEntry(value: 1, label: 'One'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Apri menu'));
        await tester.pumpAndSettle();
        expect(find.text('Voce'), findsOneWidget);
        await tester.tapAt(const Offset(5, 500));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(PopupMenuButton<int>));
        await tester.pumpAndSettle();
        expect(find.text('Popup'), findsOneWidget);
        await tester.tapAt(const Offset(5, 500));
        await tester.pumpAndSettle();
        await tester.longPress(find.text('Tip'));
        await tester.pumpAndSettle();
        expect(find.text('Suggerimento'), findsOneWidget);
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    test('export', () {
      final c = ThemeConfig();
      ThemePreset.boardUI.applyTo(c);
      final code = exportDart(c);
      for (final field in [
        'tooltipTheme: TooltipThemeData(',
        'tabBarTheme: TabBarThemeData(',
        'chipTheme: ChipThemeData(',
        'badgeTheme: BadgeThemeData(',
        'menuTheme: MenuThemeData(',
        'menuButtonTheme: MenuButtonThemeData(',
        'dropdownMenuTheme: DropdownMenuThemeData(',
        'popupMenuTheme: PopupMenuThemeData(',
      ]) {
        expect(code, contains(field), reason: field);
      }
    });
  });

  group('TextButton = link, ghost = extra style', () {
    testWidgets("Flutter's internal TextButtons do not inherit ButtonSkin", (
      tester,
    ) async {
      // Regression: menu items, SnackBar action and the copy/paste toolbar
      // picked up the ghost's light blue background.
      final cases = <Widget>[
        MenuItemButton(onPressed: () {}, child: const Text('Voce')),
        SnackBarAction(label: 'Cancel', onPressed: () {}),
        TextSelectionToolbarTextButton(
          padding: EdgeInsets.zero,
          onPressed: () {},
          child: const Text('Copy'),
        ),
        const TextButton(onPressed: null, child: Text('Link')),
      ];
      for (final w in cases) {
        await tester.pumpWidget(
          host(buildTheme(boardUiNoFont(), Brightness.light), w),
        );
        expect(
          find.descendant(
            of: find.byWidget(w),
            matching: find.byType(TweenAnimationBuilder<Decoration>),
          ),
          findsNothing,
          reason: w.runtimeType.toString(),
        );
      }
    });

    test('link: per-state colors and underline on hover', () {
      final style = buildTheme(
        boardUiNoFont(),
        Brightness.light,
      ).textButtonTheme.style!;
      final blue = tailwindPalette['blue']!;
      expect(style.backgroundBuilder, isNull);
      expect(style.backgroundColor!.resolve({}), Colors.transparent);
      expect(style.foregroundColor!.resolve({}), blue[600]);
      expect(style.foregroundColor!.resolve({WidgetState.pressed}), blue[800]);
      expect(
        style.textStyle!.resolve({WidgetState.hovered})!.decoration,
        TextDecoration.underline,
      );
      expect(
        style.textStyle!.resolve({})!.decoration,
        isNot(TextDecoration.underline),
      );
    });

    testWidgets('ghost as an extra style, with ButtonSkin', (tester) async {
      await tester.pumpWidget(
        host(
          buildTheme(boardUiNoFont(), Brightness.light),
          Builder(
            builder: (context) => TextButton(
              key: const Key('g'),
              style: context.buttonStyle(AppButtonKind.ghost),
              onPressed: () {},
              child: const Text('Ghost'),
            ),
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('g')),
          matching: find.byType(TweenAnimationBuilder<Decoration>),
        ),
        findsOneWidget,
      );
      expect(tester.getSize(find.byKey(const Key('g'))).height, 36);
    });

    test('export', () {
      final c = ThemeConfig();
      ThemePreset.boardUI.applyTo(c);
      final code = exportDart(c);
      expect(code, contains('final ghostSkin = ButtonSkin('));
      expect(code, isNot(contains('final textSkin')));
      expect(
        code,
        contains(
          '(AppButtonKind.ghost, AppButtonSize.medium): ghostSkin.applyTo(',
        ),
      );
      expect(code, contains('decoration: TextDecoration.underline'));
    });
  });

  group('checkbox, radio, switch, slider BoardUI', () {
    test('per-state colors, disabled at 50%', () {
      final theme = buildTheme(boardUiNoFont(), Brightness.light);
      final blue = tailwindPalette['blue']!;
      final white = boardTokens['background-primary-default']!.light;

      final fill = theme.checkboxTheme.fillColor!;
      expect(fill.resolve({WidgetState.selected}), blue[600]);
      expect(fill.resolve({}), white);
      expect(
        fill.resolve({WidgetState.selected, WidgetState.disabled})!.a,
        closeTo(0.5, 0.01),
      );
      final side = theme.checkboxTheme.side! as WidgetStateBorderSide;
      expect(
        side.resolve({})!.color,
        boardTokens['border-checkbox-default']!.light,
      );
      expect(side.resolve({WidgetState.selected})!.width, 0);

      expect(
        theme.radioTheme.fillColor!.resolve({WidgetState.selected}),
        blue[600],
      );
      expect(
        theme.switchTheme.trackColor!.resolve({}),
        boardTokens['background-tertiary-default']!.light,
      );
      expect(
        theme.switchTheme.trackOutlineColor!.resolve({}),
        Colors.transparent,
      );

      final slider = theme.sliderTheme;
      expect(slider.trackHeight, 6);
      expect((slider.trackShape! as GradientSliderTrackShape).activeColors, [
        blue[500],
        blue[600],
      ]);
      expect((slider.thumbShape! as SoftSliderThumbShape).radius, 10);
    });

    testWidgets('rendering and interaction, light and dark', (tester) async {
      for (final b in Brightness.values) {
        var value = 0.3;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildTheme(boardUiNoFont(), b),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => Column(
                  children: [
                    Checkbox(value: true, onChanged: (_) {}),
                    const Checkbox(value: false, onChanged: null),
                    RadioGroup<int>(
                      groupValue: 1,
                      onChanged: (_) {},
                      child: const Row(
                        children: [Radio(value: 1), Radio(value: 2)],
                      ),
                    ),
                    Switch(value: true, onChanged: (_) {}),
                    const Switch(value: false, onChanged: null),
                    Slider(
                      key: const Key('s'),
                      value: value,
                      onChanged: (v) => setState(() => value = v),
                    ),
                    const Slider(value: 0.5, onChanged: null),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.drag(find.byKey(const Key('s')), const Offset(100, 0));
        await tester.pumpAndSettle();
        expect(value, greaterThan(0.3));
        expect(tester.takeException(), isNull);
      }
    });

    test('export', () {
      final c = ThemeConfig();
      ThemePreset.boardUI.applyTo(c);
      final code = exportDart(c);
      for (final part in [
        'checkboxTheme: CheckboxThemeData(',
        'radioTheme: RadioThemeData(',
        'switchTheme: SwitchThemeData(',
        'sliderTheme: SliderThemeData(',
        'static Color? _dim(Color? c, Set<WidgetState> states)',
        'GradientSliderTrackShape(activeColors: [',
        'class SoftSliderThumbShape',
      ]) {
        expect(code, contains(part), reason: part);
      }
      expect(
        exportDart(ThemeConfig()),
        isNot(contains('class SoftSliderThumbShape')),
      );
    });
  });

  group('neobrutalism (RetroUI)', () {
    ThemeConfig neo([String palette = 'yellow', double radius = 0]) {
      final c = ThemeConfig();
      applyNeobrutalism(c, palette, radius: radius);
      c
        ..fontFamily = null
        ..headFontFamily = null; // no network in tests
      return c;
    }

    test('RangeSlider with the same shapes as the slider', () {
      final slider = buildTheme(neo(), Brightness.light).sliderTheme;
      final thumb = slider.rangeThumbShape! as SoftRangeSliderThumbShape;
      expect(thumb.cornerRadius, 0);
      expect(thumb.borderWidth, 2);
      expect(slider.rangeTrackShape, isA<GradientRangeSliderTrackShape>());
      final code = exportDart(neo());
      expect(code, contains('rangeThumbShape: SoftRangeSliderThumbShape('));
      expect(code, contains('rangeTrackShape: GradientRangeSliderTrackShape('));
      expect(code, contains('class SoftRangeSliderThumbShape'));
    });

    testWidgets('RangeSlider paints without errors', (tester) async {
      await tester.pumpWidget(
        host(
          buildTheme(neo(), Brightness.light),
          SizedBox(
            width: 300,
            child: RangeSlider(
              values: const RangeValues(.2, .7),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('AppSwitch: 44×24, square 16 thumb that travels 20', (
      tester,
    ) async {
      var on = false;
      await tester.pumpWidget(
        host(
          buildTheme(neo(), Brightness.light),
          StatefulBuilder(
            builder: (context, setState) => AppSwitch(
              key: const Key('s'),
              value: on,
              onChanged: (v) => setState(() => on = v),
            ),
          ),
        ),
      );
      final style = buildTheme(
        neo(),
        Brightness.light,
      ).extension<AppSwitchStyle>()!;
      expect(style.thumbRadius, 0);
      expect(style.thumbBorder, isTrue);
      final thumb = find.byWidgetPredicate(
        (w) => w is Container && w.constraints?.maxWidth == 16,
      );
      expect(tester.getSize(thumb), const Size(16, 16));
      final x0 = tester.getTopLeft(thumb).dx;
      await tester.tap(find.byKey(const Key('s')));
      await tester.pumpAndSettle();
      expect(on, isTrue);
      expect(tester.getTopLeft(thumb).dx - x0, 20);
      expect(tester.takeException(), isNull);
    });

    test('AppSwitch always exported, AppSwitchStyle only with geometry', () {
      final code = exportDart(neo());
      expect(code, contains('class AppSwitch extends StatefulWidget'));
      expect(
        code,
        contains('AppSwitchStyle(width: 44, height: 24, thumbSize: 16'),
      );
      final m3 = exportDart(ThemeConfig());
      expect(m3, contains('class AppSwitch extends StatefulWidget'));
      // Only the occurrences in the runtime source, none in the extensions.
      int uses(String code) => 'AppSwitchStyle('.allMatches(code).length;
      final inSource = uses(appSwitchSource);
      expect(uses(m3), inSource);
      final board = ThemeConfig();
      ThemePreset.boardUI.applyTo(board);
      expect(uses(exportDart(board)), inSource);
      expect(uses(code), inSource + 1);
    });

    testWidgets("AppSwitch without extension = Material's Switch", (
      tester,
    ) async {
      await tester.pumpWidget(
        host(ThemeData(), AppSwitch(value: true, onChanged: (_) {})),
      );
      expect(find.byType(Switch), findsOneWidget);
    });

    test('usage notes: only those the theme needs', () {
      expect(usageNotes(ThemeConfig()).map((n) => n.id), ['setup']);
      final c = ThemeConfig();
      applyNeobrutalism(c, 'yellow');
      expect(usageNotes(c).map((n) => n.id), [
        'setup',
        'fonts',
        'button.danger',
        'button.ghost',
        'button.iconSecondary',
        'buttonSizes',
        'switch',
        'menu',
      ]);
      final fonts = fontsNote(c)!;
      expect(fonts.after, contains('family: Space Grotesk'));
      expect(fonts.after, contains('family: Archivo Black'));
      final code = exportDart(c);
      expect(code, contains('// Switch → AppSwitch (required)'));
      expect(code, contains('//   MenuAnchor('));
      expect(
        code,
        contains('//     style: context.buttonStyle(AppButtonKind.danger),'),
      );
    });

    testWidgets('export: "How to use it" tab with the notes', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final c = neo();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showExportDialog(context, c),
              child: const Text('apri'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('apri'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('How to use it'));
      await tester.pumpAndSettle();
      expect(find.text('Wire up the theme'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Switch → AppSwitch'),
        300,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Switch → AppSwitch'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('palettes generated from the CSS, with the dark cascade', () {
      expect(neoPalettes.keys.toSet(), neoPaletteNames.keys.toSet());
      final y = neoPalettes['yellow']!;
      expect(y['primary']!.light, const Color(0xFFFFDB33));
      expect(y['background']!.light, const Color(0xFFF5ECE7));
      expect(y['border']!.dark, const Color(0xFF5C5C5C));
      // lime in dark: .dark .theme-lime sovrascrive .theme-lime
      expect(neoPalettes['lime']!['background']!.dark, const Color(0xFF0F0F0F));
    });

    testWidgets('metrics: button 40, field 44', (tester) async {
      await tester.pumpWidget(
        host(
          buildTheme(neo(), Brightness.light),
          const SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(
                  key: Key('b'),
                  onPressed: _noop,
                  child: Text('Invia'),
                ),
                TextField(
                  key: Key('f'),
                  decoration: InputDecoration(hintText: 'x'),
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('b'))).height, 40);
      expect(tester.getSize(find.byKey(const Key('f'))).height, 44);
      expect(tester.takeException(), isNull);
    });

    test('hard shadows and buttons that "sink"', () {
      final c = neo();
      final theme = buildTheme(c, Brightness.light);
      final card = theme.cardTheme.shape! as HardShadowBorder;
      expect(card.shadowOffset, const Offset(4, 4));
      expect(card.side.width, 2);
      expect(card.shadowColor, const Color(0xFF000000));

      final skin = buildSkin(
        ButtonKind.filled,
        c.buttons[ButtonKind.filled]!,
        theme.colorScheme,
      );
      expect(skin.resolve({}).shadows!.single.offset, const Offset(4, 4));
      expect(skin.resolve({}).shadows!.single.blurRadius, 0);
      expect(skin.resolve({WidgetState.hovered}).offset, const Offset(0, 4));
      expect(
        skin.resolve({WidgetState.hovered}).shadows!.single.offset,
        const Offset(3, 3),
      );
      expect(
        skin.resolve({WidgetState.hovered, WidgetState.pressed}).offset,
        const Offset(4, 8),
      );
      expect(
        skin.resolve({WidgetState.hovered, WidgetState.pressed}).shadows,
        isEmpty,
      );

      final field =
          theme.inputDecorationTheme.border! as WidgetStateInputBorder;
      expect(
        (field.resolve({}) as HardShadowInputBorder).shadowOffset,
        const Offset(4, 4),
      );
      expect(
        (field.resolve({WidgetState.focused}) as HardShadowInputBorder)
            .shadowOffset,
        const Offset(1, 1),
      );
    });

    testWidgets('every palette, light and dark, with overlays open', (
      tester,
    ) async {
      for (final palette in neoPaletteNames.keys) {
        for (final b in Brightness.values) {
          await tester.pumpWidget(
            MaterialApp(
              theme: buildTheme(neo(palette, palette == 'yellow' ? 8 : 0), b),
              home: DefaultTabController(
                length: 2,
                child: Scaffold(
                  appBar: AppBar(
                    title: const Text('Neo'),
                    bottom: const TabBar(
                      tabs: [
                        Tab(text: 'A'),
                        Tab(text: 'B'),
                      ],
                    ),
                  ),
                  floatingActionButton: FloatingActionButton(
                    onPressed: () {},
                    child: const Icon(Icons.add),
                  ),
                  body: ListView(
                    children: [
                      Builder(
                        builder: (context) => Wrap(
                          children: [
                            FilledButton(
                              onPressed: () {},
                              child: const Text('Ok'),
                            ),
                            ElevatedButton(
                              onPressed: () {},
                              child: const Text('Sec'),
                            ),
                            OutlinedButton(
                              onPressed: () {},
                              child: const Text('Out'),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('Link'),
                            ),
                            TextButton(
                              style: context.buttonStyle(AppButtonKind.ghost),
                              onPressed: () {},
                              child: const Text('Ghost'),
                            ),
                            FilledButton(
                              style: context.buttonStyle(
                                AppButtonKind.danger,
                                size: AppButtonSize.small,
                              ),
                              onPressed: null,
                              child: const Text('Danger'),
                            ),
                          ],
                        ),
                      ),
                      const Card(child: ListTile(title: Text('Card'))),
                      const TextField(
                        decoration: InputDecoration(errorText: 'Error'),
                      ),
                      Checkbox(value: true, onChanged: (_) {}),
                      Switch(value: true, onChanged: (_) {}),
                      Slider(value: 0.5, onChanged: (_) {}),
                      FilterChip(
                        label: const Text('Chip'),
                        selected: true,
                        onSelected: (_) {},
                      ),
                      MenuAnchor(
                        menuChildren: [
                          MenuItemButton(
                            onPressed: () {},
                            child: const Text('Voce'),
                          ),
                        ],
                        builder: (_, menu, _) => TextButton(
                          onPressed: menu.open,
                          child: const Text('Menu'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Menu'));
          await tester.pumpAndSettle();
          expect(find.text('Voce'), findsOneWidget);
          await tester.tapAt(const Offset(5, 400));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$palette $b');
        }
      }
    });

    test('export: heading font, hard shadows and sources included', () {
      final c = ThemeConfig();
      applyNeobrutalism(c, 'yellow');
      final code = exportDart(c);
      expect(code, contains("fontFamily: 'Space Grotesk'"));
      expect(code, contains("TextStyle(fontFamily: 'Archivo Black'"));
      expect(code, contains('HardShadowBorder('));
      expect(code, contains('HardShadowInputBorder('));
      expect(code, contains('class HardShadowBorder'));
      expect(code, contains('offset: Offset(4, 8)'));
      expect(code, contains("/* yellow.primary */"));
    });
  });

  test('ButtonSkin: empty states inherit from normal', () {
    const skin = ButtonSkin(
      normal: ButtonSkinState(colors: [Colors.red], foreground: Colors.white),
      hovered: ButtonSkinState(colors: [Colors.blue]),
    );
    final hovered = skin.resolve({WidgetState.hovered});
    expect(hovered.colors, [Colors.blue]);
    expect(hovered.foreground, Colors.white);
  });
}

void _noop() {}

void _layerTests() {
  group('layered theme (preset + edits)', () {
    test('merging copies every field: identical export for every preset', () {
      for (final p in ThemePreset.all) {
        final direct = ThemeConfig();
        p.apply(direct);
        final merged = ThemeConfig()..overlay(direct);
        expect(exportDart(merged), exportDart(direct), reason: p.name);
        final layered = LayeredTheme(base: p);
        expect(
          exportDart(layered.resolved),
          exportDart(direct),
          reason: p.name,
        );
      }
    });

    test('inherited values and winning edits', () {
      final t = LayeredTheme(base: ThemePreset.neobrutalism('yellow'));
      final card = SurfaceKind.card;
      expect(t.resolved.surfaces[card]!.radius, 0);
      t.edits.surfaces[card]!.radius = 12;
      t.invalidate();
      expect(t.resolved.surfaces[card]!.radius, 12);
      expect(t.baseConfig.surfaces[card]!.radius, 0);
      t.edits.surfaces[card]!.radius = null;
      t.invalidate();
      expect(t.resolved.surfaces[card]!.radius, 0);
    });

    test('preset change: edits stay on top', () {
      final t = LayeredTheme(base: ThemePreset.neobrutalism('yellow'));
      t.edits.surfaces[SurfaceKind.card]!.radius = 12;
      t.setBase(ThemePreset.neobrutalism('purple'), keepEdits: true);
      expect(t.resolved.surfaces[SurfaceKind.card]!.radius, 12);
      expect(
        t.resolved.buttons[ButtonKind.filled]!.normal.fill,
        const PaletteColor('purple', 'primary'),
      );
      t.setBase(ThemePreset.boardUI);
      expect(t.edits.isDefault, isTrue);
      expect(t.resolved.surfaces[SurfaceKind.card]!.radius, isNot(12));
    });

    test('an explicit "no" wins over a preset "yes"', () {
      final t = LayeredTheme(base: ThemePreset.neobrutalism('yellow'));
      expect(t.resolved.buttons[ButtonKind.filled]!.headFont, isTrue);
      t.edits.buttons[ButtonKind.filled]!.headFont = false;
      t.edits.shrinkWrapTapTargets = false;
      t.invalidate();
      expect(t.resolved.buttons[ButtonKind.filled]!.headFont, isFalse);
      expect(t.resolved.shrinkWrapTapTargets, isFalse);
    });

    test('globals: radius on every component, edits win', () {
      final t = LayeredTheme(base: ThemePreset.neobrutalism('yellow'));
      t.globals.radius = 8;
      t.invalidate();
      final r = t.resolved;
      expect(r.buttons[ButtonKind.filled]!.radius, 8);
      expect(r.textField.radius, 8);
      expect(r.surfaces[SurfaceKind.card]!.radius, 12);
      expect(r.surfaces[SurfaceKind.checkbox]!.radius, 2);
      t.edits.surfaces[SurfaceKind.card]!.radius = 0;
      t.invalidate();
      expect(t.resolved.surfaces[SurfaceKind.card]!.radius, 0);
      expect(t.presetConfig.buttons[ButtonKind.filled]!.radius, 0);
    });

    test('globals: Material with hard shadows', () {
      final t = LayeredTheme()..globals.shadowStyle = ShadowStyle.hard;
      t.invalidate();
      final r = t.resolved;
      expect(r.surfaces[SurfaceKind.card]!.shadow, ShadowToken.hardMd);
      expect(r.surfaces[SurfaceKind.card]!.elevation, 0);
      expect(r.buttons[ButtonKind.filled]!.normal.shadow, ShadowToken.hardMd);
      final theme = buildTheme(r, Brightness.light);
      expect(theme.cardTheme.shape, isA<HardShadowBorder>());
      // Neobrutalism with soft shadows: no more hard shadows.
      final n = LayeredTheme(base: ThemePreset.neobrutalism('yellow'))
        ..globals.shadowStyle = ShadowStyle.soft;
      n.invalidate();
      expect(n.resolved.surfaces[SurfaceKind.card]!.hasHardShadow, isFalse);
      expect(
        n.resolved.buttons[ButtonKind.filled]!.normal.shadow,
        ShadowToken.md,
      );
    });

    testWidgets('globals: height 48 for buttons and fields', (tester) async {
      final t = LayeredTheme(base: ThemePreset.neobrutalism('yellow'))
        ..globals.controlHeight = 48;
      t.invalidate();
      final c = t.resolved
        ..fontFamily = null
        ..headFontFamily = null;
      await tester.pumpWidget(
        host(
          buildTheme(c, Brightness.light),
          const SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(
                  key: Key('b'),
                  onPressed: _noop,
                  child: Text('Invia'),
                ),
                TextField(
                  key: Key('f'),
                  decoration: InputDecoration(hintText: 'x'),
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('b'))).height, 48);
      expect(tester.getSize(find.byKey(const Key('f'))).height, 48);
    });

    test('globals: motion', () {
      final t = LayeredTheme(base: ThemePreset.neobrutalism('yellow'))
        ..globals.press = PressEffect.none;
      t.invalidate();
      final b = t.resolved.buttons[ButtonKind.filled]!;
      expect(b.states[ButtonStateKey.pressed]!.offsetY, isNull);
      expect(b.states[ButtonStateKey.pressed]!.shadow, isNull);
      final m = LayeredTheme()..globals.press = PressEffect.scale;
      m.invalidate();
      expect(m.resolved.buttons[ButtonKind.filled]!.pressScale, 0.97);
      final s = LayeredTheme()
        ..globals.press = PressEffect.sink
        ..globals.shadowStyle = ShadowStyle.hard;
      s.invalidate();
      final pressed = s
          .resolved
          .buttons[ButtonKind.filled]!
          .states[ButtonStateKey.pressed]!;
      expect(pressed.offsetX, 4);
      expect(pressed.shadow, ShadowToken.none);
    });

    testWidgets('globals: every combination paints and exports', (
      tester,
    ) async {
      for (final preset in [
        ThemePreset.material3,
        ThemePreset.neobrutalism('yellow'),
      ]) {
        for (final style in ShadowStyle.values) {
          final t = LayeredTheme(base: preset)
            ..globals.radius = 6
            ..globals.borderWidth = 1
            ..globals.shadowStyle = style
            ..globals.shadowLevel = 1
            ..globals.controlHeight = 36
            ..globals.press = PressEffect.sink;
          t.invalidate();
          final c = t.resolved
            ..fontFamily = null
            ..headFontFamily = null;
          expect(exportDart(c), contains('abstract final class AppTheme'));
          await tester.pumpWidget(
            host(
              buildTheme(c, Brightness.dark),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FilledButton(onPressed: _noop, child: Text('a')),
                  const OutlinedButton(onPressed: _noop, child: Text('b')),
                  const Card(child: SizedBox(width: 80, height: 40)),
                  const TextField(),
                  Checkbox(value: true, onChanged: (_) {}),
                ],
              ),
            ),
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${preset.name} $style',
          );
        }
      }
    });

    test("modified typography: no longer the design system's", () {
      final t = LayeredTheme(base: ThemePreset.boardUI);
      final role = TextRole.values.firstWhere(
        (r) => t.baseConfig.typography.styles[r]!.source != null,
      );
      t.edits.typography.styles[role]!.size = 40;
      t.invalidate();
      final spec = t.resolved.typography.styles[role]!;
      expect(spec.size, 40);
      expect(spec.source, isNull);
    });
  });
}

void _colorTests() {
  group('colors: generators calibrated on the official colors', () {
    int channels(Color a, Color b) => [
      a.r - b.r,
      a.g - b.g,
      a.b - b.b,
      a.a - b.a,
    ].map((d) => (d * 255).abs().round()).reduce((x, y) => x > y ? x : y);

    test('BoardUI: token definitions give back the official values', () {
      Map<int, Color>? scale(String f) => boardPrimitives[f];
      for (final e in boardTokenDefs.entries) {
        final t = boardTokens[e.key]!;
        expect(
          channels(e.value.$1.eval(scale), t.light),
          lessThanOrEqualTo(1),
          reason: '${e.key} light',
        );
        expect(
          channels(e.value.$2.eval(scale), t.dark),
          lessThanOrEqualTo(1),
          reason: '${e.key} dark',
        );
      }
    });

    test('Tailwind scale: a Tailwind color rebuilds its own scale', () {
      for (final f in ['blue', 'red', 'emerald', 'violet', 'amber', 'pink']) {
        for (final shade in [300, 500, 700]) {
          final scale = accentScaleFor(boardPrimitives[f]![shade]!);
          for (final s in boardPrimitives[f]!.keys) {
            expect(
              deltaE(scale[s]!, boardPrimitives[f]![s]!),
              lessThan(0.01),
              reason: '$f-$shade → $f-$s',
            );
          }
        }
      }
      final slate = neutralScaleFor(custom: boardPrimitives['slate']![500]!);
      for (final s in boardPrimitives['slate']!.keys) {
        expect(
          deltaE(slate[s]!, boardPrimitives['slate']![s]!),
          lessThan(0.01),
        );
      }
    });

    test('Neobrutalism: generated palettes close to the 7 official ones', () {
      var fgMatches = 0;
      final errors = <String, List<double>>{};
      for (final p in neoPalettes.entries) {
        final primary = p.value['primary']!.light;
        final gen = generateNeoPalette(primary);
        expect(gen['primary']!.light, primary);
        if (gen['primary-foreground']!.light ==
            p.value['primary-foreground']!.light) {
          fgMatches++;
        }
        for (final k in [
          'primary-hover',
          'muted',
          'muted-foreground',
          'background',
        ]) {
          errors.putIfAbsent(k, () => []).addAll([
            deltaE(gen[k]!.light, p.value[k]!.light),
            deltaE(gen[k]!.dark, p.value[k]!.dark),
          ]);
        }
      }
      // The official orange uses cream-colored text (contrast 2.95:1).
      expect(fgMatches, 6);
      for (final e in errors.entries) {
        final mean = e.value.reduce((a, b) => a + b) / e.value.length;
        expect(mean, lessThan(0.08), reason: e.key);
      }
    });

    test('text on colors always readable (≥ 3:1, bold text)', () {
      for (final hex in [
        0xFF0A84FF,
        0xFFFF2D55,
        0xFF34C759,
        0xFFFFCC00,
        0xFF5856D6,
        0xFF8E8E93,
        0xFF1C1C1E,
        0xFFF2F2F7,
      ]) {
        final gen = generateNeoPalette(Color(hex));
        for (final k in ['primary', 'accent', 'secondary']) {
          for (final dark in [false, true]) {
            final bg = dark ? gen[k]!.dark : gen[k]!.light;
            final fg = dark
                ? gen['$k-foreground']!.dark
                : gen['$k-foreground']!.light;
            expect(
              contrastRatio(bg, fg),
              greaterThanOrEqualTo(3),
              reason: '${hex.toRadixString(16)} $k dark=$dark',
            );
          }
        }
      }
    });
  });

  group('colors: choices in the layered theme', () {
    test('Material: optional key colors', () {
      final t = LayeredTheme()
        ..colors.primary = materialSeeds['Indigo']
        ..colors.secondary = const Color(0xFFFF9800)
        ..colors.error = const Color(0xFF9C27B0);
      t.invalidate();
      final r = t.resolved;
      expect(r.seedColor, materialSeeds['Indigo']);
      final scheme = buildColorScheme(r, Brightness.light);
      double hue(Color c) => toOklch(c).$3;
      double dist(double a, double b) {
        final d = (a - b).abs() % 360;
        return d > 180 ? 360 - d : d;
      }

      expect(
        dist(hue(scheme.secondary), hue(const Color(0xFFFF9800))),
        lessThan(25),
      );
      expect(
        dist(hue(scheme.error), hue(const Color(0xFF9C27B0))),
        lessThan(25),
      );
      final dark = buildColorScheme(r, Brightness.dark);
      expect(dark.primary, isNot(scheme.primary));
      expect(exportDart(r), contains('secondary:'));
    });

    test(
      'BoardUI: chosen accent and neutrals recolor tokens and gradients',
      () {
        final t = LayeredTheme(base: ThemePreset.boardUI)
          ..colors.primary = boardPrimitives['emerald']![500]
          ..colors.neutralFamily = 'stone';
        t.invalidate();
        final r = t.resolved;
        final fill = r.buttons[ButtonKind.filled]!.normal.fill!;
        final scheme = buildColorScheme(r, Brightness.light);
        expect(
          deltaE(fill.resolve(scheme), boardPrimitives['emerald']![500]!),
          lessThan(0.01),
        );
        final surface = r.schemeOverrides[SchemeRole.onSurface]! as TokenColor;
        expect(surface.set, isNotNull);
        expect(surface.token.light, isNot(boardTokens['text-primary']!.light));
        expect(exportDart(r), contains('abstract final class AppTheme'));
        // No choices: official tokens.
        final official = LayeredTheme(base: ThemePreset.boardUI).resolved;
        expect(
          (official.schemeOverrides[SchemeRole.onSurface]! as TokenColor).set,
          isNull,
        );
      },
    );

    test('Neobrutalism: custom primary', () {
      final t = LayeredTheme(base: ThemePreset.neobrutalism('yellow'))
        ..colors.primary = const Color(0xFF0A84FF);
      t.invalidate();
      final fill =
          t.resolved.buttons[ButtonKind.filled]!.normal.fill! as PaletteColor;
      expect(fill.token.light, const Color(0xFF0A84FF));
      expect(fill.label, contains('Custom RetroUI'));
      expect(exportDart(t.resolved), contains('/* custom.primary */'));
    });

    test('style change: the chosen color stays', () {
      final t = LayeredTheme(base: ThemePreset.neobrutalism('yellow'))
        ..colors.primary = const Color(0xFFE11D48);
      t.setBase(ThemePreset.boardUI, keepEdits: true);
      final scheme = buildColorScheme(t.resolved, Brightness.light);
      final fill = t.resolved.buttons[ButtonKind.filled]!.normal.fill!;
      expect(
        deltaE(fill.resolve(scheme), const Color(0xFFE11D48)),
        lessThan(0.06),
      );
    });

    testWidgets('every style with custom colors paints', (tester) async {
      for (final preset in [
        ThemePreset.material3,
        ThemePreset.boardUI,
        ThemePreset.neobrutalism('green'),
      ]) {
        final t = LayeredTheme(base: preset)
          ..colors.primary = const Color(0xFF7C3AED)
          ..colors.tertiary = const Color(0xFF14B8A6)
          ..colors.neutralCustom = const Color(0xFF6B7280);
        t.invalidate();
        final c = t.resolved
          ..fontFamily = null
          ..headFontFamily = null;
        for (final b in Brightness.values) {
          await tester.pumpWidget(
            host(
              buildTheme(c, b),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FilledButton(onPressed: _noop, child: Text('a')),
                  const Card(child: SizedBox(width: 80, height: 40)),
                  const TextField(),
                  Switch(value: true, onChanged: (_) {}),
                ],
              ),
            ),
          );
          expect(tester.takeException(), isNull, reason: '${preset.name} $b');
        }
      }
    });
  });
}

void _projectTests() {
  group('project: saving and wizard', () {
    LayeredTheme roundTrip(LayeredTheme t) {
      final text = jsonEncode(layeredThemeToJson(t, name: 'Prova'));
      final back = layeredThemeFromJson(jsonDecode(text));
      expect(back.name, 'Prova');
      return back.theme;
    }

    test('every preset saved and reopened gives the same export', () {
      for (final p in ThemePreset.all) {
        final t = LayeredTheme(base: p);
        expect(
          exportDart(roundTrip(t).resolved),
          exportDart(t.resolved),
          reason: p.name,
        );
      }
    });

    test('every choice survives saving', () {
      final t = LayeredTheme(base: ThemePreset.neobrutalism('green'))
        ..colors.primary = const Color(0xFF0A84FF)
        ..colors.primaryName = 'Blu'
        ..globals.radius = 6
        ..globals.shadowStyle = ShadowStyle.hard
        ..globals.press = PressEffect.scale
        ..globals.controlHeight = 44;
      final e = t.edits
        ..fontFamily = 'Inter'
        ..density = DensityOption.compact
        ..seedColor = const Color(0xFF123456)
        ..shrinkWrapTapTargets = false;
      e.schemeOverrides[SchemeRole.tertiary] = const AdaptiveColor(
        Color(0xFF112233),
        Color(0xFF445566),
      );
      e.buttons[ButtonKind.filled]!
        ..radius = 3
        ..headFont = false
        ..fontWeight = FontWeight.w700
        ..states[ButtonStateKey.hovered]!.fill = const RoleColor(
          SchemeRole.secondary,
          alpha: 0.5,
        )
        ..states[ButtonStateKey.pressed]!.shadow = ShadowToken.hardSm;
      e.buttons[ButtonKind.danger]!.normal.foreground = const PaletteColor(
        'lime',
        'primary',
      );
      e.buttonSizes[ButtonSizeKey.small]!.minHeight = 30;
      e.textField
        ..radius = 2
        ..inputWeight = FontWeight.w500
        ..states[FieldStateKey.focused]!.border = const TokenColor(
          'text-primary',
        );
      e.typography.styles[TextRole.titleLarge]!
        ..size = 30
        ..headFont = true;
      e.surfaces[SurfaceKind.card]!
        ..background = const CustomColor(Color(0xFFFAFAFA))
        ..titleStyle = TextRole.titleSmall;
      e.surfaces[SurfaceKind.switchControl]!.thumbSize = 14;
      t.invalidate();
      final back = roundTrip(t);
      expect(back.base.name, t.base.name);
      expect(back.colors.primary, t.colors.primary);
      expect(back.globals.press, PressEffect.scale);
      expect(exportDart(back.resolved), exportDart(t.resolved));
      // The JSON contains only the choices, not the resolved theme.
      final json = layeredThemeToJson(t);
      expect((json['edits']! as Map)['buttons'], hasLength(2));
    });

    testWidgets('chip: readable labels in dark (regression)', (tester) async {
      final c = ThemeConfig();
      ThemePreset.neobrutalism('purple').apply(c);
      c
        ..fontFamily = null
        ..headFontFamily = null;
      final theme = buildTheme(c, Brightness.dark);
      await tester.pumpWidget(
        host(
          theme,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilterChip(
                label: const Text('off'),
                selected: false,
                onSelected: (_) {},
              ),
              FilterChip(
                label: const Text('on'),
                selected: true,
                onSelected: (_) {},
              ),
            ],
          ),
        ),
      );
      Color? color(String t) => tester
          .widget<RichText>(
            find.descendant(of: find.text(t), matching: find.byType(RichText)),
          )
          .text
          .style
          ?.color;
      expect(color('off'), neoPalettes['purple']!['foreground']!.dark);
      expect(color('on'), neoPalettes['purple']!['primary-foreground']!.dark);
      expect(exportDart(c), contains('WidgetStateColor.resolveWith'));
    });

    test('invalid file: clear error', () {
      expect(
        () => layeredThemeFromJson({'format': 'altro'}),
        throwsFormatException,
      );
      expect(
        () => layeredThemeFromJson({'format': themeFileFormat, 'version': 99}),
        throwsFormatException,
      );
    });

    testWidgets('wizard: style, colors, globals, name → new theme', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialCraftApp());
      final state = tester.state<EditorPageState>(find.byType(EditorPage));
      final controller = state.controller..autosave = false;
      final ctx = tester.element(find.byType(EditorPage));
      final done = showNewThemeWizard(ctx, controller);
      await tester.pumpAndSettle();
      expect(find.text('New theme'), findsWidgets);
      expect(find.text('Neobrutalism'), findsOneWidget);
      // Step 1: the dashboard (light and dark), without the details.
      expect(find.byType(DashboardShowcase), findsNWidgets(2));
      expect(find.text('Details · shapes and motion'), findsNothing);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Teal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Pill-shaped buttons'), findsOneWidget);
      // Step 3: dashboard + details on shapes and motion.
      expect(find.byType(DashboardShowcase), findsNWidgets(2));
      expect(find.text('Details · shapes and motion'), findsNWidgets(2));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'My theme'),
        'Gestionale',
      );
      await tester.tap(find.text('Create theme'));
      await tester.pumpAndSettle();
      await done;
      expect(controller.themeName, 'Gestionale');
      expect(controller.colors.primary, materialSeeds['Teal']);
      expect(controller.resolved.seedColor, materialSeeds['Teal']);
      expect(tester.takeException(), isNull);
    });
  });
}

void _shadcnFoundationTests() {
  group('shadcn/ui: foundations', () {
    test('tokens generated from the official themes', () {
      expect(shadcnBaseColors.keys, [
        'neutral',
        'stone',
        'zinc',
        'mauve',
        'olive',
        'mist',
        'taupe',
      ]);
      expect(shadcnAccents, hasLength(17));
      final n = shadcnBaseColors['neutral']!;
      expect(n['primary']!.light, const Color(0xFF171717));
      expect(n['background']!.dark, const Color(0xFF0A0A0A));
      // oklch(1 0 0 / 10%) in dark.
      expect(n['border']!.dark, const Color(0x1AFFFFFF));
      // The accent wins over the base; the rest comes from the base.
      expect(
        shadcnToken('zinc', 'blue', 'primary')!.light,
        const Color(0xFF1447E6),
      );
      expect(
        shadcnToken('zinc', 'blue', 'border'),
        same(shadcnBaseColors['zinc']!['border']),
      );
    });

    test('accent from a color: rebuilds the 17 official accents', () {
      for (final a in shadcnAccents.entries) {
        final gen = generateShadcnAccent(a.value['primary']!.light);
        for (final k in a.value.keys) {
          if (k == 'sidebar-primary-foreground') continue; // nessuna regola
          expect(
            deltaE(gen[k]!.light, a.value[k]!.light),
            lessThan(0.01),
            reason: '${a.key} $k light',
          );
          expect(
            deltaE(gen[k]!.dark, a.value[k]!.dark),
            lessThan(0.01),
            reason: '${a.key} $k dark',
          );
        }
      }
    });

    test('focus ring on fields (3px ring)', () {
      final c = ThemeConfig();
      c.textField.states[FieldStateKey.focused]!
        ..shadow = ShadowToken.ring3
        ..shadowColor = const RoleColor(SchemeRole.primary, alpha: 0.5);
      final theme = buildTheme(c, Brightness.light);
      final border =
          (theme.inputDecorationTheme.border! as WidgetStateInputBorder)
                  .resolve({WidgetState.focused})
              as HardShadowInputBorder;
      expect(border.shadowOffset, Offset.zero);
      expect(border.shadowSpread, 3);
      expect(exportDart(c), contains('shadowSpread: 3'));
    });

    test('lg size', () {
      final c = ThemeConfig();
      c.buttonSizes[ButtonSizeKey.large]!
        ..minHeight = 40
        ..paddingH = 24;
      final styles = extraButtonStyles(c);
      expect(styles.where((e) => e.$2 == AppButtonSize.large), isNotEmpty);
      expect(exportDart(c), contains('AppButtonSize.large'));
    });
  });
}

void _shadcnPresetTests() {
  group('shadcn/ui: preset', () {
    ThemeConfig shad({String base = 'neutral', String? accent}) {
      final c = ThemeConfig();
      applyShadcn(c, base: base, accent: accent);
      return c..fontFamily = null;
    }

    testWidgets('metrics: button 36, lg 40, sm 32, xs 24, field 36', (
      tester,
    ) async {
      final c = shad();
      await tester.pumpWidget(
        host(
          buildTheme(c, Brightness.light),
          SizedBox(
            width: 300,
            child: Builder(
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FilledButton(
                    key: Key('b'),
                    onPressed: _noop,
                    child: Text('Invia'),
                  ),
                  for (final (k, size) in const [
                    ('lg', AppButtonSize.large),
                    ('sm', AppButtonSize.small),
                    ('xs', AppButtonSize.xs),
                  ])
                    FilledButton(
                      key: Key(k),
                      style: context.buttonStyle(
                        AppButtonKind.filled,
                        size: size,
                      ),
                      onPressed: _noop,
                      child: const Text('Invia'),
                    ),
                  const TextField(
                    key: Key('f'),
                    decoration: InputDecoration(hintText: 'x'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('b'))).height, 36);
      expect(tester.getSize(find.byKey(const Key('lg'))).height, 40);
      expect(tester.getSize(find.byKey(const Key('sm'))).height, 32);
      expect(tester.getSize(find.byKey(const Key('xs'))).height, 24);
      expect(tester.getSize(find.byKey(const Key('f'))).height, 36);
      expect(tester.takeException(), isNull);
    });

    test('tokens, focus ring, soft shadows and radii', () {
      final c = shad();
      final theme = buildTheme(c, Brightness.light);
      expect(theme.colorScheme.primary, const Color(0xFF171717));
      final card = theme.cardTheme.shape! as HardShadowBorder;
      expect(card.radius, 14);
      expect(card.shadows, hasLength(2)); // Tailwind's shadow-sm
      expect(card.side.color, shadcnBaseColors['neutral']!['border']!.light);
      final dialog = theme.dialogTheme.shape! as HardShadowBorder;
      expect(dialog.radius, 10);
      final focused =
          (theme.inputDecorationTheme.border! as WidgetStateInputBorder)
                  .resolve({WidgetState.focused})
              as HardShadowInputBorder;
      expect(focused.shadowSpread, 3);
      expect(
        focused.shadowColor,
        shadcnBaseColors['neutral']!['ring']!.light.withValues(alpha: 0.5),
      );
      final skin = buildSkin(
        ButtonKind.filled,
        c.buttons[ButtonKind.filled]!,
        theme.colorScheme,
      );
      expect(skin.focusRingWidth, 3);
      expect(skin.focusRingOffset, 0);
      expect(c.buttons[ButtonKind.filled]!.radius, 8);
    });

    testWidgets('every base color and accent paints, light and dark', (
      tester,
    ) async {
      for (final base in shadcnBaseColors.keys) {
        for (final accent in [null, 'blue', 'yellow']) {
          final c = shad(base: base, accent: accent);
          for (final b in Brightness.values) {
            await tester.pumpWidget(
              host(
                buildTheme(c, b),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FilledButton(onPressed: _noop, child: Text('a')),
                    const OutlinedButton(onPressed: _noop, child: Text('b')),
                    const Card(child: SizedBox(width: 80, height: 40)),
                    const TextField(),
                    FilterChip(
                      label: const Text('c'),
                      selected: true,
                      onSelected: (_) {},
                    ),
                    AppSwitch(value: true, onChanged: (_) {}),
                    Slider(value: 0.4, onChanged: (_) {}),
                  ],
                ),
              ),
            );
            expect(tester.takeException(), isNull, reason: '$base $accent $b');
          }
        }
      }
    });

    test('chosen colors: base, official accent, generated accent', () {
      final t = LayeredTheme(base: ThemePreset.shadcn)
        ..colors.neutralFamily = 'zinc'
        ..colors.primary = shadcnAccents['rose']!['primary']!.light;
      t.invalidate();
      final fill =
          t.resolved.buttons[ButtonKind.filled]!.normal.fill! as ShadcnColor;
      expect(fill.base, 'zinc');
      expect(fill.accent, 'rose');
      final custom = LayeredTheme(base: ThemePreset.shadcn)
        ..colors.primary = const Color(0xFF0A84FF);
      custom.invalidate();
      final f2 =
          custom.resolved.buttons[ButtonKind.filled]!.normal.fill!
              as ShadcnColor;
      expect(f2.accent, startsWith('custom-'));
      expect(f2.token.light, const Color(0xFF0A84FF));
      // Save and reopen.
      final back = layeredThemeFromJson(
        jsonDecode(jsonEncode(layeredThemeToJson(custom))),
      ).theme;
      expect(exportDart(back.resolved), exportDart(custom.resolved));
      expect(exportDart(custom.resolved), contains('/* shadcn.primary */'));
    });
  });
}

void _shadcnVariantTests() {
  group('shadcn/ui: the 9 variants', () {
    ThemeConfig variant(String style) {
      final c = ThemeConfig();
      applyShadcn(c, style: style);
      return c..fontFamily = null;
    }

    test("values extracted from the styles' CSS", () {
      expect(shadcnStyles.keys, [
        'vega',
        'nova',
        'maia',
        'lyra',
        'mira',
        'luma',
        'rhea',
        'sera',
      ]);
      final nova = variant('nova');
      // As on ui.shadcn.com: h-8 rounded-lg px-2.5.
      expect(nova.buttons[ButtonKind.filled]!.minHeight, 32);
      expect(nova.buttons[ButtonKind.filled]!.radius, 10);
      expect(nova.buttons[ButtonKind.filled]!.paddingH, 10);
      final lyra = variant('lyra');
      expect(lyra.buttons[ButtonKind.filled]!.radius, 0);
      expect(lyra.buttons[ButtonKind.filled]!.fontSize, 12);
      expect(shadcnSpec('lyra').font, 'JetBrains Mono');
      expect(shadcnSpec('maia').font, 'Figtree');
      final sera = variant('sera');
      expect(sera.textField.underline, isTrue);
      expect(sera.buttons[ButtonKind.filled]!.letterSpacing, 1.2);
      final luma = variant('luma');
      expect(luma.surfaces[SurfaceKind.switchControl]!.width, 44);
      expect(luma.surfaces[SurfaceKind.switchControl]!.height, 20);
      // The new styles: soft destructive, cards with ring-1 foreground/10.
      expect(
        (variant('vega').buttons[ButtonKind.danger]!.normal.foreground!
                as ShadcnColor)
            .name,
        'destructive',
      );
      expect(
        variant('new-york').buttons[ButtonKind.danger]!.normal.foreground,
        const CustomColor(Color(0xFFFFFFFF)),
      );
    });

    testWidgets('actual Nova and Sera metrics', (tester) async {
      for (final (style, button, field) in [
        ('nova', 32.0, 32.0),
        ('sera', 40.0, 40.0),
        ('mira', 28.0, 28.0),
      ]) {
        await tester.pumpWidget(
          host(
            buildTheme(variant(style), Brightness.light),
            const SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(
                    key: Key('b'),
                    onPressed: _noop,
                    child: Text('Invia'),
                  ),
                  TextField(
                    key: Key('f'),
                    decoration: InputDecoration(hintText: 'x'),
                  ),
                ],
              ),
            ),
          ),
        );
        // MaterialApp animates the theme change: measure at the end.
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(const Key('b'))).height,
          button,
          reason: style,
        );
        expect(
          tester.getSize(find.byKey(const Key('f'))).height,
          field,
          reason: style,
        );
      }
    });

    testWidgets('every variant paints and exports, light and dark', (
      tester,
    ) async {
      for (final style in shadcnStyleNames.keys) {
        final c = variant(style);
        expect(exportDart(c), contains('abstract final class AppTheme'));
        for (final b in Brightness.values) {
          await tester.pumpWidget(
            host(
              buildTheme(c, b),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FilledButton(onPressed: _noop, child: Text('a')),
                  const OutlinedButton(onPressed: _noop, child: Text('b')),
                  const Card(child: SizedBox(width: 80, height: 40)),
                  const TextField(decoration: InputDecoration(errorText: 'x')),
                  FilterChip(
                    label: const Text('c'),
                    selected: true,
                    onSelected: (_) {},
                  ),
                  AppSwitch(value: true, onChanged: (_) {}),
                  Slider(value: 0.4, onChanged: (_) {}),
                ],
              ),
            ),
          );
          expect(tester.takeException(), isNull, reason: '$style $b');
        }
      }
    });

    testWidgets('Colors panel: base color rows with the grays', (tester) async {
      tester.view.physicalSize = const Size(1600, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialCraftApp());
      final state = tester.state<EditorPageState>(find.byType(EditorPage));
      final c = state.controller..autosave = false;
      // No fonts to download (no network in tests).
      c.theme.setBase(
        ThemePreset(
          id: 'shadcn-test',
          name: 'shadcn (test)',
          description: '',
          apply: (cfg) => applyShadcn(cfg..fontFamily = null),
          style: PresetStyle.shadcn,
        ),
      );
      c.update(() {});
      c.select(const GlobalSection());
      await tester.pumpAndSettle();
      for (final name in shadcnBaseNames.values) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.textContaining('only changes the grays'), findsOneWidget);
      final before = buildColorScheme(
        c.resolved,
        Brightness.light,
      ).onSurfaceVariant;
      await tester.tap(find.text('Mauve'));
      await tester.pumpAndSettle();
      expect(c.colors.neutralFamily, 'mauve');
      expect(
        buildColorScheme(c.resolved, Brightness.light).onSurfaceVariant,
        isNot(before),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('colors dashboard: every style, light and dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(700, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final preset in [
        ThemePreset.material3,
        ThemePreset.boardUI,
        ThemePreset.neobrutalism('yellow'),
        ThemePreset.shadcnVariant('luma'),
      ]) {
        final c = LayeredTheme(base: preset).resolved
          ..fontFamily = null
          ..headFontFamily = null;
        for (final b in Brightness.values) {
          await tester.pumpWidget(
            host(
              buildTheme(c, b),
              const SingleChildScrollView(
                child: SizedBox(width: 560, child: DashboardShowcase()),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Sales trend'), findsOneWidget);
          expect(tester.takeException(), isNull, reason: '${preset.name} $b');
        }
      }
    });

    test('project file: preset saved by id', () {
      for (final p in ThemePreset.all) {
        final json = layeredThemeToJson(LayeredTheme(base: p));
        expect(json['style'], p.id);
        expect(layeredThemeFromJson(json).theme.base, same(p), reason: p.id);
      }
      expect(
        ThemePreset.all.map((p) => p.id).toSet().length,
        ThemePreset.all.length,
        reason: 'duplicate ids',
      );
      expect(presetFromJson('unknown'), same(ThemePreset.material3));
    });

    test('variant change: colors and choices stay', () {
      final t = LayeredTheme(base: ThemePreset.shadcn)
        ..colors.neutralFamily = 'stone'
        ..colors.primary = shadcnAccents['violet']!['primary']!.light;
      t.edits.surfaces[SurfaceKind.card]!.radius = 3;
      t.setBase(ThemePreset.shadcnVariant('luma'), keepEdits: true);
      final fill =
          t.resolved.buttons[ButtonKind.filled]!.normal.fill! as ShadcnColor;
      expect(fill.base, 'stone');
      expect(fill.accent, 'violet');
      expect(t.resolved.surfaces[SurfaceKind.card]!.radius, 3);
      expect(t.resolved.buttons[ButtonKind.filled]!.radius, 26);
      // Saving: the variant is found again by name.
      final back = layeredThemeFromJson(
        jsonDecode(jsonEncode(layeredThemeToJson(t))),
      ).theme;
      expect(back.base.shadcnStyle, 'luma');
    });
  });
}
