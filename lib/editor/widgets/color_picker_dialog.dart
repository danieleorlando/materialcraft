import 'package:material_ui/material_ui.dart';

import '../../model/boardui_tokens.dart';
import '../../model/color_ref.dart';
import 'property_fields.dart';

enum _Mode { role, token, single, adaptive }

/// Opens the picker. With [allowRoles] false, scheme roles can't be chosen
/// (e.g. for the seed or for the scheme's own overrides).
Future<ColorRef?> showColorPicker(
  BuildContext context, {
  ColorRef? initial,
  ColorScheme? scheme,
  bool allowRoles = true,
  bool allowAdaptive = true,
}) {
  return showDialog<ColorRef>(
    context: context,
    builder: (_) => _ColorPickerDialog(
      initial: initial,
      scheme: scheme,
      allowRoles: allowRoles && scheme != null,
      allowAdaptive: allowAdaptive,
    ),
  );
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({
    this.initial,
    this.scheme,
    required this.allowRoles,
    required this.allowAdaptive,
  });

  final ColorRef? initial;
  final ColorScheme? scheme;
  final bool allowRoles;
  final bool allowAdaptive;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late _Mode _mode;
  SchemeRole _role = SchemeRole.primary;
  double _roleAlpha = 1;
  Color _single = const Color(0xFF6750A4);
  Color _light = const Color(0xFFFFFFFF);
  Color _dark = const Color(0xFF171717);
  bool _editingDark = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    switch (init) {
      case RoleColor(:final role, :final alpha) when widget.allowRoles:
        _mode = _Mode.role;
        _role = role;
        _roleAlpha = alpha;
      case CustomColor(:final color):
        _mode = _Mode.single;
        _single = _light = color;
      case TokenColor(:final name) when widget.allowAdaptive:
        _mode = _Mode.token;
        _token = name;
      case AdaptiveColor(:final light, :final dark) when widget.allowAdaptive:
        _mode = _Mode.adaptive;
        _light = light;
        _dark = dark;
        _single = light;
      default:
        _mode = widget.allowRoles ? _Mode.role : _Mode.single;
    }
  }

  ColorRef get _result => switch (_mode) {
    _Mode.role => RoleColor(_role, alpha: _roleAlpha),
    _Mode.token => TokenColor(_token ?? boardTokens.keys.first),
    _Mode.single => CustomColor(_single),
    _Mode.adaptive => AdaptiveColor(_light, _dark),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = widget.scheme;

    final segments = [
      if (widget.allowRoles)
        const ButtonSegment(value: _Mode.role, label: Text('Scheme role')),
      if (widget.allowAdaptive)
        const ButtonSegment(value: _Mode.token, label: Text('Token BoardUI')),
      const ButtonSegment(value: _Mode.single, label: Text('Color')),
      if (widget.allowAdaptive)
        const ButtonSegment(value: _Mode.adaptive, label: Text('Light / Dark')),
    ];

    return AlertDialog(
      title: const Text('Choose color'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (segments.length > 1) ...[
                SegmentedButton<_Mode>(
                  segments: segments,
                  selected: {_mode},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _mode = s.first),
                ),
                const SizedBox(height: 16),
              ],
              switch (_mode) {
                _Mode.role => _RoleEditor(
                  scheme: scheme!,
                  role: _role,
                  alpha: _roleAlpha,
                  onRole: (r) => setState(() => _role = r),
                  onAlpha: (a) => setState(() => _roleAlpha = a),
                ),
                _Mode.token => _TokenPicker(
                  selected: _token,
                  onSelected: (t) => setState(() => _token = t),
                ),
                _Mode.single => _ColorEditor(
                  key: const ValueKey('single'),
                  color: _single,
                  onChanged: (c) => setState(() => _single = c),
                ),
                _Mode.adaptive => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Different values for light and dark mode.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final dark in [false, true])
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: dark ? 0 : 8),
                              child: _SlotTile(
                                label: dark ? 'Dark' : 'Light',
                                color: dark ? _dark : _light,
                                selected: _editingDark == dark,
                                onTap: () =>
                                    setState(() => _editingDark = dark),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ColorEditor(
                      key: ValueKey('slot-$_editingDark'),
                      color: _editingDark ? _dark : _light,
                      onChanged: (c) => setState(() {
                        if (_editingDark) {
                          _dark = c;
                        } else {
                          _light = c;
                        }
                      }),
                    ),
                  ],
                ),
              },
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _result),
          child: const Text('Use'),
        ),
      ],
    );
  }
}

class _RoleEditor extends StatelessWidget {
  const _RoleEditor({
    required this.scheme,
    required this.role,
    required this.alpha,
    required this.onRole,
    required this.onAlpha,
  });

  final ColorScheme scheme;
  final SchemeRole role;
  final double alpha;
  final ValueChanged<SchemeRole> onRole;
  final ValueChanged<double> onAlpha;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'They adapt to light and dark automatically.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final r in SchemeRole.values)
              ChoiceChip(
                selected: r == role,
                avatar: ColorSwatchDot(color: r.resolve(scheme), size: 18),
                label: Text(r.label),
                visualDensity: VisualDensity.compact,
                onSelected: (_) => onRole(r),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _AlphaSlider(alpha: alpha, onChanged: onAlpha),
      ],
    );
  }
}

