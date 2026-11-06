import '../model/surface_config.dart';
import '../model/theme_config.dart';

/// An instruction on how to use the exported theme: what the theme does by
/// itself and
/// what has to be written in the app code instead (explicit helpers on top of
/// Material, never widgets that replace one).
class UsageNote {
  const UsageNote({
    required this.id,
    required this.title,
    required this.body,
    this.before,
    required this.after,
    this.required = false,
    this.language = 'dart',
  });

  final String id;
  final String title;

  /// Short explanation: why it's needed and what happens if you don't do it.
  final String body;

  /// Starting Material code (`null` = there's no equivalent).
  final String? before;

  /// Code to write in the app.
  final String after;

  /// Without this change the theme doesn't look like the preview.
  final bool required;
  final String language;
}

/// The Material library the exported file is written for.
enum ExportTarget {
  /// `package:material_ui`, Material as a package (Flutter 3.47+).
  materialUi(
    label: 'material_ui',
    description: 'Flutter 3.47+, apps migrated to the material_ui package',
    import: 'package:material_ui/material_ui.dart',
    packageVersion: '^0.2.0',
    dynamicColorVersion: '^2.1.0',
    dartVersion: (3, 13),
  ),

  /// `package:flutter/material.dart`, Material inside the framework.
  flutterMaterial(
    label: 'flutter/material',
    description: 'Flutter before 3.47, or apps still on flutter/material',
    import: 'package:flutter/material.dart',
    packageVersion: '^0.1.0',
    dynamicColorVersion: '^1.8.1',
    // Flutter 3.35, the oldest supported by materialcraft 0.1.x.
    dartVersion: (3, 9),
  );

  const ExportTarget({
    required this.label,
    required this.description,
    required this.import,
    required this.packageVersion,
    required this.dynamicColorVersion,
    required this.dartVersion,
  });

  final String label;
  final String description;

  /// Import of the Material library in the exported file.
  final String import;

  /// Version of the `materialcraft` package stated in the export.
  final String packageVersion;

  /// Version of `dynamic_color` built on the same Material library.
  final String dynamicColorVersion;

  /// Oldest Dart version (major, minor) the exported code must compile on.
  final (int, int) dartVersion;
}

/// The instructions this theme needs, in the order to apply them.
List<UsageNote> usageNotes(
  ThemeConfig c, {
  bool usePackage = false,
  ExportTarget target = ExportTarget.materialUi,
}) => [
  if (usePackage) packageNote(target),
  setupNote(),
  ?fontsNote(c),
  for (final kind in ButtonKind.values)
    if (kind.isExtra && !c.buttons[kind]!.isEmpty) buttonExtraNote(kind),
  if (c.buttonSizes.values.any((s) => !s.isEmpty)) buttonSizesNote(),
  if (c.surfaces[SurfaceKind.switchControl]!.hasSwitchGeometry)
    switchNote(usePackage: usePackage),
  if (menuNeedsNoClip(c)) menuNote(),
  dynamicColorNote(target),
];

bool menuNeedsNoClip(ThemeConfig c) {
  final menu = c.surfaces[SurfaceKind.menu]!;
  return !menu.isEmpty && menu.hasShapeShadow;
}

UsageNote packageNote([
  ExportTarget target = ExportTarget.materialUi,
]) => UsageNote(
  id: 'package',
  title: 'Add the materialcraft package',
  body:
      'The theme uses the classes of the materialcraft package (ButtonSkin, '
      'AppSwitch, HardShadowBorder, …) instead of bundling them in the file. '
      'Upgrading the package brings you fixes without exporting the theme '
      'again.${target == ExportTarget.flutterMaterial ? ' The 0.1.x versions are the ones built on flutter/material.' : ''}',
  after: '''dependencies:
  materialcraft: ${target.packageVersion}''',
  required: true,
  language: 'yaml',
);

UsageNote setupNote() => const UsageNote(
  id: 'setup',
  title: 'Wire up the theme',
  body:
      'Copy app_theme.dart into your project (for example in lib/) and pass it '
      'to MaterialApp. Every Material widget takes its style from here.',
  after: '''import 'app_theme.dart';

MaterialApp(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  home: ...,
)''',
  required: true,
);

