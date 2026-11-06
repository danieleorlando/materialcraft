import 'package:material_ui/material_ui.dart';
import 'package:materialcraft/materialcraft.dart';

import '../model/surface_config.dart';
import '../model/theme_builder.dart';
import '../model/theme_config.dart';
import 'editor_controller.dart';
import 'preview_showcases.dart';

/// Cosa mostra l'anteprima.
enum PreviewMode {
  /// The components of the section selected in the editor.
  section,

  /// Dashboard only (wizard: style, colors, summary).
  dashboard,

  /// Dashboard + strip of details on shapes and motion (wizard:
  /// global properties).
  dashboardWithDetails,
}

/// Side-by-side light / dark preview with the theme being edited.
class PreviewPane extends StatelessWidget {
  const PreviewPane({
    super.key,
    required this.controller,
    this.mode = PreviewMode.section,
  });

  final EditorController controller;
  final PreviewMode mode;

  @override
  Widget build(BuildContext context) {
    final c = controller.resolved;
    final light = buildTheme(c, Brightness.light);
    final dark = buildTheme(c, Brightness.dark);
    final section = controller.selected;

    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 820;
          final panels = [
            _ThemedPreview(
              theme: light,
              title: 'Light',
              section: section,
              mode: mode,
            ),
            _ThemedPreview(
              theme: dark,
              title: 'Dark',
              section: section,
              mode: mode,
            ),
          ];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: panels[0]),
                      const SizedBox(width: 24),
                      Expanded(child: panels[1]),
                    ],
                  )
                : Column(
                    children: [
                      panels[0],
                      const SizedBox(height: 24),
                      panels[1],
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _ThemedPreview extends StatelessWidget {
  const _ThemedPreview({
    required this.theme,
    required this.title,
    required this.section,
    required this.mode,
  });

  final ThemeData theme;
  final String title;
  final EditorSection section;
  final PreviewMode mode;

  @override
  Widget build(BuildContext context) {
    // AnimatedTheme interpolates changes: the preview stays smooth while
    // dragging the sliders.
    return AnimatedTheme(
      data: theme,
      duration: const Duration(milliseconds: 150),
      child: Builder(
        builder: (context) {
          final t = Theme.of(context);
          final cs = t.colorScheme;
          final kinds = switch (section) {
            // Colors: the buttons that show primary, secondary, borders and
            // destructive (the others are in their own sections).
            GlobalSection() => const [
              ButtonKind.filled,
              ButtonKind.elevated,
              ButtonKind.outlined,
              ButtonKind.text,
              ButtonKind.danger,
            ],
            GeneralSection() || StyleSection() => const [
              ButtonKind.filled,
              ButtonKind.outlined,
              ButtonKind.elevated,
            ],
            ButtonSection(:final kind) => [kind],
            _ => const <ButtonKind>[],
          };
          final general = section is GeneralSection || section is StyleSection;
          final showField =
              section is GlobalSection ||
              section is TextFieldSection ||
              general;

          return Material(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        title == 'Dark'
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: t.textTheme.titleSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (mode != PreviewMode.section) ...[
                    const DashboardShowcase(),
                    if (mode == PreviewMode.dashboardWithDetails) ...[
                      Divider(color: cs.outlineVariant),
                      const SizedBox(height: 16),
                      Text(
                        'Details · shapes and motion',
                        style: t.textTheme.labelLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Button states (pill, height, press) and the
                      // controls the dashboard doesn't have.
                      for (final k in const [
                        ButtonKind.filled,
                        ButtonKind.outlined,
                      ])
                        _ButtonShowcase(kind: k),
                      for (final k in const [
                        SurfaceKind.chip,
                        SurfaceKind.checkbox,
                        SurfaceKind.menu,
                      ])
                        SurfaceShowcase(kind: k),
                    ],
                  ] else ...[
                    // Colors: a dashboard first, where the surfaces and
                    // grays of the base color show (as in the shadcn
                    // configurator).
                    if (section is GlobalSection) const DashboardShowcase(),
                    if (section is TypographySection)
                      const TypographyShowcase(),
                    if (section is ButtonSizesSection) const _SizesShowcase(),
                    if (section case SurfaceSection(:final kind))
                      SurfaceShowcase(kind: kind),
                    if (general)
                      for (final k in const [
                        SurfaceKind.card,
                        SurfaceKind.chip,
                        SurfaceKind.checkbox,
                        SurfaceKind.menu,
                      ])
                        SurfaceShowcase(kind: k),
                    // Colors: where backgrounds, borders, muted and secondary
                    // text show (the differences between base colors).
                    if (section is GlobalSection)
                      for (final k in const [
                        SurfaceKind.card,
                        SurfaceKind.listTile,
                        SurfaceKind.chip,
                        SurfaceKind.menu,
                        SurfaceKind.checkbox,
                      ])
                        SurfaceShowcase(kind: k),
                    if (showField) const _FieldShowcase(),
                    for (final k in kinds) _ButtonShowcase(kind: k),
                    const SizedBox(height: 8),
                    Divider(color: cs.outlineVariant),
                    const SizedBox(height: 16),
                    Text(
                      'In context',
                      style: t.textTheme.labelLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _SampleScene(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// All labelled buttons in the three sizes.
class _SizesShowcase extends StatelessWidget {
  const _SizesShowcase();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final caption = t.textTheme.labelSmall?.copyWith(
      color: t.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final size in AppButtonSize.values) ...[
            Text(size.name, style: caption),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final k in ButtonKind.values)
                  if (!k.isIconOnly)
                    PreviewButton(kind: k, label: k.label, size: size),
                PreviewButton(
                  kind: ButtonKind.filled,
                  label: 'Icon',
                  icon: Icons.add,
                  size: size,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

/// One button type: interactive row + row of "frozen" states.
class _ButtonShowcase extends StatelessWidget {
  const _ButtonShowcase({required this.kind});

  final ButtonKind kind;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final caption = t.textTheme.labelSmall?.copyWith(
      color: t.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kind.widget,
            style: t.textTheme.labelMedium?.copyWith(
              color: t.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              buildPreviewButton(kind, label: 'Label'),
              buildPreviewButton(kind, label: 'With icon', icon: Icons.add),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 12,
            children: [
              for (final (label, states) in const [
                ('Normal', <WidgetState>{}),
                ('Hover', {WidgetState.hovered}),
                ('Pressed', {WidgetState.hovered, WidgetState.pressed}),
                ('Focus', {WidgetState.focused}),
                ('Disabled', {WidgetState.disabled}),
              ])
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FrozenButton(kind: kind, states: states),
                    const SizedBox(height: 6),
                    Text(label, style: caption),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Button locked in a set of states, to compare them side by side.
class _FrozenButton extends StatefulWidget {
  const _FrozenButton({required this.kind, required this.states});

  final ButtonKind kind;
  final Set<WidgetState> states;

  @override
  State<_FrozenButton> createState() => _FrozenButtonState();
}

class _FrozenButtonState extends State<_FrozenButton> {
  late final _controller = WidgetStatesController({...widget.states});

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeFocus(
        child: buildPreviewButton(
          widget.kind,
          label: 'Button',
          enabled: !widget.states.contains(WidgetState.disabled),
          statesController: _controller,
        ),
      ),
    );
  }
}

/// Text fields: interactive examples + "frozen" states.
class _FieldShowcase extends StatelessWidget {
  const _FieldShowcase();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final caption = t.textTheme.labelSmall?.copyWith(
      color: t.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TextField',
            style: t.textTheme.labelMedium?.copyWith(
              color: t.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  decoration: InputDecoration(hintText: 'name@example.com'),
                ),
              ),
              SizedBox(
                width: 220,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Password',
                    helperText: 'At least 8 characters',
                    suffixIcon: Icon(Icons.visibility_outlined),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              for (final (label, state) in const [
                ('Normal', _Frozen.normal),
                ('Hover', _Frozen.hovered),
                ('Focus', _Frozen.focused),
                ('Disabled', _Frozen.disabled),
                ('Error', _Frozen.error),
              ])
                SizedBox(
                  width: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FrozenField(state: state),
                      const SizedBox(height: 6),
                      Text(label, style: caption),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _Frozen { normal, hovered, focused, disabled, error }

/// InputDecorator locked in a state (TextField doesn't allow forcing it).
class _FrozenField extends StatelessWidget {
  const _FrozenField({required this.state});

  final _Frozen state;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;
    return IgnorePointer(
      child: InputDecorator(
        isEmpty: true,
        isFocused: state == _Frozen.focused,
        isHovering: state == _Frozen.hovered,
        decoration: InputDecoration(
          hintText: 'Placeholder',
          prefixIcon: const Icon(Icons.mail_outline),
          enabled: state != _Frozen.disabled,
          errorText: state == _Frozen.error ? 'Required field' : null,
        ),
        child: Text('', style: style),
      ),
    );
  }
}

/// A small sample screen that uses every button type.
class _SampleScene extends StatelessWidget {
  const _SampleScene();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirm order', style: t.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '3 items · expected delivery Thursday. You can change the '
              'address before confirming.',
              style: t.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Notes for the courier',
                helperText: 'Optional',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_location_alt_outlined),
                  label: const Text('Address'),
                ),
                ElevatedButton(onPressed: () {}, child: const Text('Save')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () {}, child: const Text('Cancel')),
                const SizedBox(width: 8),
                FilledButton(onPressed: () {}, child: const Text('Confirm')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildPreviewButton(
  ButtonKind kind, {
  required String label,
  IconData? icon,
  bool enabled = true,
  WidgetStatesController? statesController,
  AppButtonSize size = AppButtonSize.medium,
}) => PreviewButton(
  kind: kind,
  label: label,
  icon: icon,
  enabled: enabled,
  statesController: statesController,
  size: size,
);

/// Preview button: uses the theme and, for danger / icon secondary / sizes,
/// the AppButtonStyles extra styles, as the app would.
class PreviewButton extends StatelessWidget {
  const PreviewButton({
    super.key,
    required this.kind,
    required this.label,
    this.icon,
    this.enabled = true,
    this.statesController,
    this.size = AppButtonSize.medium,
  });

  final ButtonKind kind;
  final String label;
  final IconData? icon;
  final bool enabled;
  final WidgetStatesController? statesController;
  final AppButtonSize size;

  @override
  Widget build(BuildContext context) {
    final onPressed = enabled ? () {} : null;
    final sc = statesController;
    final extra = context.buttonStyle(
      AppButtonKind.values.byName(kind.name),
      size: size,
    );
    final text = Text(label);

    if (kind.isIconOnly) {
      final glyph = Icon(icon ?? Icons.notifications_outlined);
      final themed = kind == ButtonKind.iconSecondary
          ? extra
          : Theme.of(context).iconButtonTheme.style;
      if (sc == null) {
        return IconButton(
          onPressed: onPressed,
          style: themed,
          tooltip: label,
          icon: glyph,
        );
      }
      // IconButton doesn't accept a statesController: for locked states
      // a TextButton with the same style and IconButton's measurements is used.
      final base = IconButton.styleFrom(
        minimumSize: const Size(40, 40),
        padding: const EdgeInsets.all(8),
        iconSize: 24,
        shape: const CircleBorder(),
      );
      return TextButton(
        onPressed: onPressed,
        statesController: sc,
        style: themed?.merge(base) ?? base,
        child: glyph,
      );
    }

    final style = extra;
    if (icon != null) {
      final i = Icon(icon);
      return switch (kind) {
        ButtonKind.elevated => ElevatedButton.icon(
          onPressed: onPressed,
          statesController: sc,
          style: style,
          icon: i,
          label: text,
        ),
        ButtonKind.outlined => OutlinedButton.icon(
          onPressed: onPressed,
          statesController: sc,
          style: style,
          icon: i,
          label: text,
        ),
        ButtonKind.text => TextButton.icon(
          onPressed: onPressed,
          statesController: sc,
          style: style,
          icon: i,
          label: text,
        ),
        _ => FilledButton.icon(
          onPressed: onPressed,
          statesController: sc,
          style: style,
          icon: i,
          label: text,
        ),
      };
    }
    return switch (kind) {
      ButtonKind.elevated => ElevatedButton(
        onPressed: onPressed,
        statesController: sc,
        style: style,
        child: text,
      ),
      ButtonKind.outlined => OutlinedButton(
        onPressed: onPressed,
        statesController: sc,
        style: style,
        child: text,
      ),
      ButtonKind.text => TextButton(
        onPressed: onPressed,
        statesController: sc,
        style: style,
        child: text,
      ),
      _ => FilledButton(
        onPressed: onPressed,
        statesController: sc,
        style: style,
        child: text,
      ),
    };
  }
}
