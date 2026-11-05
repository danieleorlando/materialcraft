import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'editor/editor_page.dart';
import 'editor/gallery_page.dart';

void main() {
  // Plain addresses (/gallery) instead of #/gallery. vercel.json serves
  // index.html for them.
  usePathUrlStrategy();
  runApp(const MaterialCraftApp());
}

/// The editor, always at the bottom of the stack: the gallery opens themes
/// in it.
final _editorKey = GlobalKey<EditorPageState>();

class MaterialCraftApp extends StatelessWidget {
  const MaterialCraftApp({super.key});

  static Route<void> _editor() => MaterialPageRoute(
    settings: const RouteSettings(name: '/'),
    builder: (_) => EditorPage(key: _editorKey),
  );

  static Route<void> _gallery() => MaterialPageRoute(
    settings: const RouteSettings(name: galleryRoute),
    builder: (_) => GalleryPage(
      onOpen: (entry) => _editorKey.currentState?.openFromGallery(entry),
    ),
  );

  static bool _isGallery(String? name) =>
      Uri.tryParse(name ?? '/')?.path == galleryRoute;

  @override
  Widget build(BuildContext context) {
    // Neutral theme for the editor itself: the theme being edited lives only
    // in the preview, so the interface doesn't change while you work.
    return MaterialApp(
      title: 'MaterialCraft',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF455A64),
          dynamicSchemeVariant: DynamicSchemeVariant.neutral,
        ),
        visualDensity: VisualDensity.standard,
      ),
      // Any address other than /gallery (including /?t= and /?g= links)
      // opens the editor; /gallery opens the gallery on top of it.
      onGenerateInitialRoutes: (name) => [
        _editor(),
        if (_isGallery(name)) _gallery(),
      ],
      onGenerateRoute: (settings) =>
          _isGallery(settings.name) ? _gallery() : _editor(),
    );
  }
}
