import 'package:flutter/material.dart';
import 'package:materialcraft/materialcraft.dart';

void main() => runApp(const ExampleApp());

/// A minimal theme using the materialcraft extensions. Real themes are
/// usually exported from the MaterialCraft editor as `app_theme.dart`.
ThemeData buildTheme() {
  final colorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4));
  return ThemeData(
    colorScheme: colorScheme,
    extensions: [
      AppButtonStyles({
        (AppButtonKind.danger, AppButtonSize.medium): FilledButton.styleFrom(
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
        ),
      }),
      const AppSwitchStyle(
        width: 44,
        height: 24,
        thumbSize: 16,
        trackRadius: 0,
        thumbRadius: 0,
        thumbBorder: true,
      ),
    ],
  );
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) =>
      MaterialApp(theme: buildTheme(), home: const ExamplePage());
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  bool _on = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('materialcraft')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            FilledButton(
              style: context.buttonStyle(AppButtonKind.danger),
              onPressed: () {},
              child: const Text('Delete'),
            ),
            AppSwitch(value: _on, onChanged: (v) => setState(() => _on = v)),
          ],
        ),
      ),
    );
  }
}