UsageNote? fontsNote(ThemeConfig c) {
  final families = [?c.fontFamily, ?c.headFontFamily];
  if (families.isEmpty) return null;
  final yaml = StringBuffer('flutter:\n  fonts:\n');
  for (final f in families) {
    final dir = f.replaceAll(' ', '');
    // The heading font usually has a single weight (e.g. Archivo Black).
    final onlyHead = f == c.headFontFamily && f != c.fontFamily;
    yaml
      ..writeln('    - family: $f')
      ..writeln('      fonts:')
      ..writeln('        - asset: assets/fonts/$dir/$dir-Regular.ttf')
      ..writeln('          weight: 400');
    if (!onlyHead) {
      yaml
        ..writeln('        - asset: assets/fonts/$dir/$dir-Bold.ttf')
        ..writeln('          weight: 700');
    }
  }
  final head = c.headFontFamily;
  return UsageNote(
    id: 'fonts',
    title: families.length == 1 ? 'Add the font' : 'Add the fonts',
    body:
        'The theme uses ${families.map((f) => "'$f'").join(' and ')}'
        '${head == null ? '' : " ('$head' for headings)"}. Download the files '
        '(Google Fonts) and declare them in pubspec.yaml with the same family '
        'name, one file per weight you use (the paths below are an example). '
        'Without them, Flutter falls back to the system font.',
    after: yaml.toString().trimRight(),
    required: true,
    language: 'yaml',
  );
}

UsageNote buttonExtraNote(ButtonKind kind) {
  final (example, child) = switch (kind) {
    ButtonKind.danger => ("onPressed: _delete", "const Text('Delete')"),
    ButtonKind.ghost => ("onPressed: _cancel", "const Text('Cancel')"),
    _ => ("onPressed: _filter", "const Icon(Icons.tune)"),
  };
  final childArg = kind.isIconOnly ? 'icon: $child' : 'child: $child';
  return UsageNote(
    id: 'button.${kind.name}',
    title: '${kind.label} button',
    body:
        'Material has no ${kind.label} variant: the theme exports it as an '
        'extra style. Use a ${kind.widget} with the style taken from the '
        'theme; without `style:` you get the regular ${kind.widget}.',
    after:
        '${kind.widget}(\n'
        '  style: context.buttonStyle(AppButtonKind.${kind.name}),\n'
        '  $example,\n'
        '  $childArg,\n'
        ')',
  );
}

UsageNote buttonSizesNote() => const UsageNote(
  id: 'buttonSizes',
  title: 'Button sizes',
  body:
      'Material has a single size per button. The large, small and xs sizes '
      'are extra styles: pass them with `context.buttonStyle(kind, size:)`. '
      'Without it, the button keeps the regular size.',
  before: '''OutlinedButton(
  onPressed: _save,
  child: const Text('Save'),
)''',
  after: '''OutlinedButton(
  style: context.buttonStyle(
    AppButtonKind.outlined,
    size: AppButtonSize.small,
  ),
  onPressed: _save,
  child: const Text('Save'),
)''',
);

UsageNote switchNote({bool usePackage = false}) => UsageNote(
  id: 'switch',
  title: 'Switch → AppSwitch',
  body:
      "Material's theme cannot change the shape of the switch (the thumb "
      "stays round). For this theme's geometry use AppSwitch, which "
      "${usePackage ? 'comes from the materialcraft package' : 'is included in app_theme.dart'} "
      "and takes value and onChanged just like Switch. SwitchListTile uses "
      "Material's Switch: replace it with a ListTile that has AppSwitch as "
      "trailing.",
  before: '''Switch(
  value: on,
  onChanged: (v) => setState(() => on = v),
)

SwitchListTile(
  title: const Text('Notifications'),
  value: on,
  onChanged: (v) => setState(() => on = v),
)''',
  after: '''AppSwitch(
  value: on,
  onChanged: (v) => setState(() => on = v),
)

ListTile(
  title: const Text('Notifications'),
  onTap: () => setState(() => on = !on),
  trailing: AppSwitch(
    value: on,
    onChanged: (v) => setState(() => on = v),
  ),
)''',
  required: true,
);

UsageNote dynamicColorNote([ExportTarget target = ExportTarget.materialUi]) =>
    UsageNote(
      id: 'dynamicColor',
      title: 'Dynamic color (optional)',
      body:
          'On Android 12+ the theme can take its color scheme from the '
          'wallpaper: add dynamic_color ${target.dynamicColorVersion} and pass '
          'the system schemes to AppTheme. Where they are not available (null) '
          "the theme's own scheme is used. Colors that the theme sets outside "
          'the scheme do not change.',
      before: '''MaterialApp(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  home: ...,
)''',
      after: '''DynamicColorBuilder(
  builder: (light, dark) => MaterialApp(
    theme: AppTheme.light(light),
    darkTheme: AppTheme.dark(dark),
    home: ...,
  ),
)''',
    );

UsageNote menuNote() => const UsageNote(
  id: 'menu',
  title: 'Menu with a shadow',
  body:
      "MenuAnchor clips the menu panel and the theme cannot prevent it: the "
      "shadow would be cut off. Add clipBehavior: Clip.none to every "
      "MenuAnchor. PopupMenuButton needs nothing.",
  before: '''MenuAnchor(
  menuChildren: [...],
  builder: ...,
)''',
  after: '''MenuAnchor(
  clipBehavior: Clip.none,
  menuChildren: [...],
  builder: ...,
)''',
  required: true,
);
