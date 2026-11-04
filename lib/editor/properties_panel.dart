import 'package:flutter/material.dart';

import '../export/usage_notes.dart';
import '../model/color_ref.dart';
import '../model/presets.dart';
import '../model/shadow_token.dart';
import '../model/theme_builder.dart';
import '../model/theme_config.dart';
import 'editor_controller.dart';
import 'button_sizes_properties.dart';
import 'color_choice_section.dart';
import 'general_properties.dart';
import 'style_properties.dart';
import 'surface_properties.dart';
import 'text_field_properties.dart';
import 'typography_properties.dart';
import 'widgets/color_picker_dialog.dart';
import 'widgets/property_fields.dart';
import 'widgets/usage_callout.dart';

const fontWeightOptions = <FontWeight, String>{
  FontWeight.w300: 'Light (300)',
  FontWeight.w400: 'Regular (400)',
  FontWeight.w500: 'Medium (500)',
  FontWeight.w600: 'SemiBold (600)',
  FontWeight.w700: 'Bold (700)',
  FontWeight.w800: 'ExtraBold (800)',
};

const _variants = <DynamicSchemeVariant, String>{
  DynamicSchemeVariant.fidelity: 'Fidelity',
  DynamicSchemeVariant.content: 'Content',
  DynamicSchemeVariant.vibrant: 'Vibrant',
  DynamicSchemeVariant.expressive: 'Expressive',
  DynamicSchemeVariant.neutral: 'Neutral',
  DynamicSchemeVariant.monochrome: 'Monochrome',
  DynamicSchemeVariant.rainbow: 'Rainbow',
  DynamicSchemeVariant.fruitSalad: 'Fruit salad',
};

class PropertiesPanel extends StatelessWidget {
  const PropertiesPanel({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return switch (controller.selected) {
      GlobalSection() => _GlobalProperties(controller: controller),
      GeneralSection() => GeneralProperties(controller: controller),
      StyleSection() => StyleProperties(controller: controller),
      ButtonSection(:final kind) => _ButtonProperties(
        key: ValueKey(kind),
        controller: controller,
        kind: kind,
      ),
      TextFieldSection() => TextFieldProperties(controller: controller),
      TypographySection() => TypographyProperties(controller: controller),
      ButtonSizesSection() => ButtonSizesProperties(controller: controller),
      SurfaceSection(:final kind) => SurfaceProperties(
        key: ValueKey(kind),
        controller: controller,
        kind: kind,
      ),
    };
  }
}

class PanelHeader extends StatelessWidget {
  const PanelHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Global properties
// ---------------------------------------------------------------------------

class _GlobalProperties extends StatelessWidget {
  const _GlobalProperties({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    // e = user edits, r = result (preset + edits).
    final e = controller.edits;
    final r = controller.resolved;
    final pb = controller.presetOnly;
    final src = controller.sourceOf;
    final from = controller.preset.name;
    final theme = Theme.of(context);
    final lightScheme = buildColorScheme(r, Brightness.light);
    void set(VoidCallback f) => controller.update(f);

    final available = SchemeRole.values
        .where((role) => !e.schemeOverrides.containsKey(role))
        .toList();

    return ListView(
      children: [
        const PanelHeader(
          title: 'Colors',
          subtitle: 'ColorScheme · seed · roles',
        ),
        ColorChoiceSection(controller: controller),
        if (controller.preset.style == PresetStyle.material)
          ChoiceField<DynamicSchemeVariant>(
            label: 'Scheme variant',
            value: e.schemeVariant,
            inherited: r.schemeVariant,
            inheritedFrom: src(r.schemeVariant, pb.schemeVariant),
            defaultLabel: 'Tonal spot (default)',
            options: _variants,
            onChanged: (v) => set(() => e.schemeVariant = v),
          ),
        PropertySection(
          title: 'Role tweaks',
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                'Override a single scheme role: it wins over the generated '
                'colors.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final role in e.schemeOverrides.keys)
              ColorField(
                label: role.label,
                value: e.schemeOverrides[role],
                inherited: controller.base.schemeOverrides[role],
                inheritedFrom: from,
                scheme: lightScheme,
                allowRoles: false,
                dense: true,
                onChanged: (v) => set(() {
                  if (v == null) {
                    e.schemeOverrides.remove(role);
                  } else {
                    e.schemeOverrides[role] = v;
                  }
                }),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: MenuAnchor(
                  menuChildren: [
                    for (final role in available)
                      MenuItemButton(
                        leadingIcon: ColorSwatchDot(
                          color: role.resolve(lightScheme),
                          size: 16,
                        ),
                        onPressed: () async {
                          final picked = await showColorPicker(
                            context,
                            initial: CustomColor(role.resolve(lightScheme)),
                            scheme: lightScheme,
                            allowRoles: false,
                          );
                          if (picked != null) {
                            set(() => e.schemeOverrides[role] = picked);
                          }
                        },
                        child: Text(role.label),
                      ),
                  ],
                  builder: (context, menu, _) => TextButton.icon(
                    onPressed: available.isEmpty
                        ? null
                        : () => menu.isOpen ? menu.close() : menu.open(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Override a role'),
                  ),
                ),
              ),
            ),
          ],
        ),
        PropertySection(
          title: 'Resulting palette',
          children: [
            _SchemePalette(scheme: lightScheme, label: 'Light'),
            _SchemePalette(
              scheme: buildColorScheme(r, Brightness.dark),
              label: 'Dark',
            ),
          ],
        ),
      ],
    );
  }
}

class _SchemePalette extends StatelessWidget {
  const _SchemePalette({required this.scheme, required this.label});

