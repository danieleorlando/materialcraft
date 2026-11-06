import 'package:material_ui/material_ui.dart';

import '../model/presets.dart';
import '../model/presets_shadcn.dart';
import '../model/theme_builder.dart';
import '../model/theme_config.dart';
import 'editor_controller.dart';
import 'properties_panel.dart';

/// Description of the three base styles.
const styleInfo = <PresetStyle, (String, String, String?)>{
  PresetStyle.material: (
    'Material 3',
    "Flutter's defaults: color scheme generated from one color, pill-shaped "
        "buttons, soft shadows and Material 3 states.",
    null,
  ),
  PresetStyle.boardUI: (
    'BoardUI',
    'SaaS product interface: light gradients, thin borders, CSS shadows, '
        'focus ring, Inter font.',
    'github.com/BoardUI/boardui · MIT',
  ),
  PresetStyle.shadcn: (
    'shadcn/ui',
    'Clean and neutral: thin borders, very light shadows, 3px focus ring, '
        '10px radius, Geist font. The style of many modern web apps.',
    'github.com/shadcn-ui/ui · MIT',
  ),
  PresetStyle.neobrutalism: (
    'Neobrutalism',
    'Retro and bold: 2px black borders, offset hard shadows, buttons that '
        'sink, Archivo Black for headings.',
    'github.com/neobrutalism/neobrutalism (RetroUI) · MIT',
  ),
};

/// Preset to use for a style (for Neobrutalism it keeps the current palette).
ThemePreset presetForStyle(PresetStyle style, {ThemePreset? current}) =>
    switch (style) {
      PresetStyle.material => ThemePreset.material3,
      PresetStyle.boardUI => ThemePreset.boardUI,
      PresetStyle.shadcn =>
        current?.style == PresetStyle.shadcn ? current! : ThemePreset.shadcn,
      PresetStyle.neobrutalism =>
        current?.style == PresetStyle.neobrutalism
            ? current!
            : ThemePreset.neobrutalism('yellow'),
    };

/// Changes style, asking what to do with the choices already made.
Future<void> changeStyle(
  BuildContext context,
  EditorController controller,
  ThemePreset preset,
) async {
  var keepEdits = false;
  if (controller.hasEdits) {
    final choice = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Switch to "${styleInfo[preset.style]!.$1}"?'),
        content: const Text(
          'You have already chosen colors, global properties or component '
          'changes. You can keep them on top of the new style (they win over '
          'its values) or start from scratch.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Start from scratch'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keep my choices'),
          ),
        ],
      ),
    );
    if (choice == null) return;
    keepEdits = choice;
  }
  await controller.applyPreset(preset, keepEdits: keepEdits);
}

/// The three style cards, with a small preview of each.
class StyleCards extends StatelessWidget {
  const StyleCards({super.key, required this.selected, required this.onSelect});

  final PresetStyle selected;
  final ValueChanged<PresetStyle> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final style in PresetStyle.values)
          _StyleCard(
            style: style,
            selected: style == selected,
            onTap: () => onSelect(style),
          ),
      ],
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final PresetStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final (title, description, source) = styleInfo[style]!;

    // Preview with the style's theme (no downloaded fonts: the font
    // names are in the description).
    final config = ThemeConfig();
    presetForStyle(style).apply(config);
    config
      ..fontFamily = null
      ..headFontFamily = null;
    final preview = buildTheme(config, Brightness.light);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Material(
        color: selected ? cs.secondaryContainer : cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: theme.textTheme.titleMedium),
                    ),
                    if (selected) Icon(Icons.check_circle, color: cs.primary),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (source != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      source,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                IgnorePointer(
                  child: Theme(
                    data: preview,
                    child: Builder(
                      builder: (context) => Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            FilledButton(
                              onPressed: () {},
                              child: const Text('Save'),
                            ),
                            OutlinedButton(
                              onPressed: () {},
                              child: const Text('Cancel'),
                            ),
                            Checkbox(value: true, onChanged: (_) {}),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The shadcn/ui variants (classic style and the 8 new ones).
class ShadcnVariantPicker extends StatelessWidget {
  const ShadcnVariantPicker({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Text('shadcn/ui variant', style: theme.textTheme.titleSmall),
          ),
          RadioGroup<String>(
            groupValue: selected,
            onChanged: (v) => onSelect(v!),
            child: Column(
              children: [
                for (final e in shadcnStyleNames.entries)
                  RadioListTile<String>(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    value: e.key,
                    title: Text(e.value.split(' · ').first),
                    subtitle: Text(
                      [
                        e.value.split(' · ').last,
                        'font ${shadcnSpec(e.key).font}',
                        'radius ${shadcnSpec(e.key).buttonRadius.round()} px',
                        'buttons '
                            '${shadcnSpec(e.key).sizes['default']!.$1?.round()} '
                            'px',
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Style" panel of the sidebar.
class StyleProperties extends StatelessWidget {
  const StyleProperties({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        const PanelHeader(
          title: 'Style',
          subtitle: 'The starting design system',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'The style sets the "physics" of the theme: shapes, borders, '
            'shadows and how buttons react. Colors and global properties are '
            'chosen in the next sections.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        StyleCards(
          selected: controller.preset.style,
          onSelect: (style) {
            if (style == controller.preset.style) return;
            changeStyle(
              context,
              controller,
              presetForStyle(style, current: controller.preset),
            );
          },
        ),
        if (controller.preset.style == PresetStyle.shadcn)
          ShadcnVariantPicker(
            selected: controller.preset.shadcnStyle,
            // Changing variant keeps colors and choices.
            onSelect: (v) => controller.applyPreset(
              ThemePreset.shadcnVariant(v),
              keepEdits: true,
            ),
          ),
      ],
    );
  }
}
