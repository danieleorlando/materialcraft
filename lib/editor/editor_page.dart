import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/share_link.dart';
import '../model/surface_config.dart';
import '../model/theme_config.dart';
import '../model/theme_layers.dart';
import 'about_dialog.dart';
import 'editor_controller.dart';
import 'export_dialog.dart';
import 'new_theme_wizard.dart';
import 'storage/storage.dart';
import 'preview_pane.dart';
import 'properties_panel.dart';
import 'style_properties.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => EditorPageState();
}

class EditorPageState extends State<EditorPage> {
  final _controller = EditorController();

  @visibleForTesting
  EditorController get controller => _controller;

  @override
  void initState() {
    super.initState();
    _start();
  }

  /// Opens a shared link if the page has one; otherwise restores the last
  /// theme, and on first launch in the browser opens the wizard.
  Future<void> _start() async {
    final shared = readShareParam();
    if (shared != null) {
      clearShareParam();
      if (await openSharedTheme(shared)) return;
    }
    final restored = await _controller.restoreAutosave();
    if (!restored && kIsWeb && mounted) {
      await showNewThemeWizard(context, _controller);
    }
  }

  /// Opens the theme of a shared link (`?t=` value). Asks first if it would
  /// replace a different theme the user was working on. True if the editor
  /// now shows a theme (the shared one or the user's own).
  @visibleForTesting
  Future<bool> openSharedTheme(String payload) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return false;
    final ({LayeredTheme theme, String? name}) shared;
    try {
      shared = decodeSharePayload(payload);
    } on FormatException catch (e) {
      _toast(e.message);
      return false;
    }
    final sharedName = shared.name ?? 'Shared theme';

