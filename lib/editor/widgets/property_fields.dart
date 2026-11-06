import 'package:material_ui/material_ui.dart';

import '../../model/color_ref.dart';
import 'color_picker_dialog.dart';

/// Header of a property group.
class PropertySection extends StatelessWidget {
  const PropertySection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

/// Row with label, current value and reset button.
class _PropertyHeader extends StatelessWidget {
  const _PropertyHeader({
    required this.label,
    required this.valueText,
    required this.overridden,
    required this.onReset,
  });

  final String label;
  final String valueText;
  final bool overridden;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(
          valueText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: overridden
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: overridden ? FontWeight.w600 : FontWeight.normal,
            fontStyle: overridden ? FontStyle.normal : FontStyle.italic,
          ),
        ),
        SizedBox(
          width: 36,
          child: overridden
              ? IconButton(
                  tooltip: 'Reset to default',
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt),
                )
              : null,
        ),
      ],
    );
  }
}

/// Numeric property with a slider. `value == null` means "default".
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.label,
    required this.value,
    required this.defaultValue,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.unit = '',
    this.defaultLabel,
    this.decimals,
    this.inherited,
    this.inheritedFrom,
  });

  final String label;
  final double? value;

  /// Value inherited from the preset when [value] is null (null = M3 default).
  final double? inherited;
  final String? inheritedFrom;
  final int? decimals;
  final double defaultValue;
  final double min;
  final double max;
  final double step;
  final String unit;
  final String? defaultLabel;
  final ValueChanged<double?> onChanged;

  String _fmt(double v) {
    final d = decimals ?? (step < 1 ? 1 : 0);
    final s = d == 0 ? v.round().toString() : v.toStringAsFixed(d);
    return '$s$unit';
  }

  @override
  Widget build(BuildContext context) {
    final inh = inherited;
    final current = (value ?? inh ?? defaultValue).clamp(min, max);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PropertyHeader(
            label: label,
            valueText: value != null
                ? _fmt(value!)
                : inh != null
                ? '${inheritedFrom ?? 'preset'} · ${_fmt(inh)}'
                : (defaultLabel ?? 'default · ${_fmt(defaultValue)}'),
            overridden: value != null,
            onReset: () => onChanged(null),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: current,
              min: min,
              max: max,
              divisions: ((max - min) / step).round(),
              label: _fmt(current),
              onChanged: (v) {
                final rounded = (v / step).round() * step;
                onChanged(double.parse(rounded.toStringAsFixed(2)));
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Color property: shows the swatch and opens the picker.
class ColorField extends StatelessWidget {
  const ColorField({
    super.key,
    required this.label,
    required this.value,
    required this.scheme,
    required this.onChanged,
    this.defaultColor,
    this.defaultText = 'default',
    this.allowRoles = true,
    this.dense = false,
    this.inherited,
    this.inheritedFrom,
  });

  final String label;
  final ColorRef? value;

  /// Color inherited from the preset when [value] is null.
  final ColorRef? inherited;
  final String? inheritedFrom;
  final ColorScheme scheme;

  /// Color shown when [value] is null (null = no solid swatch).
  final Color? defaultColor;
  final String defaultText;
  final bool allowRoles;
  final bool dense;
  final ValueChanged<ColorRef?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = value;
    final inh = v == null ? inherited : null;
    final shownRef = v ?? inh;
    return InkWell(
      onTap: () async {
        final picked = await showColorPicker(
          context,
          initial: shownRef,
          scheme: scheme,
          allowRoles: allowRoles,
        );
        if (picked != null) onChanged(picked);
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, dense ? 3 : 6, 4, dense ? 3 : 6),
        child: Row(
          children: [
            if (shownRef is AdaptiveColor)
              SplitSwatch(light: shownRef.light, dark: shownRef.dark, size: 28)
            else if (shownRef is TokenColor)
              SplitSwatch(
                light: shownRef.token.light,
                dark: shownRef.token.dark,
                size: 28,
              )
            else if (shownRef is PaletteColor)
              SplitSwatch(
                light: shownRef.token.light,
                dark: shownRef.token.dark,
                size: 28,
              )
            else if (shownRef != null)
              ColorSwatchDot(color: shownRef.resolve(scheme), size: 28)
            else if (defaultColor != null)
              ColorSwatchDot(color: defaultColor!, size: 28)
            else
              const EmptySwatch(size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodyMedium),
                  Text(
                    v?.label ??
                        (inh != null
                            ? '${inheritedFrom ?? 'preset'} · ${inh.label}'
                            : defaultText),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: v == null
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 36,
              child: v != null
                  ? IconButton(
                      tooltip: 'Reset',
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      onPressed: () => onChanged(null),
                      icon: const Icon(Icons.restart_alt),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Switch with label and description.
class SwitchField extends StatelessWidget {
  const SwitchField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      dense: true,
      contentPadding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      subtitle: subtitle == null ? null : Text(subtitle!),
      value: value,
      onChanged: onChanged,
    );
  }
}

/// Multiple-choice property via a dropdown.
class ChoiceField<T> extends StatelessWidget {
  const ChoiceField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.defaultLabel = 'default',
    this.inherited,
    this.inheritedFrom,
  });

  final String label;
  final T? value;
  final Map<T, String> options;
  final String defaultLabel;

  /// Choice inherited from the preset when [value] is null.
  final T? inherited;
  final String? inheritedFrom;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: DropdownButtonFormField<T?>(
        // The key forces a rebuild when the value changes from outside (reset).
        key: ValueKey(value),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        items: [
          DropdownMenuItem<T?>(
            value: null,
            child: Text(
              inherited != null
                  ? '${inheritedFrom ?? 'preset'} · '
                        '${options[inherited] ?? inherited.toString()}'
                  : defaultLabel,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          for (final e in options.entries)
            DropdownMenuItem<T?>(value: e.key, child: Text(e.value)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class ColorSwatchDot extends StatelessWidget {
  const ColorSwatchDot({super.key, required this.color, this.size = 24});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    );
  }
}

/// Swatch split in half: light on the left, dark on the right.
class SplitSwatch extends StatelessWidget {
  const SplitSwatch({
    super.key,
    required this.light,
    required this.dark,
    this.size = 24,
  });

  final Color light;
  final Color dark;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        // Without stretch, ColoredBoxes without a child would have zero height.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: ColoredBox(color: light)),
          Expanded(child: ColoredBox(color: dark)),
        ],
      ),
    );
  }
}

/// Empty swatch (inherited value).
class EmptySwatch extends StatelessWidget {
  const EmptySwatch({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1.5,
        ),
      ),
      child: Icon(
        Icons.subdirectory_arrow_right,
        size: size * 0.55,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}
