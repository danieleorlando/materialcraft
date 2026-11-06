import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../export/dart_exporter.dart';
import '../export/export_format.dart';
import '../export/usage_notes.dart';
import '../model/theme_config.dart';
import 'storage/storage.dart';
import 'widgets/usage_callout.dart';

Future<void> showExportDialog(BuildContext context, ThemeConfig config) async {
  // The formatter is a deferred library: download it on first use.
  await loadExportFormatter();
  if (!context.mounted) return;
  return showDialog<void>(
    context: context,
    builder: (_) => _ExportDialog(config: config),
  );
}

class _ExportDialog extends StatefulWidget {
  const _ExportDialog({required this.config});

  final ThemeConfig config;

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  /// Remembered for the session: whoever picks the package always wants it.
  static bool _usePackage = false;

  /// Material library of the export, remembered for the session too.
  static ExportTarget _target = ExportTarget.materialUi;

  @override
  Widget build(BuildContext context) {
    final code = exportDart(
      widget.config,
      usePackage: _usePackage,
      target: _target,
    );
    final notes = usageNotes(
      widget.config,
      usePackage: _usePackage,
      target: _target,
    );
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final required = notes.where((n) => n.required).length;
    final height = MediaQuery.sizeOf(context).height * 0.85;
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 860,
          maxHeight: height < 720 ? height : 720,
        ),
        child: DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'app_theme.dart',
                            style: theme.textTheme.titleLarge,
                          ),
                          Text(
                            _usePackage
                                ? 'Add the materialcraft package, put the '
                                      'file in your project and use '
                                      'AppTheme.light() / AppTheme.dark() in '
                                      'MaterialApp.'
                                : 'Put the file in your project and use '
                                      'AppTheme.light() / AppTheme.dark() in '
                                      'MaterialApp.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => downloadText(
                        'app_theme.dart',
                        code,
                        mimeType: 'text/plain',
                      ),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Download'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: code));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Code copied to clipboard'),
                              behavior: SnackBarBehavior.floating,
                              width: 320,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy'),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('Standalone'),
                          tooltip: 'A single file, no dependencies',
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('With package'),
                          tooltip:
                              'Shorter file: the support classes come from '
                              'the materialcraft package',
                        ),
                      ],
                      selected: {_usePackage},
                      onSelectionChanged: (v) =>
                          setState(() => _usePackage = v.first),
                    ),
                    SegmentedButton<ExportTarget>(
                      showSelectedIcon: false,
                      segments: [
                        for (final t in ExportTarget.values)
                          ButtonSegment(
                            value: t,
                            label: Text(t.label),
                            tooltip: t.description,
                          ),
                      ],
                      selected: {_target},
                      onSelectionChanged: (v) =>
                          setState(() => _target = v.first),
                    ),
                  ],
                ),
              ),
              TabBar(
                tabAlignment: TabAlignment.start,
                isScrollable: true,
                tabs: [
                  const Tab(text: 'Code'),
                  Tab(
                    text:
                        'How to use it · '
                        '${notes.length}${required > 1 ? ' ($required required)' : ''}',
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    Container(
                      color: cs.surfaceContainerHighest,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SelectableText(
                            code,
                            style: GoogleFonts.jetBrainsMono(
                              // No ligatures: '=>' must stay '=>' in the code.
                              fontFeatures: const [FontFeature.disable('calt')],
                              fontSize: 13,
                              height: 1.5,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            "The theme works on top of Material: almost "
                            "everything applies by itself. These are the only "
                            "changes to make in your app's code to get the "
                            "same look as the preview.",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                        for (final n in notes)
                          UsageCallout(note: n, dense: false),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
