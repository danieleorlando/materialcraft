import 'package:flutter/material.dart';

import '../export/usage_notes.dart';
import '../model/theme_config.dart';
import 'editor_controller.dart';
import 'properties_panel.dart';
import 'widgets/property_fields.dart';
import 'widgets/usage_callout.dart';

/// Small / xs sizes: geometry shared by all labelled buttons.
class ButtonSizesProperties extends StatelessWidget {
  const ButtonSizesProperties({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = controller.edits;
    final r = controller.resolved;
    void set(VoidCallback f) => controller.update(f);
    // The defaults shown are the FilledButton's (medium size).
    final medium = r.buttons[ButtonKind.filled]!;

    return ListView(
      children: [
        const PanelHeader(
          title: 'Sizes',
          subtitle: 'AppButtonStyles · context.buttonStyle(kind, size:)',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            "Medium is the size defined by each button's theme. Large, small "
            "and xs only change the geometry: colors, states and effects stay "
            "those of the button. Empty fields inherit from medium.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        UsageCallout(note: buttonSizesNote()),
        for (final key in ButtonSizeKey.values)
          _SizeSection(
            title: key.label,
            spec: c.buttonSizes[key]!,
            inherited: r.buttonSizes[key]!,
            presetSpec: controller.presetOnly.buttonSizes[key]!,
            src: controller.sourceOf,
            medium: medium,
            set: set,
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SizeSection extends StatelessWidget {
  const _SizeSection({
    required this.title,
    required this.spec,
    required this.inherited,
    required this.presetSpec,
    required this.src,
    required this.medium,
    required this.set,
  });

  final String title;
  final ButtonSizeSpec spec;

  /// Resolved size (preset + edits): shows the inherited values.
  final ButtonSizeSpec inherited;
  final ButtonSizeSpec presetSpec;
  final String Function(Object?, Object?) src;
  final ButtonConfig medium;
  final void Function(VoidCallback) set;

  @override
  Widget build(BuildContext context) {
    return PropertySection(
      title: title,
      children: [
        NumberField(
          label: 'Minimum height',
          value: spec.minHeight,
          inherited: inherited.minHeight,
          inheritedFrom: src(inherited.minHeight, presetSpec.minHeight),
          defaultValue: medium.minHeight ?? ButtonKind.defaultMinHeight,
          min: 16,
          max: 56,
          unit: ' px',
          onChanged: (v) => set(() => spec.minHeight = v),
        ),
        NumberField(
          label: 'Radius',
          value: spec.radius,
          inherited: inherited.radius,
          inheritedFrom: src(inherited.radius, presetSpec.radius),
          defaultValue: medium.radius ?? ButtonKind.defaultRadius,
          min: 0,
          max: 28,
          unit: ' px',
          onChanged: (v) => set(() => spec.radius = v),
        ),
        NumberField(
          label: 'Horizontal padding',
          value: spec.paddingH,
          inherited: inherited.paddingH,
          inheritedFrom: src(inherited.paddingH, presetSpec.paddingH),
          defaultValue: medium.paddingH ?? ButtonKind.filled.defaultPaddingH,
          min: 0,
          max: 32,
          unit: ' px',
          onChanged: (v) => set(() => spec.paddingH = v),
        ),
        NumberField(
          label: 'Vertical padding',
          value: spec.paddingV,
          inherited: inherited.paddingV,
          inheritedFrom: src(inherited.paddingV, presetSpec.paddingV),
          defaultValue: medium.paddingV ?? ButtonKind.filled.defaultPaddingV,
          min: 0,
          max: 16,
          unit: ' px',
          onChanged: (v) => set(() => spec.paddingV = v),
        ),
        NumberField(
          label: 'Icon size',
          value: spec.iconSize,
          inherited: inherited.iconSize,
          inheritedFrom: src(inherited.iconSize, presetSpec.iconSize),
          defaultValue: medium.iconSize ?? ButtonKind.filled.m3IconSize,
          min: 10,
          max: 24,
          unit: ' px',
          onChanged: (v) => set(() => spec.iconSize = v),
        ),
        NumberField(
          label: 'Font size',
          value: spec.fontSize,
          inherited: inherited.fontSize,
          inheritedFrom: src(inherited.fontSize, presetSpec.fontSize),
          defaultValue: medium.fontSize ?? ButtonKind.defaultFontSize,
          min: 9,
          max: 18,
          unit: ' px',
          onChanged: (v) => set(() => spec.fontSize = v),
        ),
        NumberField(
          label: 'Line height',
          value: spec.lineHeight,
          inherited: inherited.lineHeight,
          inheritedFrom: src(inherited.lineHeight, presetSpec.lineHeight),
          defaultValue: medium.lineHeight ?? 20,
          min: 10,
          max: 28,
          unit: ' px',
          onChanged: (v) => set(() => spec.lineHeight = v),
        ),
        NumberField(
          label: 'Letter spacing',
          value: spec.letterSpacing,
          inherited: inherited.letterSpacing,
          inheritedFrom: src(inherited.letterSpacing, presetSpec.letterSpacing),
          defaultValue: medium.letterSpacing ?? ButtonKind.defaultLetterSpacing,
          min: -1,
          max: 2,
          step: 0.05,
          decimals: 2,
          onChanged: (v) => set(() => spec.letterSpacing = v),
        ),
        ChoiceField<FontWeight>(
          label: 'Font weight',
          value: spec.fontWeight,
          inherited: inherited.fontWeight,
          inheritedFrom: src(inherited.fontWeight, presetSpec.fontWeight),
          defaultLabel: 'as medium',
          options: fontWeightOptions,
          onChanged: (v) => set(() => spec.fontWeight = v),
        ),
      ],
    );
  }
}
