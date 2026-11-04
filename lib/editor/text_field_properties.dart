import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../model/shadow_token.dart';
import '../model/text_field_config.dart';
import '../model/theme_builder.dart';
import 'editor_controller.dart';
import 'properties_panel.dart';
import 'widgets/property_fields.dart';

class TextFieldProperties extends StatefulWidget {
  const TextFieldProperties({super.key, required this.controller});

  final EditorController controller;

  @override
  State<TextFieldProperties> createState() => _TextFieldPropertiesState();
}

class _TextFieldPropertiesState extends State<TextFieldProperties> {
  FieldStateKey _state = FieldStateKey.normal;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    // f = user edits, rf = result (preset + edits).
    final f = controller.edits.textField;
    final rf = controller.resolved.textField;
    final pf = controller.presetOnly.textField;
    final src = controller.sourceOf;
    final scheme = buildColorScheme(controller.resolved, Brightness.light);
    final theme = Theme.of(context);
    final view = rf.view;
    void set(VoidCallback fn) => controller.update(fn);

    final st = f.states[_state]!;
    final rst = rf.states[_state]!;
    final prst = pf.states[_state]!;
    final isNormal = _state == FieldStateKey.normal;
    final inheritText = isNormal ? 'default M3' : 'as Normal';

    // Resulting height of a single-line field without a label.
    final lineHeight = rf.inputLineHeight ?? TextFieldConfig.m3InputLineHeight;
    final pv = rf.paddingV ?? TextFieldConfig.m3PaddingV;
    final height = math.max(
      pv * 2 + lineHeight,
      (rf.dense ?? false) ? 0.0 : kMinInteractiveDimension,
    );

