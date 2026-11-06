import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../export/usage_notes.dart';

/// "How to use it" box: explanation and before / after code to copy.
class UsageCallout extends StatelessWidget {
  const UsageCallout({super.key, required this.note, this.dense = true});

  final UsageNote note;

  /// In the properties panel (narrow) or in the export dialog.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = note.required ? cs.tertiary : cs.primary;
    return Container(
      margin: dense
          ? const EdgeInsets.fromLTRB(12, 4, 12, 12)
          : const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                note.required ? Icons.priority_high : Icons.lightbulb_outline,
                size: 18,
                color: accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(note.title, style: theme.textTheme.titleSmall),
              ),
              if (note.required)
                Text(
                  'Required',
                  style: theme.textTheme.labelSmall?.copyWith(color: accent),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            note.body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          if (note.before != null) ...[
            const SizedBox(height: 10),
            _CodeBlock(label: 'Material', code: note.before!, muted: true),
          ],
          const SizedBox(height: 10),
          _CodeBlock(
            label: note.before == null
                ? (note.language == 'yaml' ? 'pubspec.yaml' : 'Code')
                : 'With this theme',
            code: note.after,
          ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({
    required this.label,
    required this.code,
    this.muted = false,
  });

  final String label;
  final String code;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            if (!muted)
              IconButton(
                tooltip: 'Copy',
                visualDensity: VisualDensity.compact,
                iconSize: 16,
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
                icon: const Icon(Icons.copy),
              ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: muted ? cs.surfaceContainer : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(
              code,
              style: GoogleFonts.jetBrainsMono(
                // No ligatures: '=>' must stay '=>' in the code.
                fontFeatures: const [FontFeature.disable('calt')],
                fontSize: 12,
                height: 1.5,
                color: muted ? cs.onSurfaceVariant : cs.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
