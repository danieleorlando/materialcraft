import 'package:flutter/material.dart';

import '../model/boardui_tokens.dart';
import '../model/color_ref.dart';
import '../model/color_sets.dart';
import '../model/material_colors.dart';
import '../model/neobrutalism_tokens.dart';
import '../model/presets.dart';
import '../model/presets_neobrutalism.dart';
import '../model/presets_shadcn.dart';
import '../model/shadcn_tokens.dart';
import '../model/theme_config.dart';
import 'editor_controller.dart';
import 'widgets/color_picker_dialog.dart';
import 'widgets/property_fields.dart';

/// "Colors" step: the style's official colors or your own color from which
/// the whole palette is generated, with the style's rules.
class ColorChoiceSection extends StatelessWidget {
  const ColorChoiceSection({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final preset = controller.preset;
    final ch = controller.colors;
    final theme = Theme.of(context);
    void set(VoidCallback f) => controller.update(f);

    Widget hint(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );

    Future<Color?> pick(Color initial) async {
      final picked = await showColorPicker(
        context,
        initial: CustomColor(initial),
        allowRoles: false,
        allowAdaptive: false,
      );
      return picked is CustomColor ? picked.color.withValues(alpha: 1) : null;
    }

    Widget custom(String label, String generated) => _ColorRow(
      label: label,
      color: ch.primary,
      emptyText: generated,
      onPick: () async {
        final c = await pick(ch.primary ?? controller.resolved.seedColor);
        if (c != null) {
          set(() {
            ch.primary = c;
            ch.primaryName = null;
          });
        }
      },
      onReset: () => set(() {
        ch.primary = null;
        ch.primaryName = null;
      }),
    );

    final children = switch (preset.style) {
      PresetStyle.material => [
        hint(
          'Material generates the whole scheme (light and dark) from one '
          'color. The purple baseline is the official scheme; the others are '
          'the colors of the Material Design palette.',
        ),
        _SwatchGrid(
          swatches: {'Baseline M3': ThemeConfig.defaultSeed, ...materialSeeds},
          selected: ch.primary == null ? 'Baseline M3' : ch.primaryName,
          onSelect: (name, color) => set(() {
            ch.primary = name == 'Baseline M3' ? null : color;
            ch.primaryName = name == 'Baseline M3' ? null : name;
          }),
        ),
        custom(
          'Custom color',
          ch.primaryName ?? 'none (the one above is used)',
        ),
        const SizedBox(height: 8),
        hint(
          'Optional key colors: if you set one, its tonal palette comes from '
          'the chosen color instead of the primary (as in the Material Theme '
          'Builder).',
        ),
        for (final (label, get, put)
            in <(String, Color? Function(), void Function(Color?))>[
              ('Secondary', () => ch.secondary, (v) => ch.secondary = v),
              ('Tertiary', () => ch.tertiary, (v) => ch.tertiary = v),
              ('Neutral', () => ch.neutral, (v) => ch.neutral = v),
              (
                'Neutral variant',
                () => ch.neutralVariant,
                (v) => ch.neutralVariant = v,
              ),
              ('Error', () => ch.error, (v) => ch.error = v),
            ])
          _ColorRow(
            label: label,
            color: get(),
            emptyText: 'generated from the primary',
            dense: true,
            onPick: () async {
              final c = await pick(get() ?? controller.resolved.seedColor);
              if (c != null) set(() => put(c));
            },
            onReset: () => set(() => put(null)),
          ),
      ],
      PresetStyle.boardUI => [
        hint(
          'BoardUI is designed for swapping the accent: the color generates a '
          '50–950 scale (Tailwind style) and the 186 tokens are recomputed. '
          'The neutrals give character to backgrounds, borders and text.',
        ),
        _SwatchGrid(
          swatches: {
            'Blue (official)': boardPrimitives['accent']![500]!,
            for (final f in _tailwindAccents)
              if (boardPrimitives[f] != null)
                _cap(f): boardPrimitives[f]![500]!,
          },
          selected: ch.primary == null ? 'Blue (official)' : ch.primaryName,
          onSelect: (name, color) => set(() {
            final official = name == 'Blue (official)';
            ch.primary = official ? null : color;
            ch.primaryName = official ? null : name;
          }),
        ),
        custom('Custom accent', ch.primaryName ?? 'none'),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in neutralFamilies.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected:
                      ch.neutralCustom == null &&
                      (ch.neutralFamily ?? 'neutral') == e.key,
                  avatar: ColorSwatchDot(
                    color: boardPrimitives[e.key]![500]!,
                    size: 16,
                  ),
                  onSelected: (_) => set(() {
                    ch.neutralFamily = e.key == 'neutral' ? null : e.key;
                    ch.neutralCustom = null;
                  }),
                ),
            ],
          ),
        ),
        _ColorRow(
          label: 'Custom gray',
          color: ch.neutralCustom,
          emptyText: 'none',
          dense: true,
          onPick: () async {
            final c = await pick(
              ch.neutralCustom ?? boardPrimitives['neutral']![500]!,
            );
            if (c != null) set(() => ch.neutralCustom = c);
          },
          onReset: () => set(() => ch.neutralCustom = null),
        ),
      ],
      PresetStyle.shadcn => [
        hint(
          'shadcn/ui has two levels. The base color only changes the grays '
          '(backgrounds, borders, secondary text): the differences are '
          'subtle, as in the original, and show more in dark mode. To give '
          'the theme a color, pick an accent below or your own primary.',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
          child: Text('Base color (grays)', style: theme.textTheme.labelLarge),
        ),
        for (final e in shadcnBaseNames.entries)
          _BaseRow(
            name: e.value,
            tokens: shadcnBaseColors[e.key]!,
            selected:
                (ch.neutralFamily ?? 'neutral') == e.key ||
                (!shadcnBaseColors.containsKey(ch.neutralFamily) &&
                    e.key == 'neutral'),
            onTap: () => set(() {
              ch.neutralFamily = e.key == 'neutral' ? null : e.key;
              ch.neutralCustom = null;
            }),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
          child: Text(
            'Accent (primary and charts)',
            style: theme.textTheme.labelLarge,
          ),
        ),
        _SwatchGrid(
          swatches: {
            'Base color primary':
                shadcnBaseColors[shadcnBaseColors.containsKey(ch.neutralFamily)
                        ? ch.neutralFamily!
                        : 'neutral']!['primary']!
                    .light,
            for (final a in shadcnAccents.entries)
              _cap(a.key): a.value['primary']!.light,
          },
          selected: ch.primary == null
              ? 'Base color primary'
              : shadcnAccents.entries
                    .where((a) => a.value['primary']!.light == ch.primary)
                    .map((a) => _cap(a.key))
                    .firstOrNull,
          onSelect: (name, color) => set(() {
            final official = name == 'Base color primary';
            ch.primary = official ? null : color;
            ch.primaryName = official ? null : name;
          }),
        ),
        custom('Custom primary', ch.primaryName ?? 'none'),
      ],
      PresetStyle.neobrutalism => [
        hint(
          'The 7 official RetroUI palettes, or your own primary: background, '
          'hover, muted and accent are generated with the rules derived from '
          'the official palettes; text on colors is black or white depending '
          'on contrast.',
        ),
        _SwatchGrid(
          swatches: {
            for (final e in neoPaletteNames.entries)
              e.value: neoPalettes[e.key]!['primary']!.light,
          },
          selected: ch.primary == null
              ? neoPaletteNames[preset.neoPalette]
              : null,
          onSelect: (name, _) {
            final key = neoPaletteNames.entries
                .firstWhere((e) => e.value == name)
                .key;
            controller.colors.primary = null;
            controller.applyPreset(
              ThemePreset.neobrutalism(key),
              keepEdits: true,
            );
          },
        ),
        custom('Custom primary', 'none (official palette)'),
      ],
    };

    return PropertySection(title: 'Style colors', children: children);
  }
}

