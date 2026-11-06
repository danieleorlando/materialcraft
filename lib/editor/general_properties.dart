import 'package:material_ui/material_ui.dart';

import '../export/usage_notes.dart';
import '../model/global_tokens.dart';
import '../model/theme_config.dart';
import 'editor_controller.dart';
import 'properties_panel.dart';
import 'widgets/property_fields.dart';
import 'widgets/usage_callout.dart';

/// Global properties: they apply to every component, on top of the chosen
/// style. Edits made on a single component always win.
class GeneralProperties extends StatelessWidget {
  const GeneralProperties({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final g = controller.globals;
    final e = controller.edits;
    final r = controller.resolved;
    final p = controller.presetOnly;
    final from = controller.preset.name;
    final theme = Theme.of(context);
    void set(VoidCallback f) => controller.update(f);
    const asStyle = 'style default';

    Widget hint(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );

    // Preset values, to position the sliders when they aren't set.
    final filled = p.buttons[ButtonKind.filled]!;
    final presetRadius = (filled.radius ?? ButtonKind.defaultRadius).clamp(
      0.0,
      24.0,
    );
    final presetHeight = filled.minHeight ?? ButtonKind.defaultMinHeight;

    return ListView(
      children: [
        PanelHeader(
          title: 'Global properties',
          subtitle: 'They apply to every component',
          action: TextButton.icon(
            onPressed: g.isEmpty ? null : () => set(g.reset),
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text('Reset'),
          ),
        ),
        hint(
          'They apply on top of the "$from" style. Whatever you change on a '
          'single component always wins over these choices. "Style default" '
          'keeps the preset values.',
        ),
        PropertySection(
          title: 'Shape',
          children: [
            NumberField(
              label: 'Radius',
              value: g.radius,
              defaultValue: presetRadius,
              defaultLabel: asStyle,
              min: 0,
              max: 24,
              unit: ' px',
              onChanged: (v) => set(() => g.radius = v),
            ),
            hint(
              g.radius == null
                  ? 'Buttons, fields, chips and tooltips use this radius; '
                        'cards, dialogs and menus 1.5×; checkboxes ¼.'
                  : 'Controls ${_px(g.radius!)} · cards and dialogs '
                        '${_px(containerRadius(g.radius!))} · checkboxes '
                        '${_px(smallRadius(g.radius!))}',
            ),
            ChoiceField<bool>(
              label: 'Pill-shaped buttons',
              value: g.pillButtons,
              defaultLabel: asStyle,
              options: const {true: 'Yes', false: 'No'},
              onChanged: (v) => set(() => g.pillButtons = v),
            ),
            NumberField(
              label: 'Border width',
              value: g.borderWidth,
              defaultValue: p.buttons[ButtonKind.outlined]!.borderWidth ?? 1,
              defaultLabel: asStyle,
              min: 0,
              max: 4,
              step: 0.5,
              unit: ' px',
              onChanged: (v) => set(() => g.borderWidth = v),
            ),
            hint('Applies to components that already have a border.'),
          ],
        ),
        PropertySection(
          title: 'Depth',
          children: [
            ChoiceField<ShadowStyle>(
              label: 'Shadows',
              value: g.shadowStyle,
              defaultLabel: asStyle,
              options: {
                for (final s in ShadowStyle.values) s: '${s.label} · ${s.hint}',
              },
              onChanged: (v) => set(() => g.shadowStyle = v),
            ),
            ChoiceField<int>(
              label: 'Intensity',
              value: g.shadowLevel,
              defaultLabel: asStyle,
              options: const {-1: 'Lighter', 0: 'Normal', 1: 'Stronger'},
              onChanged: (v) => set(() => g.shadowLevel = v),
            ),
            if (g.shadowStyle == ShadowStyle.hard)
              hint(
                'With hard shadows, cards, dialogs, menus, buttons and fields '
                'get a shadow even if the style had none.',
              ),
          ],
        ),
        PropertySection(
          title: 'Typography',
          children: [
            ChoiceField<String>(
              label: 'Font',
              value: e.fontFamily,
              inherited: r.fontFamily,
              inheritedFrom: from,
              defaultLabel: 'Roboto (default)',
              options: {for (final f in ThemeConfig.fontFamilies) f: f},
              onChanged: controller.setFont,
            ),
            ChoiceField<String>(
              label: 'Heading font',
              value: e.headFontFamily,
              inherited: r.headFontFamily,
              inheritedFrom: from,
              defaultLabel: 'same as the main font',
              options: {for (final f in ThemeConfig.fontFamilies) f: f},
              onChanged: controller.setHeadFont,
            ),
            if (fontsNote(r) case final note?) UsageCallout(note: note),
          ],
        ),
        PropertySection(
          title: 'Sizing',
          children: [
            NumberField(
              label: 'Button and field height',
              value: g.controlHeight,
              defaultValue: presetHeight,
              defaultLabel: asStyle,
              min: 28,
              max: 56,
              step: 2,
              unit: ' px',
              onChanged: (v) => set(() => g.controlHeight = v),
            ),
            ChoiceField<DensityOption>(
              label: 'Visual density',
              value: e.density,
              inherited: r.density,
              inheritedFrom: from,
              defaultLabel: 'Adaptive (compact on desktop)',
              options: {for (final d in DensityOption.values) d: d.label},
              onChanged: (v) => set(() => e.density = v),
            ),
            SwitchField(
              label: 'No 48px tap target',
              subtitle: 'MaterialTapTargetSize.shrinkWrap',
              value: r.shrinkWrapTapTargets,
              onChanged: (v) => set(() => e.shrinkWrapTapTargets = v),
            ),
          ],
        ),
        PropertySection(
          title: 'Motion',
          children: [
            ChoiceField<PressEffect>(
              label: 'On press',
              value: g.press,
              defaultLabel: asStyle,
              options: {
                for (final s in PressEffect.values) s: '${s.label} · ${s.hint}',
              },
              onChanged: (v) => set(() => g.press = v),
            ),
            NumberField(
              label: 'Transition duration',
              value: g.transitionMs,
              defaultValue:
                  filled.transitionMs ?? ButtonConfig.defaultTransitionMs,
              defaultLabel: asStyle,
              min: 0,
              max: 500,
              step: 10,
              unit: ' ms',
              onChanged: (v) => set(() => g.transitionMs = v),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

String _px(double v) => '${v.round()} px';
