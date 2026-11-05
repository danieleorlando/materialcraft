import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/gallery.dart';
import '../model/share_link.dart';
import '../model/theme_builder.dart';
import '../model/theme_config.dart';
import '../model/theme_json.dart';
import '../model/theme_layers.dart';
import 'preview_pane.dart';
import 'storage/storage.dart';

Future<List<GalleryEntry>>? _gallery;

/// The gallery themes bundled with the app (loaded once). Files that don't
/// pass the check are skipped; `test/gallery_test.dart` keeps them valid.
Future<List<GalleryEntry>> loadGallery() => _gallery ??= _load(rootBundle);

@visibleForTesting
void resetGalleryCache() => _gallery = null;

/// Tests load the bundle for real (`runAsync`), then hand the entries to the
/// editor with a future of their own fake-async zone.
@visibleForTesting
void setGalleryForTesting(List<GalleryEntry> entries) =>
    _gallery = Future.value(entries);

Future<List<GalleryEntry>> _load(AssetBundle bundle) async {
  final manifest = await AssetManifest.loadFromAssetBundle(bundle);
  final entries = <GalleryEntry>[];
  for (final path in manifest.listAssets()) {
    final slug = gallerySlugOf(path);
    if (slug == null) continue;
    try {
      final json = jsonDecode(await bundle.loadString(path));
      entries.add(galleryEntryFromJson(slug, json));
    } catch (e) {
      debugPrint('Gallery: skipped $path: $e');
    }
  }
  return entries..sort(compareGalleryEntries);
}

/// A copy of [t] the editor can change without touching the gallery's own.
LayeredTheme copyLayeredTheme(LayeredTheme t) =>
    layeredThemeFromJson(jsonDecode(jsonEncode(layeredThemeToJson(t)))).theme;

/// Link that opens a gallery theme: `?g=<slug>`.
String galleryLink(String slug, {String? baseUrl}) => Uri.parse(
  baseUrl ?? publicEditorUrl,
).replace(queryParameters: {galleryParam: slug}).toString();

/// Shows the gallery; returns the theme the user chose to open.
Future<GalleryEntry?> showGalleryDialog(BuildContext context) =>
    showDialog<GalleryEntry>(
      context: context,
      builder: (context) => const _GalleryDialog(),
    );

class _GalleryDialog extends StatelessWidget {
  const _GalleryDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 1180,
          maxHeight: size.height * 0.88,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gallery', style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        Text(
                          'Themes made with MaterialCraft. Open one to start '
                          'from it: you can change everything and export it. '
                          'To add yours, use Submit in the editor.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant),
            Flexible(
              child: FutureBuilder<List<GalleryEntry>>(
                future: loadGallery(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return const _Message("The gallery couldn't be loaded.");
                  }
                  final entries = snap.data;
                  if (entries == null) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (entries.isEmpty) {
                    return const _Message('No themes in the gallery yet.');
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(20),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 380,
                          mainAxisExtent: 268,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: entries.length,
                    itemBuilder: (context, i) => GalleryCard(entry: entries[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(48),
    child: Center(child: Text(text)),
  );
}

/// One gallery theme: live light/dark preview, name, author and actions.
class GalleryCard extends StatefulWidget {
  const GalleryCard({super.key, required this.entry});

  final GalleryEntry entry;

  @override
  State<GalleryCard> createState() => _GalleryCardState();
}

class _GalleryCardState extends State<GalleryCard> {
  late (ThemeData, ThemeData) _themes = _build();

  @override
  void didUpdateWidget(GalleryCard old) {
    super.didUpdateWidget(old);
    if (old.entry != widget.entry) _themes = _build();
  }

  (ThemeData, ThemeData) _build() {
    final ThemeConfig c = copyLayeredTheme(widget.entry.theme).resolved;
    // Outside the browser (tests) google_fonts can't download the fonts.
    if (!kIsWeb) {
      c
        ..fontFamily = null
        ..headFontFamily = null;
    }
    return (buildTheme(c, Brightness.light), buildTheme(c, Brightness.dark));
  }

  Future<void> _copyLink() async {
    final link = galleryLink(widget.entry.slug, baseUrl: editorBaseUrl());
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link to "${widget.entry.name}" copied.'),
        behavior: SnackBarBehavior.floating,
        width: 360,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final e = widget.entry;
    return Material(
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 132,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _MiniPreview(theme: _themes.$1)),
                Expanded(child: _MiniPreview(theme: _themes.$2)),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.name,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    e.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton(
                            onPressed: () => openUrl(e.authorUrl),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(
                              'by @${e.author}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy link',
                        onPressed: _copyLink,
                        icon: const Icon(Icons.link, size: 20),
                      ),
                      const SizedBox(width: 4),
                      FilledButton.tonal(
                        onPressed: () => Navigator.pop(context, e),
                        child: const Text('Open'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small, non-interactive scene drawn with [theme]: buttons, a field and
/// controls, scaled down to fit the card.
class _MiniPreview extends StatelessWidget {
  const _MiniPreview({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return ColoredBox(
            color: cs.surface,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    // Room for the biggest buttons and fields; FittedBox
                    // scales the scene down to the card.
                    width: 300,
                    height: 210,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              PreviewButton(
                                kind: ButtonKind.filled,
                                label: 'Save',
                              ),
                              SizedBox(width: 8),
                              PreviewButton(
                                kind: ButtonKind.outlined,
                                label: 'Cancel',
                              ),
                            ],
                          ),
                          const TextField(
                            decoration: InputDecoration(hintText: 'Email'),
                          ),
                          Row(
                            children: [
                              Checkbox(value: true, onChanged: (_) {}),
                              Switch(value: true, onChanged: (_) {}),
                              const Spacer(),
                              Text(
                                'Aa',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