const _tailwindAccents = [
  'red', 'orange', 'amber', 'yellow', 'lime', 'green', 'emerald', 'teal', //
  'cyan', 'sky', 'indigo', 'violet', 'purple', 'fuchsia', 'pink', 'rose',
];

String _cap(String s) => s[0].toUpperCase() + s.substring(1);

class _SwatchGrid extends StatelessWidget {
  const _SwatchGrid({
    required this.swatches,
    required this.selected,
    required this.onSelect,
  });

  final Map<String, Color> swatches;
  final String? selected;
  final void Function(String name, Color color) onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final e in swatches.entries)
            Tooltip(
              message: e.key,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onSelect(e.key, e.value),
                child: Container(
                  width: 30,
                  height: 30,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: e.key == selected
                          ? cs.onSurface
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: e.value,
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.outlineVariant),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.label,
    required this.color,
    required this.emptyText,
    required this.onPick,
    required this.onReset,
    this.dense = false,
  });

  final String label;
  final Color? color;
  final String emptyText;
  final VoidCallback onPick;
  final VoidCallback onReset;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color;
    return InkWell(
      onTap: onPick,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, dense ? 3 : 6, 4, dense ? 3 : 6),
        child: Row(
          children: [
            if (c != null)
              ColorSwatchDot(color: c, size: 28)
            else
              const EmptySwatch(size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodyMedium),
                  Text(
                    c == null ? emptyText : colorLabel(c),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: c == null ? FontStyle.italic : null,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 36,
              child: c != null
                  ? IconButton(
                      tooltip: 'Reset',
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      onPressed: onReset,
                      icon: const Icon(Icons.restart_alt),
                    )
                  : const Icon(Icons.edit_outlined, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

/// A shadcn base color with its strip of grays (light and dark).
class _BaseRow extends StatelessWidget {
  const _BaseRow({
    required this.name,
    required this.tokens,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final Map<String, BoardToken> tokens;
  final bool selected;
  final VoidCallback onTap;

  static const _strip = [
    'background',
    'muted',
    'border',
    'muted-foreground',
    'primary',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    Widget strip(bool dark) => ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border.all(color: cs.outlineVariant)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final k in _strip)
              Tooltip(
                message: '$k · ${dark ? 'dark' : 'light'}',
                child: Container(
                  width: 18,
                  height: 18,
                  color: dark ? tokens[k]!.dark : tokens[k]!.light,
                ),
              ),
          ],
        ),
      ),
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 16, 4),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(name, style: theme.textTheme.bodyMedium)),
            strip(false),
            const SizedBox(width: 6),
            strip(true),
          ],
        ),
      ),
    );
  }
}
