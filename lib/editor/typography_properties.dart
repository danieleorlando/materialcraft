import 'package:material_ui/material_ui.dart';

import '../model/typography_config.dart';
import 'editor_controller.dart';
import 'properties_panel.dart';
import 'widgets/property_fields.dart';

/// The 15 TextTheme styles: size, line height, weight and letter spacing.
class TypographyProperties extends StatelessWidget {
  const TypographyProperties({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    // t = user edits, rt = result (preset + edits).
    final t = controller.edits.typography;
    final rt = controller.resolved.typography;
    final from = controller.preset.name;
    final theme = Theme.of(context);
    void set(VoidCallback f) => controller.update(f);

    String summary(TextRole r, TypeSpec s) {
      final size = s.size ?? r.m3Size;
      final lh = s.lineHeight ?? r.m3LineHeight;
      final w = (s.weight ?? r.m3Weight).value;
      final src = s.source == null ? '' : ' · ${s.source}';
      return '${size.round()}/${lh.round()} · $w$src';
    }

    return ListView(
      children: [
        PanelHeader(
          title: 'Typography',
          subtitle: 'TextTheme · ThemeData(textTheme:)',
          action: TextButton.icon(
            onPressed: t.isEmpty ? null : () => set(t.reset),
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text('Reset'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'The font family is chosen in "Global properties". Buttons and '
            'fields also have their own styles.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final r in TextRole.values)
          _RoleTile(
            key: ValueKey(r),
            role: r,
            spec: t.styles[r]!,
            inherited: rt.styles[r]!,
            from: from,
            summary: summary(r, rt.styles[r]!),
            onChanged: (fn) => set(fn),
            onReset: () => set(() => t.styles[r] = TypeSpec()),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    super.key,
    required this.role,
    required this.spec,
    required this.inherited,
    required this.from,
    required this.summary,
    required this.onChanged,
    required this.onReset,
  });

  final TextRole role;
  final TypeSpec spec;

  /// Resolved style (preset + edits): shows the inherited values.
  final TypeSpec inherited;
  final String from;
  final String summary;
  final void Function(VoidCallback) onChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Row(
        children: [
          Text(role.label, style: theme.textTheme.bodyMedium),
          if (!spec.isEmpty) ...[
            const SizedBox(width: 6),
            Icon(Icons.circle, size: 6, color: theme.colorScheme.primary),
          ],
        ],
      ),
      subtitle: Text(
        summary,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Used for: ${role.usedBy}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              if (!spec.isEmpty)
                TextButton(onPressed: onReset, child: const Text('Reset')),
            ],
          ),
        ),
        NumberField(
          label: 'Size',
          value: spec.size,
          inherited: inherited.size,
          inheritedFrom: from,
          defaultValue: role.m3Size,
          min: 8,
          max: 72,
          unit: ' px',
          onChanged: (v) => onChanged(() {
            spec.size = v;
            spec.source = null;
          }),
        ),
        NumberField(
          label: 'Line height',
          value: spec.lineHeight,
          inherited: inherited.lineHeight,
          inheritedFrom: from,
          defaultValue: role.m3LineHeight,
          min: 10,
          max: 88,
          unit: ' px',
          onChanged: (v) => onChanged(() {
            spec.lineHeight = v;
            spec.source = null;
          }),
        ),
        NumberField(
          label: 'Letter spacing',
          value: spec.letterSpacing,
          inherited: inherited.letterSpacing,
          inheritedFrom: from,
          defaultValue: role.m3LetterSpacing,
          min: -1,
          max: 2,
          step: 0.05,
          decimals: 2,
          onChanged: (v) => onChanged(() {
            spec.letterSpacing = v;
            spec.source = null;
          }),
        ),
        SwitchField(
          label: 'Heading font',
          value: inherited.headFont ?? false,
          onChanged: (v) => onChanged(() {
            spec.headFont = v;
            spec.source = null;
          }),
        ),
        ChoiceField<FontWeight>(
          label: 'Weight',
          value: spec.weight,
          inherited: inherited.weight,
          inheritedFrom: from,
          defaultLabel: 'default (${role.m3Weight.value})',
          options: fontWeightOptions,
          onChanged: (v) => onChanged(() {
            spec.weight = v;
            spec.source = null;
          }),
        ),
      ],
    );
  }
}