    final mine = _controller.readAutosavedTheme();
    if (mine != null &&
        mine.theme.hasUserChoices &&
        !sameTheme(mine.theme, shared.theme)) {
      final choice = await _askReplace(sharedName, mine.name ?? 'My theme');
      if (!mounted) return false;
      switch (choice) {
        case _ReplaceChoice.keep:
          await _controller.adopt(mine.theme, name: mine.name);
          return true;
        case _ReplaceChoice.saveFirst:
          downloadText(fileNameFor(mine.name ?? 'My theme'), mine.json);
        case _ReplaceChoice.open:
          break;
      }
    }
    await _controller.adopt(shared.theme, name: sharedName);
    if (mounted) _toast('Opened the shared theme "$sharedName"');
    return true;
  }

  Future<_ReplaceChoice> _askReplace(String shared, String mine) async {
    final choice = await showDialog<_ReplaceChoice>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Open the shared theme?'),
        content: Text(
          'The link opens "$shared". It replaces the theme you were working '
          'on, "$mine".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _ReplaceChoice.keep),
            child: const Text('Keep mine'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _ReplaceChoice.saveFirst),
            child: const Text('Save mine, then open'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _ReplaceChoice.open),
            child: const Text('Open shared theme'),
          ),
        ],
      ),
    );
    return choice ?? _ReplaceChoice.keep;
  }

  Future<void> _share() async {
    await Clipboard.setData(ClipboardData(text: _controller.shareLink()));
    if (!mounted) return;
    _toast(
      'Link copied. Anyone who opens it gets "${_controller.themeName}" in '
      'the editor.',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      width: 360,
    ),
  );

  Future<void> _newTheme() async {
    if (_controller.hasEdits) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Create a new theme?'),
          content: Text(
            'The theme "${_controller.themeName}" will be replaced. To keep '
            'it, save it first with "Save".',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('New theme'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    await showNewThemeWizard(context, _controller);
  }

  Future<void> _open() async {
    final text = await pickTextFile();
    if (text == null || !mounted) return;
    try {
      await _controller.openJson(text);
      _toast('Opened "${_controller.themeName}"');
    } on FormatException catch (e) {
      _toast(e.message);
    }
  }

  void _save() {
    downloadText(_controller.fileName, _controller.toJsonString());
    _toast('Saved ${_controller.fileName}');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => Text.rich(
            TextSpan(
              text: 'MaterialCraft',
              children: [
                TextSpan(
                  text: '  ·  ${_controller.themeName}',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: cs.outlineVariant)),
        actions: [
          TextButton(
            onPressed: () => showAboutMaterialCraft(context),
            child: const Text('by Daniele Orlando'),
          ),
          IconButton(
            tooltip: 'MaterialCraft on GitHub',
            onPressed: () => openUrl(repoUrl),
            icon: const Icon(Icons.star_outline, size: 20),
          ),
          SizedBox(
            height: 24,
            child: VerticalDivider(width: 24, color: cs.outlineVariant),
          ),
          TextButton.icon(
            onPressed: _newTheme,
            icon: const Icon(Icons.auto_awesome_outlined, size: 18),
            label: const Text('New theme'),
          ),
          TextButton.icon(
            onPressed: _open,
            icon: const Icon(Icons.folder_open_outlined, size: 18),
            label: const Text('Open'),
          ),
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save'),
          ),
          TextButton.icon(
            onPressed: _share,
            icon: const Icon(Icons.link, size: 18),
            label: const Text('Share'),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: () => showExportDialog(context, _controller.resolved),
              icon: const Icon(Icons.code, size: 18),
              label: const Text('Export code'),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 220, child: _Sidebar(controller: _controller)),
            VerticalDivider(width: 1, color: cs.outlineVariant),
            Expanded(child: PreviewPane(controller: _controller)),
            VerticalDivider(width: 1, color: cs.outlineVariant),
            SizedBox(
              width: 360,
              child: PropertiesPanel(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        text.toUpperCase(),
        style: t.textTheme.labelSmall?.copyWith(
          color: t.colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );

    Widget item({
      required String label,
      required IconData icon,
      required EditorSection section,
      bool modified = false,
    }) {
      final selected = controller.selected == section;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        child: ListTile(
          dense: true,
          selected: selected,
          selectedTileColor: t.colorScheme.secondaryContainer,
          selectedColor: t.colorScheme.onSecondaryContainer,
          shape: const StadiumBorder(),
          leading: Icon(icon, size: 20),
          title: Text(label),
          trailing: modified
              ? Tooltip(
                  message: 'Edited by you',
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: t.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : null,
          onTap: () => controller.select(section),
        ),
      );
    }

    // The dot marks hand-made edits, not preset values.
    final c = controller.edits;
    final buttons = c.buttons;
    return ListView(
      children: [
        header('Theme'),
        item(
          label: 'Style · ${styleInfo[controller.preset.style]!.$1}',
          icon: Icons.style_outlined,
          section: const StyleSection(),
        ),
        item(
          label: 'Colors',
          icon: Icons.palette_outlined,
          section: const GlobalSection(),
          modified:
              !controller.colors.isEmpty ||
              c.seed != null ||
              c.schemeVariant != null ||
              c.schemeOverrides.isNotEmpty,
        ),
        item(
          label: 'Global properties',
          icon: Icons.tune,
          section: const GeneralSection(),
          modified:
              !controller.globals.isEmpty ||
              c.fontFamily != null ||
              c.headFontFamily != null ||
              c.density != null ||
              c.shrinkWrap != null,
        ),
        item(
          label: 'Typography',
          icon: Icons.text_fields_outlined,
          section: const TypographySection(),
          modified: !c.typography.isEmpty,
        ),
        header('Buttons'),
        for (final k in ButtonKind.values)
          item(
            label: k.label,
            icon: switch (k) {
              ButtonKind.elevated => Icons.layers_outlined,
              ButtonKind.filled => Icons.smart_button,
              ButtonKind.outlined => Icons.crop_square,
              ButtonKind.text => Icons.text_fields,
              ButtonKind.icon => Icons.touch_app_outlined,
              ButtonKind.danger => Icons.warning_amber_rounded,
              ButtonKind.ghost => Icons.blur_on,
              ButtonKind.iconSecondary => Icons.check_box_outline_blank,
            },
            section: ButtonSection(k),
            modified: !buttons[k]!.isEmpty,
          ),
        item(
          label: 'Sizes (lg, sm, xs)',
          icon: Icons.format_size,
          section: const ButtonSizesSection(),
          modified: c.buttonSizes.values.any((s) => !s.isEmpty),
        ),
        header('Fields'),
        item(
          label: 'Text field',
          icon: Icons.edit_note,
          section: const TextFieldSection(),
          modified: !c.textField.isEmpty,
        ),
        header('Containers'),
        for (final k in SurfaceKind.values)
          item(
            label: k.label,
            icon: switch (k) {
              SurfaceKind.card => Icons.crop_portrait,
              SurfaceKind.dialog => Icons.web_asset,
              SurfaceKind.bottomSheet => Icons.vertical_align_bottom,
              SurfaceKind.appBar => Icons.web,
              SurfaceKind.navigationBar => Icons.call_to_action_outlined,
              SurfaceKind.navigationRail => Icons.view_sidebar_outlined,
              SurfaceKind.listTile => Icons.list,
              SurfaceKind.divider => Icons.horizontal_rule,
              SurfaceKind.fab => Icons.add_circle_outline,
              SurfaceKind.tooltip => Icons.chat_bubble_outline,
              SurfaceKind.tabBar => Icons.tab_outlined,
              SurfaceKind.chip => Icons.label_outline,
              SurfaceKind.badge => Icons.circle_notifications_outlined,
              SurfaceKind.menu => Icons.menu_open,
              SurfaceKind.checkbox => Icons.check_box_outlined,
              SurfaceKind.radio => Icons.radio_button_checked,
              SurfaceKind.switchControl => Icons.toggle_on_outlined,
              SurfaceKind.slider => Icons.linear_scale,
              SurfaceKind.snackBar => Icons.announcement_outlined,
            },
            section: SurfaceSection(k),
            modified: !c.surfaces[k]!.isEmpty,
          ),
      ],
    );
  }
}

enum _ReplaceChoice { keep, saveFirst, open }
