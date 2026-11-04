import 'package:flutter/material.dart';

import 'color_choice_section.dart';
import 'editor_controller.dart';
import 'general_properties.dart';
import 'preview_pane.dart';
import '../model/presets.dart';
import 'style_properties.dart';

/// "New theme" wizard: style → colors → global properties → name.
///
/// Works on a draft: the theme being edited only changes with "Create theme".
Future<void> showNewThemeWizard(
  BuildContext context,
  EditorController controller,
) async {
  final draft = EditorController()..autosave = false;
  final created = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog.fullscreen(child: _Wizard(draft: draft)),
  );
  if (created == true) {
    await controller.adopt(draft.theme, name: draft.themeName);
    // Global properties show the result on every component right away.
    controller.select(const GeneralSection());
  }
  draft.dispose();
}

class _Wizard extends StatefulWidget {
  const _Wizard({required this.draft});

  final EditorController draft;

  @override
  State<_Wizard> createState() => _WizardState();
}

class _WizardState extends State<_Wizard> {
  static const _steps = ['Style', 'Colors', 'Global properties', 'Name'];
  int _step = 0;
  late final _name = TextEditingController(text: widget.draft.themeName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _goTo(int i) => setState(() => _step = i);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final draft = widget.draft;
    final last = _step == _steps.length - 1;

    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('New theme'),
          leading: IconButton(
            tooltip: 'Cancel',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context, false),
          ),
          shape: Border(bottom: BorderSide(color: cs.outlineVariant)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  for (var i = 0; i < _steps.length; i++) ...[
                    if (i > 0)
                      Expanded(
                        child: Divider(
                          color: i <= _step ? cs.primary : cs.outlineVariant,
                        ),
                      ),
                    _StepDot(
                      index: i,
                      label: _steps[i],
                      state: i < _step
                          ? _StepState.done
                          : i == _step
                          ? _StepState.current
                          : _StepState.todo,
                      onTap: i < _step ? () => _goTo(i) : null,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 400,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: cs.outlineVariant)),
                ),
                child: switch (_step) {
                  0 => ListView(
                    padding: const EdgeInsets.only(top: 16),
                    children: [
                      _intro(
                        context,
                        'Pick the starting design system. You can change it '
                        'later from the Style section.',
                      ),
                      StyleCards(
                        selected: draft.preset.style,
                        onSelect: (s) => draft.applyPreset(
                          presetForStyle(s, current: draft.preset),
                          keepEdits: true,
                        ),
                      ),
                      if (draft.preset.style == PresetStyle.shadcn)
                        ShadcnVariantPicker(
                          selected: draft.preset.shadcnStyle,
                          onSelect: (v) => draft.applyPreset(
                            ThemePreset.shadcnVariant(v),
                            keepEdits: true,
                          ),
                        ),
                    ],
                  ),
                  1 => ListView(
                    padding: const EdgeInsets.only(top: 16),
                    children: [
                      _intro(
                        context,
                        "The style's official colors, or your own color: the "
                        "rest of the palette is generated from it.",
                      ),
                      ColorChoiceSection(controller: draft),
                    ],
                  ),
                  2 => GeneralProperties(controller: draft),
                  _ => ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        "What's the theme called?",
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _name,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => draft.themeName = v,
                        onSubmitted: (_) => Navigator.pop(context, true),
                      ),
                      const SizedBox(height: 16),
                      _Summary(draft: draft),
                    ],
                  ),
                },
              ),
            ),
            Expanded(
              child: PreviewPane(
                controller: draft,
                // Always the same dashboard, changing step by step;
                // at the global properties step also the details on shapes and
                // motion, which the dashboard alone doesn't show.
                mode: _step == 2
                    ? PreviewMode.dashboardWithDetails
                    : PreviewMode.dashboard,
              ),
            ),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: cs.outlineVariant)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Text(
                  'Step ${_step + 1} of ${_steps.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (_step > 0)
                  TextButton(
                    onPressed: () => _goTo(_step - 1),
                    child: const Text('Back'),
                  ),
                const SizedBox(width: 8),
                if (!last)
                  FilledButton(
                    onPressed: () => _goTo(_step + 1),
                    child: const Text('Next'),
                  )
                else
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Create theme'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _intro(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.draft});

  final EditorController draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ch = draft.colors;
    final g = draft.globals;
    final colors = ch.primary == null
        ? 'official${draft.preset.neoPalette != null ? ' (${draft.preset.name.split('· ').last})' : ''}'
        : (ch.primaryName ?? 'custom');
    final general = [
      if (g.radius != null) 'radius ${g.radius!.round()} px',
      if (g.pillButtons == true) 'pill-shaped buttons',
      if (g.borderWidth != null) 'borders ${g.borderWidth} px',
      if (g.shadowStyle != null)
        '${g.shadowStyle!.label.toLowerCase()} '
            'shadows',
      if (g.controlHeight != null) 'height ${g.controlHeight!.round()} px',
      if (g.press != null) 'press: ${g.press!.label.toLowerCase()}',
    ];
    Widget row(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(k, style: theme.textTheme.labelLarge),
          ),
          Expanded(child: Text(v, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row('Style', styleInfo[draft.preset.style]!.$1),
        row('Colors', colors),
        row(
          'Global properties',
          general.isEmpty ? 'style default' : general.join(', '),
        ),
        const SizedBox(height: 12),
        Text(
          'After creating it you can fine-tune every component; style, colors '
          'and global properties stay editable from the sidebar.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

enum _StepState { done, current, todo }

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.label,
    required this.state,
    this.onTap,
  });

  final int index;
  final String label;
  final _StepState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final active = state != _StepState.todo;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: active ? cs.primary : cs.surfaceContainerHighest,
              foregroundColor: active ? cs.onPrimary : cs.onSurfaceVariant,
              child: state == _StepState.done
                  ? const Icon(Icons.check, size: 14)
                  : Text('${index + 1}', style: theme.textTheme.labelSmall),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: active ? cs.onSurface : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