    return ListView(
      children: [
        PanelHeader(
          title: 'Text field',
          subtitle: 'InputDecorationTheme · textTheme.bodyLarge',
          action: TextButton.icon(
            onPressed: f.isEmpty ? null : () => set(f.reset),
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text('Reset'),
          ),
        ),
        PropertySection(
          title: 'State',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in FieldStateKey.values)
                    ChoiceChip(
                      label: Text(s.label),
                      selected: s == _state,
                      visualDensity: VisualDensity.compact,
                      avatar: f.states[s]!.isEmpty
                          ? null
                          : Icon(
                              Icons.circle,
                              size: 8,
                              color: theme.colorScheme.primary,
                            ),
                      onSelected: (_) => setState(() => _state = s),
                    ),
                ],
              ),
            ),
            if (!isNormal)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'Background, placeholder and icons inherit from the Normal '
                  'state; the border has a Material 3 default for each state. '
                  'Precedence: Disabled › Error › Focus › Hover.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
        PropertySection(
          title: 'Colors · ${_state.label}',
          children: [
            ColorField(
              label: 'Background',
              value: st.fill,
              inherited: rst.fill,
              inheritedFrom: src(rst.fill, prst.fill),
              scheme: scheme,
              defaultColor: st.fill == null
                  ? view.fill(_state)?.resolve(scheme)
                  : null,
              defaultText: view.fill(_state) == null
                  ? 'none (not filled)'
                  : inheritText,
              onChanged: (v) => set(() => st.fill = v),
            ),
            ColorField(
              label: 'Border',
              value: st.border,
              inherited: rst.border,
              inheritedFrom: src(rst.border, prst.border),
              scheme: scheme,
              defaultColor: st.border == null
                  ? view.border(_state).resolve(scheme)
                  : null,
              defaultText: 'default M3',
              onChanged: (v) => set(() => st.border = v),
            ),
            NumberField(
              label: 'Border width',
              value: st.borderWidth,
              inherited: rst.borderWidth,
              inheritedFrom: src(rst.borderWidth, prst.borderWidth),
              defaultValue: view.borderWidth(_state),
              min: 0,
              max: 4,
              step: 0.5,
              unit: ' px',
              onChanged: (v) => set(() => st.borderWidth = v),
            ),
            ColorField(
              label: 'Placeholder (hint)',
              value: st.placeholder,
              inherited: rst.placeholder,
              inheritedFrom: src(rst.placeholder, prst.placeholder),
              scheme: scheme,
              defaultColor: st.placeholder == null
                  ? fieldPlaceholder(rf, _state).resolve(scheme)
                  : null,
              defaultText: inheritText,
              onChanged: (v) => set(() => st.placeholder = v),
            ),
            ChoiceField<ShadowToken>(
              label: 'Shadow',
              value: st.shadow,
              inherited: rst.shadow,
              inheritedFrom: src(rst.shadow, prst.shadow),
              defaultLabel: isNormal ? 'none' : 'as Normal',
              options: {for (final t in ShadowToken.values) t: t.label},
              onChanged: (v) => set(() => st.shadow = v),
            ),
            ColorField(
              label: 'Shadow color',
              value: st.shadowColor,
              inherited: rst.shadowColor,
              inheritedFrom: src(rst.shadowColor, prst.shadowColor),
              scheme: scheme,
              defaultText: isNormal ? 'outline' : 'as Normal',
              onChanged: (v) => set(() => st.shadowColor = v),
            ),
            ColorField(
              label: 'Icons (prefix / suffix)',
              value: st.icon,
              inherited: rst.icon,
              inheritedFrom: src(rst.icon, prst.icon),
              scheme: scheme,
              defaultColor: st.icon == null
                  ? fieldIcon(rf, _state).resolve(scheme)
                  : null,
              defaultText: inheritText,
              onChanged: (v) => set(() => st.icon = v),
            ),
          ],
        ),
        PropertySection(
          title: 'Shape and size',
          children: [
            NumberField(
              label: 'Corner radius',
              value: f.radius,
              inherited: rf.radius,
              inheritedFrom: src(rf.radius, pf.radius),
              defaultValue: TextFieldConfig.m3Radius,
              min: 0,
              max: 28,
              unit: ' px',
              onChanged: (v) => set(() => f.radius = v),
            ),
            SwitchField(
              label: 'Bottom border only',
              subtitle: 'UnderlineInputBorder, no box',
              value: rf.underline ?? false,
              onChanged: (v) => set(() => f.underline = v),
            ),
            SwitchField(
              label: 'Dense (isDense)',
              subtitle: 'No 48px minimum height; 18px icons',
              value: rf.dense ?? false,
              onChanged: (v) => set(() => f.dense = v),
            ),
            NumberField(
              label: 'Text inset',
              value: f.textInset,
              inherited: rf.textInset,
              inheritedFrom: src(rf.textInset, pf.textInset),
              defaultValue: TextFieldConfig.m3TextInset,
              min: 0,
              max: 32,
              unit: ' px',
              onChanged: (v) => set(() => f.textInset = v),
            ),
            NumberField(
              label: 'Right padding',
              value: f.paddingEnd,
              inherited: rf.paddingEnd,
              inheritedFrom: src(rf.paddingEnd, pf.paddingEnd),
              defaultValue: TextFieldConfig.m3PaddingEnd,
              min: 0,
              max: 32,
              unit: ' px',
              onChanged: (v) => set(() => f.paddingEnd = v),
            ),
            NumberField(
              label: 'Vertical padding',
              value: f.paddingV,
              inherited: rf.paddingV,
              inheritedFrom: src(rf.paddingV, pf.paddingV),
              defaultValue: TextFieldConfig.m3PaddingV,
              min: 0,
              max: 24,
              unit: ' px',
              onChanged: (v) => set(() => f.paddingV = v),
            ),
            NumberField(
              label: 'Icon area',
              value: f.iconBox,
              inherited: rf.iconBox,
              inheritedFrom: src(rf.iconBox, pf.iconBox),
              defaultValue: TextFieldConfig.m3IconBox,
              min: 16,
              max: 56,
              unit: ' px',
              onChanged: (v) => set(() => f.iconBox = v),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(
                'Resulting height (one line, no label): ${height.round()} px',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        PropertySection(
          title: 'Typed text',
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                'Flutter takes the field text style from textTheme.bodyLarge: '
                'the change also applies to the other widgets that use it.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            NumberField(
              label: 'Font size',
              value: f.inputFontSize,
              inherited: rf.inputFontSize,
              inheritedFrom: src(rf.inputFontSize, pf.inputFontSize),
              defaultValue: TextFieldConfig.m3InputFontSize,
              min: 10,
              max: 24,
              unit: ' px',
              onChanged: (v) => set(() => f.inputFontSize = v),
            ),
            NumberField(
              label: 'Line height',
              value: f.inputLineHeight,
              inherited: rf.inputLineHeight,
              inheritedFrom: src(rf.inputLineHeight, pf.inputLineHeight),
              defaultValue: TextFieldConfig.m3InputLineHeight,
              min: 12,
              max: 32,
              unit: ' px',
              onChanged: (v) => set(() => f.inputLineHeight = v),
            ),
            NumberField(
              label: 'Letter spacing',
              value: f.inputLetterSpacing,
              inherited: rf.inputLetterSpacing,
              inheritedFrom: src(rf.inputLetterSpacing, pf.inputLetterSpacing),
              defaultValue: TextFieldConfig.m3InputLetterSpacing,
              min: -1,
              max: 2,
              step: 0.05,
              decimals: 2,
              onChanged: (v) => set(() => f.inputLetterSpacing = v),
            ),
            ChoiceField<FontWeight>(
              label: 'Font weight',
              value: f.inputWeight,
              inherited: rf.inputWeight,
              inheritedFrom: src(rf.inputWeight, pf.inputWeight),
              defaultLabel: 'Regular (400) · default',
              options: fontWeightOptions,
              onChanged: (v) => set(() => f.inputWeight = v),
            ),
            ColorField(
              label: 'Text color',
              value: f.inputColor,
              inherited: rf.inputColor,
              inheritedFrom: src(rf.inputColor, pf.inputColor),
              scheme: scheme,
              defaultColor: scheme.onSurface,
              onChanged: (v) => set(() => f.inputColor = v),
            ),
            ColorField(
              label: 'Cursor',
              value: f.cursor,
              inherited: rf.cursor,
              inheritedFrom: src(rf.cursor, pf.cursor),
              scheme: scheme,
              defaultColor: scheme.primary,
              onChanged: (v) => set(() => f.cursor = v),
            ),
          ],
        ),
        PropertySection(
          title: 'Helper and error text',
          children: [
            NumberField(
              label: 'Font size',
              value: f.helperFontSize,
              inherited: rf.helperFontSize,
              inheritedFrom: src(rf.helperFontSize, pf.helperFontSize),
              defaultValue: TextFieldConfig.m3HelperFontSize,
              min: 9,
              max: 18,
              unit: ' px',
              onChanged: (v) => set(() => f.helperFontSize = v),
            ),
            NumberField(
              label: 'Letter spacing',
              value: f.helperLetterSpacing,
              inherited: rf.helperLetterSpacing,
              inheritedFrom: src(
                rf.helperLetterSpacing,
                pf.helperLetterSpacing,
              ),
              defaultValue: TextFieldConfig.m3HelperLetterSpacing,
              min: -1,
              max: 2,
              step: 0.05,
              decimals: 2,
              onChanged: (v) => set(() => f.helperLetterSpacing = v),
            ),
            ChoiceField<FontWeight>(
              label: 'Font weight',
              value: f.helperWeight,
              inherited: rf.helperWeight,
              inheritedFrom: src(rf.helperWeight, pf.helperWeight),
              defaultLabel: 'Regular (400) · default',
              options: fontWeightOptions,
              onChanged: (v) => set(() => f.helperWeight = v),
            ),
            ColorField(
              label: 'Helper color (helperText)',
              value: f.helperColor,
              inherited: rf.helperColor,
              inheritedFrom: src(rf.helperColor, pf.helperColor),
              scheme: scheme,
              defaultColor: scheme.onSurfaceVariant,
              onChanged: (v) => set(() => f.helperColor = v),
            ),
            ColorField(
              label: 'Error color (errorText)',
              value: f.errorColor,
              inherited: rf.errorColor,
              inheritedFrom: src(rf.errorColor, pf.errorColor),
              scheme: scheme,
              defaultColor: scheme.error,
              onChanged: (v) => set(() => f.errorColor = v),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