  final ColorScheme scheme;
  final String label;

  @override
  Widget build(BuildContext context) {
    const roles = [
      SchemeRole.primary,
      SchemeRole.primaryContainer,
      SchemeRole.secondary,
      SchemeRole.tertiary,
      SchemeRole.error,
      SchemeRole.surface,
      SchemeRole.surfaceContainerLow,
      SchemeRole.surfaceContainerHighest,
      SchemeRole.onSurface,
      SchemeRole.outline,
      SchemeRole.outlineVariant,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                for (final r in roles)
                  Expanded(
                    child: Tooltip(
                      message: r.label,
                      child: Container(height: 32, color: r.resolve(scheme)),
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

// ---------------------------------------------------------------------------
// Button properties
// ---------------------------------------------------------------------------

class _ButtonProperties extends StatefulWidget {
  const _ButtonProperties({
    super.key,
    required this.controller,
    required this.kind,
  });

  final EditorController controller;
  final ButtonKind kind;

  @override
  State<_ButtonProperties> createState() => _ButtonPropertiesState();
}

class _ButtonPropertiesState extends State<_ButtonProperties> {
  ButtonStateKey _state = ButtonStateKey.normal;

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final controller = widget.controller;
    // e = user edits, r = result (preset + edits).
    final e = controller.edits.buttons[kind]!;
    final r = controller.resolved.buttons[kind]!;
    final pb = controller.presetOnly.buttons[kind]!;
    final src = controller.sourceOf;
    final scheme = buildColorScheme(controller.resolved, Brightness.light);
    final theme = Theme.of(context);
    void set(VoidCallback f) => controller.update(f);

    final st = e.states[_state]!;
    final rst = r.states[_state]!;
    final prst = pb.states[_state]!;
    // A preset gradient is "turned off" by setting end = start.
    final baseEnd = controller.base.buttons[kind]!.states[_state]!.fillEnd;
    final flattened =
        baseEnd != null && st.fillEnd != null && st.fillEnd == rst.fill;
    final hasGradient = rst.fillEnd != null && !flattened;
    final isNormal = _state == ButtonStateKey.normal;
    final isDisabled = _state == ButtonStateKey.disabled;
    // Effective values (with M3 defaults) to show what is being inherited.
    final eff = effectiveState(kind, r, _state);
    final inheritText = isNormal || isDisabled ? 'default M3' : 'as Normal';

    Color? shown(ColorRef? explicit, ColorRef? effective) =>
        explicit == null ? effective?.resolve(scheme) : null;

    return ListView(
      children: [
        PanelHeader(
          title: '${kind.label} button',
          subtitle: kind.isExtra
              ? 'AppButtonStyles · context.buttonStyle(AppButtonKind.${kind.name})'
              : r.needsSkin
              ? '${kind.themeData} · styleFrom + ButtonSkin'
              : '${kind.themeData} · styleFrom',
          action: TextButton.icon(
            onPressed: e.isEmpty ? null : () => set(e.reset),
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text('Reset'),
          ),
        ),
        if (kind.isExtra) UsageCallout(note: buttonExtraNote(kind)),
        PropertySection(
          title: 'State',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in ButtonStateKey.values)
                    ChoiceChip(
                      label: Text(s.label),
                      selected: s == _state,
                      visualDensity: VisualDensity.compact,
                      avatar: e.states[s]!.isEmpty
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
                  isDisabled
                      ? "Without explicit values, Material 3's disabled "
                            "colors are used."
                      : "Empty values inherit from the Normal state. If the "
                            "background is not set, Material 3's state layer is "
                            "applied.",
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
              label: hasGradient ? 'Background (gradient start)' : 'Background',
              value: st.fill,
              inherited: rst.fill,
              inheritedFrom: src(rst.fill, prst.fill),
              scheme: scheme,
              defaultColor: shown(st.fill, eff.fill),
              defaultText: eff.fill == null && isNormal
                  ? 'transparent'
                  : inheritText,
              onChanged: (v) => set(() {
                st.fill = v;
                if (v == null) st.fillEnd = null;
              }),
            ),
            if (kind.allowsSkin)
              SwitchField(
                label: 'Vertical gradient',
                subtitle: rst.fill == null ? 'Set the background first' : null,
                value: hasGradient,
                onChanged: rst.fill == null
                    ? (_) {}
                    : (on) => set(
                        () => st.fillEnd = baseEnd != null
                            // Preset gradient: on = inherit,
                            // off = end equal to the start.
                            ? (on ? null : rst.fill)
                            : (on ? rst.fill : null),
                      ),
              ),
            if (hasGradient)
              ColorField(
                label: 'Background (gradient end)',
                value: st.fillEnd,
                inherited: rst.fillEnd,
                inheritedFrom: src(rst.fillEnd, prst.fillEnd),
                scheme: scheme,
                onChanged: (v) => set(() => st.fillEnd = v),
              ),
            ColorField(
              label: 'Text and icon',
              value: st.foreground,
              inherited: rst.foreground,
              inheritedFrom: src(rst.foreground, prst.foreground),
              scheme: scheme,
              defaultColor: shown(st.foreground, eff.foreground),
              defaultText: inheritText,
              onChanged: (v) => set(() => st.foreground = v),
            ),
            ColorField(
              label: 'Border',
              value: st.border,
              inherited: rst.border,
              inheritedFrom: src(rst.border, prst.border),
              scheme: scheme,
              defaultColor: shown(st.border, eff.border),
              defaultText: inheritText,
              onChanged: (v) => set(() => st.border = v),
            ),
            if (kind.allowsSkin)
              ChoiceField<ShadowToken>(
                label: 'Shadow (box-shadow)',
                value: st.shadow,
                inherited: rst.shadow,
                inheritedFrom: src(rst.shadow, prst.shadow),
                defaultLabel: isNormal
                    ? (kind.m3Shadow == null
                          ? 'None (default)'
                          : '${kind.m3Shadow!.label} (default)')
                    : isDisabled
                    ? 'None (default)'
                    : 'As Normal',
                options: {for (final t in ShadowToken.values) t: t.label},
                onChanged: (v) => set(() => st.shadow = v),
              ),
            if (kind.allowsSkin)
              ColorField(
                label: 'Shadow color (if hard)',
                value: st.shadowColor,
                inherited: rst.shadowColor,
                inheritedFrom: src(rst.shadowColor, prst.shadowColor),
                scheme: scheme,
                defaultText: isNormal ? 'outline' : 'as Normal',
                onChanged: (v) => set(() => st.shadowColor = v),
              ),
            if (kind.allowsSkin)
              NumberField(
                label: 'Offset X',
                value: st.offsetX,
                inherited: rst.offsetX,
                inheritedFrom: src(rst.offsetX, prst.offsetX),
                defaultValue: 0,
                min: -12,
                max: 12,
                unit: ' px',
                onChanged: (v) => set(() => st.offsetX = v),
              ),
            if (kind.allowsSkin)
              NumberField(
                label: 'Offset Y',
                value: st.offsetY,
                inherited: rst.offsetY,
                inheritedFrom: src(rst.offsetY, prst.offsetY),
                defaultValue: 0,
                min: -12,
                max: 12,
                unit: ' px',
                onChanged: (v) => set(() => st.offsetY = v),
              ),
          ],
        ),
        PropertySection(
          title: 'Shape',
          children: [
            NumberField(
              label: 'Corner radius',
              value: e.radius,
              inherited: r.radius,
              inheritedFrom: src(r.radius, pb.radius),
              defaultValue: ButtonKind.defaultRadius,
              defaultLabel: 'default · pill',
              min: 0,
              max: 32,
              unit: ' px',
              onChanged: (v) => set(() => e.radius = v),
            ),
            NumberField(
              label: 'Border width',
              value: e.borderWidth,
              inherited: r.borderWidth,
              inheritedFrom: src(r.borderWidth, pb.borderWidth),
              defaultValue: kind.defaultBorderWidth,
              min: 0,
              max: 4,
              step: 0.5,
              unit: ' px',
              onChanged: (v) => set(() => e.borderWidth = v),
            ),
          ],
        ),
        PropertySection(
          title: 'Sizing',
          children: [
            NumberField(
              label: 'Horizontal padding',
              value: e.paddingH,
              inherited: r.paddingH,
              inheritedFrom: src(r.paddingH, pb.paddingH),
              defaultValue: kind.defaultPaddingH,
              min: 0,
              max: 48,
              unit: ' px',
              onChanged: (v) => set(() => e.paddingH = v),
            ),
            NumberField(
              label: 'Vertical padding',
              value: e.paddingV,
              inherited: r.paddingV,
              inheritedFrom: src(r.paddingV, pb.paddingV),
              defaultValue: kind.defaultPaddingV,
              min: 0,
              max: 24,
              unit: ' px',
              onChanged: (v) => set(() => e.paddingV = v),
            ),
            NumberField(
              label: 'Minimum height',
              value: e.minHeight,
              inherited: r.minHeight,
              inheritedFrom: src(r.minHeight, pb.minHeight),
              defaultValue: ButtonKind.defaultMinHeight,
              min: 20,
              max: 72,
              unit: ' px',
              onChanged: (v) => set(() => e.minHeight = v),
            ),
            NumberField(
              label: 'Minimum width',
              value: e.minWidth,
              inherited: r.minWidth,
              inheritedFrom: src(r.minWidth, pb.minWidth),
              defaultValue: kind.m3MinWidth,
              min: 0,
              max: 160,
              unit: ' px',
              onChanged: (v) => set(() => e.minWidth = v),
            ),
            NumberField(
              label: 'Icon size',
              value: e.iconSize,
              inherited: r.iconSize,
              inheritedFrom: src(r.iconSize, pb.iconSize),
              defaultValue: kind.m3IconSize,
              min: 12,
              max: 32,
              unit: ' px',
              onChanged: (v) => set(() => e.iconSize = v),
            ),
          ],
        ),
        if (!kind.isIconOnly)
          PropertySection(
            title: 'Text',
            children: [
              NumberField(
                label: 'Font size',
                value: e.fontSize,
                inherited: r.fontSize,
                inheritedFrom: src(r.fontSize, pb.fontSize),
                defaultValue: ButtonKind.defaultFontSize,
                min: 10,
                max: 24,
                unit: ' px',
                onChanged: (v) => set(() => e.fontSize = v),
              ),
              NumberField(
                label: 'Line height',
                value: e.lineHeight,
                inherited: r.lineHeight,
                inheritedFrom: src(r.lineHeight, pb.lineHeight),
                defaultValue: 20,
                defaultLabel: 'default · labelLarge',
                min: 10,
                max: 32,
                unit: ' px',
                onChanged: (v) => set(() => e.lineHeight = v),
              ),
              NumberField(
                label: 'Letter spacing',
                value: e.letterSpacing,
                inherited: r.letterSpacing,
                inheritedFrom: src(r.letterSpacing, pb.letterSpacing),
                defaultValue: ButtonKind.defaultLetterSpacing,
                min: -1,
                max: 3,
                step: 0.1,
                onChanged: (v) => set(() => e.letterSpacing = v),
              ),
              SwitchField(
                label: 'Heading font',
                subtitle: 'Use the heading font for the label',
                value: r.headFont ?? false,
                onChanged: (v) => set(() => e.headFont = v),
              ),
              if (!kind.allowsSkin)
                SwitchField(
                  label: 'Underline on hover',
                  subtitle: 'Like a link',
                  value: r.hoverUnderline ?? false,
                  onChanged: (v) => set(() => e.hoverUnderline = v),
                ),
              ChoiceField<FontWeight>(
                label: 'Font weight',
                value: e.fontWeight,
                inherited: r.fontWeight,
                inheritedFrom: src(r.fontWeight, pb.fontWeight),
                defaultLabel: 'Medium (500) · default',
                options: fontWeightOptions,
                onChanged: (v) => set(() => e.fontWeight = v),
              ),
            ],
          ),
        if (!kind.allowsSkin)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'TextButton only has per-state colors: no gradients, shadows, '
              'press effect or focus ring. Flutter uses it inside menu items, '
              'the SnackBar action and the copy/paste toolbar, which would '
              'inherit those effects. For a text button with a background use '
              'the Ghost extra style.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (kind.allowsSkin)
          PropertySection(
            title: 'Effects',
            children: [
              NumberField(
                label: 'Scale on press',
                value: e.pressScale,
                inherited: r.pressScale,
                inheritedFrom: src(r.pressScale, pb.pressScale),
                defaultValue: 1,
                defaultLabel: 'none',
                min: 0.9,
                max: 1,
                step: 0.01,
                decimals: 2,
                onChanged: (v) => set(() => e.pressScale = v),
              ),
              NumberField(
                label: 'Transition duration',
                value: e.transitionMs,
                inherited: r.transitionMs,
                inheritedFrom: src(r.transitionMs, pb.transitionMs),
                defaultValue: ButtonConfig.defaultTransitionMs,
                min: 0,
                max: 500,
                step: 10,
                unit: ' ms',
                onChanged: (v) => set(() => e.transitionMs = v),
              ),
              ColorField(
                label: 'Focus ring',
                value: e.focusRing,
                inherited: r.focusRing,
                inheritedFrom: src(r.focusRing, pb.focusRing),
                scheme: scheme,
                defaultText: 'none',
                onChanged: (v) => set(() => e.focusRing = v),
              ),
              if (r.focusRing != null) ...[
                NumberField(
                  label: 'Focus ring width',
                  value: e.focusRingWidth,
                  inherited: r.focusRingWidth,
                  inheritedFrom: src(r.focusRingWidth, pb.focusRingWidth),
                  defaultValue: ButtonConfig.defaultFocusRingWidth,
                  min: 1,
                  max: 6,
                  step: 0.5,
                  unit: ' px',
                  onChanged: (v) => set(() => e.focusRingWidth = v),
                ),
                NumberField(
                  label: 'Focus ring gap',
                  value: e.focusRingOffset,
                  inherited: r.focusRingOffset,
                  inheritedFrom: src(r.focusRingOffset, pb.focusRingOffset),
                  defaultValue: ButtonConfig.defaultFocusRingOffset,
                  min: 0,
                  max: 6,
                  step: 0.5,
                  unit: ' px',
                  onChanged: (v) => set(() => e.focusRingOffset = v),
                ),
                ColorField(
                  label: 'Gap color',
                  value: e.focusRingOffsetColor,
                  inherited: r.focusRingOffsetColor,
                  inheritedFrom: src(
                    r.focusRingOffsetColor,
                    pb.focusRingOffsetColor,
                  ),
                  scheme: scheme,
                  defaultText: 'transparent',
                  onChanged: (v) => set(() => e.focusRingOffsetColor = v),
                ),
              ],
            ],
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}
