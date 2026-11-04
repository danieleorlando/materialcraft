import 'package:flutter/material.dart';

import '../export/usage_notes.dart';
import '../model/shadow_token.dart';
import '../model/surface_config.dart';
import '../model/theme_builder.dart';
import '../model/typography_config.dart';
import 'editor_controller.dart';
import 'properties_panel.dart';
import 'widgets/property_fields.dart';
import 'widgets/usage_callout.dart';

/// Properties of a container (card, dialog, AppBar, …): shows only the fields
/// that component supports.
class SurfaceProperties extends StatelessWidget {
  const SurfaceProperties({
    super.key,
    required this.controller,
    required this.kind,
  });

  final EditorController controller;
  final SurfaceKind kind;

  @override
  Widget build(BuildContext context) {
    // s = user edits, rs = result (preset + edits).
    final s = controller.edits.surfaces[kind]!;
    final rs = controller.resolved.surfaces[kind]!;
    final ps = controller.presetOnly.surfaces[kind]!;
    final src = controller.sourceOf;
    final scheme = buildColorScheme(controller.resolved, Brightness.light);
    void set(VoidCallback f) => controller.update(f);

    final roles = {for (final r in TextRole.values) r: r.label};

    Widget field(SurfaceProp p, String label) => switch (p) {
      SurfaceProp.background => ColorField(
        label: label,
        value: s.background,
        inherited: rs.background,
        inheritedFrom: src(rs.background, ps.background),
        scheme: scheme,
        onChanged: (v) => set(() => s.background = v),
      ),
      SurfaceProp.foreground => ColorField(
        label: label,
        value: s.foreground,
        inherited: rs.foreground,
        inheritedFrom: src(rs.foreground, ps.foreground),
        scheme: scheme,
        onChanged: (v) => set(() => s.foreground = v),
      ),
      SurfaceProp.borderColor => ColorField(
        label: label,
        value: s.borderColor,
        inherited: rs.borderColor,
        inheritedFrom: src(rs.borderColor, ps.borderColor),
        scheme: scheme,
        defaultColor: rs.borderColor == null && rs.borderWidth != null
            ? scheme.outlineVariant
            : null,
        defaultText: rs.borderWidth != null ? 'outlineVariant' : 'none',
        onChanged: (v) => set(() => s.borderColor = v),
      ),
      SurfaceProp.accent => ColorField(
        label: label,
        value: s.accent,
        inherited: rs.accent,
        inheritedFrom: src(rs.accent, ps.accent),
        scheme: scheme,
        onChanged: (v) => set(() => s.accent = v),
      ),
      SurfaceProp.borderWidth => NumberField(
        label: label,
        value: s.borderWidth,
        inherited: rs.borderWidth,
        inheritedFrom: src(rs.borderWidth, ps.borderWidth),
        defaultValue: kind == SurfaceKind.divider ? 1 : 0,
        min: 0,
        max: 4,
        step: 0.5,
        unit: ' px',
        onChanged: (v) => set(() => s.borderWidth = v),
      ),
      SurfaceProp.radius => NumberField(
        label: label,
        value: s.radius,
        inherited: rs.radius,
        inheritedFrom: src(rs.radius, ps.radius),
        defaultValue: kind.m3Radius,
        min: 0,
        max: 40,
        unit: ' px',
        onChanged: (v) => set(() => s.radius = v),
      ),
      SurfaceProp.elevation => NumberField(
        label: label,
        value: s.elevation,
        inherited: rs.elevation,
        inheritedFrom: src(rs.elevation, ps.elevation),
        defaultValue: kind.m3Elevation,
        min: 0,
        max: 12,
        step: 0.5,
        onChanged: (v) => set(() => s.elevation = v),
      ),
      SurfaceProp.height => NumberField(
        label: label,
        value: s.height,
        inherited: rs.height,
        inheritedFrom: src(rs.height, ps.height),
        defaultValue: switch (kind) {
          SurfaceKind.badge => 16,
          SurfaceKind.switchControl => 32,
          _ => 80,
        },
        min: switch (kind) {
          SurfaceKind.badge => 10,
          SurfaceKind.switchControl => 16,
          _ => 48,
        },
        max: switch (kind) {
          SurfaceKind.badge => 28,
          SurfaceKind.switchControl => 48,
          _ => 96,
        },
        unit: ' px',
        onChanged: (v) => set(() => s.height = v),
      ),
      SurfaceProp.titleStyle => ChoiceField<TextRole>(
        label: label,
        value: s.titleStyle,
        inherited: rs.titleStyle,
        inheritedFrom: src(rs.titleStyle, ps.titleStyle),
        options: roles,
        defaultLabel: 'default M3',
        onChanged: (v) => set(() => s.titleStyle = v),
      ),
      SurfaceProp.selectedForeground => ColorField(
        label: label,
        value: s.selectedForeground,
        inherited: rs.selectedForeground,
        inheritedFrom: src(rs.selectedForeground, ps.selectedForeground),
        scheme: scheme,
        onChanged: (v) => set(() => s.selectedForeground = v),
      ),
      SurfaceProp.shadowColor => ColorField(
        label: label,
        value: s.shadowColor,
        inherited: rs.shadowColor,
        inheritedFrom: src(rs.shadowColor, ps.shadowColor),
        scheme: scheme,
        defaultText: 'outline',
        onChanged: (v) => set(() => s.shadowColor = v),
      ),
      SurfaceProp.accentEnd => ColorField(
        label: label,
        value: s.accentEnd,
        inherited: rs.accentEnd,
        inheritedFrom: src(rs.accentEnd, ps.accentEnd),
        scheme: scheme,
        defaultText: 'none (solid fill)',
        onChanged: (v) => set(() => s.accentEnd = v),
      ),
      SurfaceProp.shadow => ChoiceField<ShadowToken>(
        label: label,
        value: s.shadow,
        inherited: rs.shadow,
        inheritedFrom: src(rs.shadow, ps.shadow),
        options: {for (final t in ShadowToken.values) t: t.label},
        defaultLabel: 'None (default)',
        onChanged: (v) => set(() => s.shadow = v),
      ),
      SurfaceProp.paddingH => NumberField(
        label: label,
        value: s.paddingH,
        inherited: rs.paddingH,
        inheritedFrom: src(rs.paddingH, ps.paddingH),
        defaultValue: 8,
        min: 0,
        max: 32,
        unit: ' px',
        onChanged: (v) => set(() => s.paddingH = v),
      ),
      SurfaceProp.paddingV => NumberField(
        label: label,
        value: s.paddingV,
        inherited: rs.paddingV,
        inheritedFrom: src(rs.paddingV, ps.paddingV),
        defaultValue: kind == SurfaceKind.menu ? 12 : 4,
        min: 0,
        max: 24,
        unit: ' px',
        onChanged: (v) => set(() => s.paddingV = v),
      ),
      SurfaceProp.innerRadius => NumberField(
        label: label,
        value: s.innerRadius,
        inherited: rs.innerRadius,
        inheritedFrom: src(rs.innerRadius, ps.innerRadius),
        defaultValue: 0,
        min: 0,
        max: 24,
        unit: ' px',
        onChanged: (v) => set(() => s.innerRadius = v),
      ),
      SurfaceProp.width => NumberField(
        label: label,
        value: s.width,
        inherited: rs.width,
        inheritedFrom: src(rs.width, ps.width),
        defaultValue: 52,
        min: 24,
        max: 80,
        unit: ' px',
        onChanged: (v) => set(() => s.width = v),
      ),
      SurfaceProp.trackBorderWidth => NumberField(
        label: label,
        value: s.trackBorderWidth,
        inherited: rs.trackBorderWidth,
        inheritedFrom: src(rs.trackBorderWidth, ps.trackBorderWidth),
        defaultValue: rs.borderWidth ?? 0,
        min: 0,
        max: 4,
        step: 0.5,
        unit: ' px',
        onChanged: (v) => set(() => s.trackBorderWidth = v),
      ),
      SurfaceProp.thumbSize => NumberField(
        label: label,
        value: s.thumbSize,
        inherited: rs.thumbSize,
        inheritedFrom: src(rs.thumbSize, ps.thumbSize),
        defaultValue: 24,
        min: 8,
        max: 40,
        unit: ' px',
        onChanged: (v) => set(() => s.thumbSize = v),
      ),
      SurfaceProp.bodyStyle => ChoiceField<TextRole>(
        label: label,
        value: s.bodyStyle,
        inherited: rs.bodyStyle,
        inheritedFrom: src(rs.bodyStyle, ps.bodyStyle),
        options: roles,
        defaultLabel: 'default M3',
        onChanged: (v) => set(() => s.bodyStyle = v),
      ),
    };

    return ListView(
      children: [
        PanelHeader(
          title: kind.label,
          subtitle: kind.themeData,
          action: TextButton.icon(
            onPressed: s.isEmpty ? null : () => set(s.reset),
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text('Reset'),
          ),
        ),
        if (kind.props.containsKey(SurfaceProp.elevation))
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Elevation paints the Material shadow: the CSS shadows of a '
              'design system can only be approximated.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (kind == SurfaceKind.switchControl && rs.hasSwitchGeometry)
          UsageCallout(note: switchNote())
        else if (kind == SurfaceKind.switchControl)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'The "AppSwitch" entries do not exist in Material\'s Switch: if '
              'you set one, the theme exports the AppSwitch widget to use '
              'instead of Switch.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (kind == SurfaceKind.menu && rs.hasShapeShadow)
          UsageCallout(note: menuNote()),
        PropertySection(
          title: 'Properties',
          children: [for (final e in kind.props.entries) field(e.key, e.value)],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
