import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../model/gallery.dart';
import '../model/presets.dart';
import '../model/share_link.dart';
import '../model/theme_builder.dart';
import '../model/theme_config.dart';
import '../model/theme_json.dart';
import '../model/theme_layers.dart';
import 'preview_pane.dart';
import 'style_properties.dart';
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

/// Address of the gallery page.
const galleryRoute = '/gallery';

/// The gallery as a page of its own (`/gallery`): a grid of themes with
/// filters by style. [onOpen] puts the chosen theme in the editor, which the
/// page returns to first.
class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key, required this.onOpen});

  final ValueChanged<GalleryEntry> onOpen;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  /// Style filter (null = all).
  PresetStyle? _style;

  void _open(GalleryEntry entry) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onOpen(entry);
  }

  void _back() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        leading: IconButton(
          tooltip: 'Back to the editor',
          onPressed: _back,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text.rich(
          TextSpan(
            text: 'MaterialCraft',
            children: [
              TextSpan(
                text: '  ·  Gallery',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
              ),
            ],
          ),
        ),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: cs.outlineVariant)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.tonalIcon(
              onPressed: _back,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Editor'),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<GalleryEntry>>(
        future: loadGallery(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const _Message("The gallery couldn't be loaded.");
          }
          final all = snap.data;
          if (all == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final styles = {for (final e in all) e.theme.base.style};
          final entries = _style == null
              ? all
              : all.where((e) => e.theme.base.style == _style).toList();
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Centered(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gallery', style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 6),
                        Text(
                          'Themes made with MaterialCraft. Open one to start '
                          'from it: you can change everything and export it. '
                          'To add yours, use Submit in the editor.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: Text('All (${all.length})'),
                              selected: _style == null,
                              onSelected: (_) => setState(() => _style = null),
                            ),
                            for (final style in PresetStyle.values)
                              if (styles.contains(style))
                                ChoiceChip(
                                  label: Text(
                                    '${styleInfo[style]!.$1} '
                                    '(${all.where((e) => e.theme.base.style == style).length})',
                                  ),
                                  selected: _style == style,
                                  onSelected: (_) =>
                                      setState(() => _style = style),
                                ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (all.isEmpty)
                const SliverToBoxAdapter(
                  child: _Message('No themes in the gallery yet.'),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                sliver: _SliverCentered(
                  maxCrossAxisExtent: _maxContentWidth - 48,
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 420,
                          mainAxisExtent: 268,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                    itemCount: entries.length,
                    itemBuilder: (context, i) => GalleryCard(
                      key: ValueKey(entries[i].slug),
                      entry: entries[i],
                      onOpen: () => _open(entries[i]),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

const _maxContentWidth = 1400.0;

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(48),
    child: Center(child: Text(text)),
  );
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxContentWidth),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}

/// Centers a sliver and limits its width, like [_Centered] for boxes.
class _SliverCentered extends StatelessWidget {
  const _SliverCentered({
    required this.maxCrossAxisExtent,
    required this.sliver,
  });

  final double maxCrossAxisExtent;
  final Widget sliver;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) {
      final extra = constraints.crossAxisExtent - maxCrossAxisExtent;
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: extra > 0 ? extra / 2 : 0),
        sliver: sliver,
      );
    },
  );
}

/// One gallery theme: live light/dark preview, name, author and actions.
class GalleryCard extends StatefulWidget {
  const GalleryCard({super.key, required this.entry, required this.onOpen});

  final GalleryEntry entry;
  final VoidCallback onOpen;

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
                        onPressed: widget.onOpen,
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
