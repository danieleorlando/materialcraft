import 'package:flutter/material.dart';

import 'editor/editor_page.dart';

void main() {
  runApp(const MaterialCraftApp());
}

class MaterialCraftApp extends StatelessWidget {
  const MaterialCraftApp({super.key});

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
      home: const EditorPage(),
    );
  }
}
