import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:materialcraft/materialcraft.dart';

void main() {
  test('AppButtonStyles: sizes without a style fall back to medium', () {
    final danger = FilledButton.styleFrom(backgroundColor: Colors.red);
    final small = FilledButton.styleFrom(backgroundColor: Colors.pink);
    final styles = AppButtonStyles({
      (AppButtonKind.danger, AppButtonSize.medium): danger,
      (AppButtonKind.danger, AppButtonSize.small): small,
    });
    expect(styles.style(AppButtonKind.danger), danger);
    expect(styles.style(AppButtonKind.danger, AppButtonSize.small), small);
    expect(styles.style(AppButtonKind.danger, AppButtonSize.xs), danger);
    expect(styles.style(AppButtonKind.filled), isNull);
  });

  testWidgets('AppSwitch without AppSwitchStyle is the Material Switch', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(child: AppSwitch(value: true, onChanged: (_) {})),
      ),
    );
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('AppSwitch with AppSwitchStyle: theme geometry and tap', (
    tester,
  ) async {
    var value = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [
            AppSwitchStyle(width: 44, height: 24, thumbSize: 16),
          ],
        ),
        home: Material(
          child: Center(
            child: StatefulBuilder(
              builder: (context, setState) => AppSwitch(
                value: value,
                onChanged: (v) => setState(() => value = v),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(Switch), findsNothing);
    await tester.tap(find.byType(AppSwitch));
    await tester.pumpAndSettle();
    expect(value, isTrue);
  });
}