/// Tailwind palette + hex field + opacity for a single color.
class _ColorEditor extends StatefulWidget {
  const _ColorEditor({super.key, required this.color, required this.onChanged});

  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  State<_ColorEditor> createState() => _ColorEditorState();
}

class _ColorEditorState extends State<_ColorEditor> {
  late final TextEditingController _hex = TextEditingController(
    text: _hexOf(widget.color),
  );
  String? _error;

  static String _hexOf(Color c) => '#${hexArgb(c).substring(2)}';

  @override
  void didUpdateWidget(_ColorEditor old) {
    super.didUpdateWidget(old);
    final rgb = _hexOf(widget.color);
    if (parseHex(_hex.text)?.toARGB32() !=
        (widget.color.toARGB32() | 0xFF000000)) {
      _hex.text = rgb;
    }
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _setRgb(Color rgb) =>
      widget.onChanged(rgb.withValues(alpha: widget.color.a));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedRgb = widget.color.toARGB32() & 0xFFFFFF;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tailwind', style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        for (final fam in tailwindPalette.entries)
          if (fam.key != 'accent') // alias of blue
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(fam.key, style: theme.textTheme.bodySmall),
                  ),
                  for (final shade in fam.value.entries)
                    Expanded(
                      child: Tooltip(
                        message: '${fam.key}-${shade.key}',
                        child: InkWell(
                          onTap: () => _setRgb(shade.value),
                          child: Container(
                            height: 26,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: shade.value,
                              borderRadius: BorderRadius.circular(4),
                              border:
                                  shade.value.toARGB32() & 0xFFFFFF ==
                                      selectedRgb
                                  ? Border.all(
                                      color: theme.colorScheme.onSurface,
                                      width: 2,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        Row(
          children: [
            const SizedBox(width: 56),
            for (final c in const [Color(0xFFFFFFFF), Color(0xFF000000)])
              Padding(
                padding: const EdgeInsets.only(right: 4, top: 2),
                child: InkWell(
                  onTap: () => _setRgb(c),
                  child: ColorSwatchDot(color: c, size: 24),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColorSwatchDot(color: widget.color, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _hex,
                decoration: InputDecoration(
                  labelText: 'Hex',
                  hintText: '#155DFC',
                  helperText: tailwindName(widget.color),
                  errorText: _error,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) {
                  final c = parseHex(v);
                  setState(() => _error = c == null ? 'Format: #RRGGBB' : null);
                  if (c != null) {
                    // An 8-digit hex includes the alpha; a 6-digit one keeps the current one.
                    final s = v.trim().replaceFirst('#', '');
                    widget.onChanged(
                      s.length == 8 ? c : c.withValues(alpha: widget.color.a),
                    );
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _AlphaSlider(
          alpha: widget.color.a,
          onChanged: (a) => widget.onChanged(widget.color.withValues(alpha: a)),
        ),
      ],
    );
  }
}

class _AlphaSlider extends StatelessWidget {
  const _AlphaSlider({required this.alpha, required this.onChanged});

  final double alpha;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Opacity'),
        Expanded(
          child: Slider(
            value: alpha,
            divisions: 20,
            label: '${(alpha * 100).round()}%',
            onChanged: (v) => onChanged(double.parse(v.toStringAsFixed(2))),
          ),
        ),
        SizedBox(width: 44, child: Text('${(alpha * 100).round()}%')),
      ],
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            ColorSwatchDot(color: color, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  Text(
                    colorLabel(color),
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Searchable list of BoardUI's semantic color tokens.
class _TokenPicker extends StatefulWidget {
  const _TokenPicker({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  State<_TokenPicker> createState() => _TokenPickerState();
}

class _TokenPickerState extends State<_TokenPicker> {
  String _query = '';
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final words = _query.toLowerCase().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    final names = boardTokens.keys
        .where((n) => words.every(n.contains))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'BoardUI semantic tokens: each one already has a light and dark '
          'value.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          autofocus: true,
          decoration: const InputDecoration(
            isDense: true,
            prefixIcon: Icon(Icons.search, size: 20),
            hintText: 'Search (e.g. text primary, border, error)',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 8),
        Text('${names.length} token', style: theme.textTheme.labelSmall),
        const SizedBox(height: 4),
        SizedBox(
          height: 320,
          child: Scrollbar(
            controller: _scroll,
            child: ListView.builder(
              controller: _scroll,
              itemCount: names.length,
              itemExtent: 40,
              itemBuilder: (context, i) {
                final name = names[i];
                final t = boardTokens[name]!;
                final selected = name == widget.selected;
                return ListTile(
                  dense: true,
                  selected: selected,
                  selectedTileColor: theme.colorScheme.secondaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  leading: SplitSwatch(light: t.light, dark: t.dark, size: 22),
                  title: Text(name),
                  trailing: Text(
                    '${colorLabel(t.light)} / ${colorLabel(t.dark)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () => widget.onSelected(name),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
