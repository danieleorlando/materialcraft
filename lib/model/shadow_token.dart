import 'package:material_ui/material_ui.dart';

/// One CSS `box-shadow` layer: `x y blur spread rgba(0,0,0,alpha)`.
class CssShadow {
  const CssShadow(this.x, this.y, this.blur, this.spread, this.alpha);

  final double x;
  final double y;
  final double blur;
  final double spread;
  final double alpha;

  /// Flutter blur radius equivalent to the CSS blur.
  ///
  /// CSS: sigma = blur / 2. Flutter: sigma = radius * 0.57735 + 0.5
  /// (radius > 0). So radius = (blur / 2 - 0.5) / 0.57735.
  double get flutterBlur {
    final r = (blur / 2 - 0.5) / 0.57735;
    return r <= 0 ? 0 : double.parse(r.toStringAsFixed(3));
  }

  BoxShadow toBoxShadow() => BoxShadow(
    color: Color.fromRGBO(0, 0, 0, alpha),
    offset: Offset(x, y),
    blurRadius: flutterBlur,
    spreadRadius: spread,
  );
}

/// Tailwind v4 shadows with the BoardUI overrides, in light and dark.
enum ShadowToken {
  none('None', [], []),
  xs2('2xs', [CssShadow(0, 1, 0, 0, 0.05)], [CssShadow(0, 1, 0, 0, 0.16)]),
  xs('xs', [CssShadow(0, 1, 2, 0, 0.05)], [CssShadow(0, 1, 2, 0, 0.18)]),
  sm(
    'sm',
    [CssShadow(0, 1, 2, 0, 0.06), CssShadow(0, 1, 3, 0, 0.10)],
    [CssShadow(0, 1, 2, 0, 0.12), CssShadow(0, 1, 3, 0, 0.16)],
  ),
  md(
    'md',
    [CssShadow(0, 2, 4, -1, 0.06), CssShadow(0, 4, 6, -1, 0.10)],
    [CssShadow(0, 2, 4, -1, 0.12), CssShadow(0, 4, 6, -1, 0.18)],
  ),
  dropdown(
    'dropdown (BoardUI)',
    [CssShadow(0, 1, 1, 0, 0.04), CssShadow(0, 4, 4, 0, 0.02)],
    [CssShadow(0, 1, 1, 0, 0.14), CssShadow(0, 4, 4, 0, 0.10)],
  ),
  lg(
    'lg',
    [CssShadow(0, 4, 6, -2, 0.05), CssShadow(0, 10, 15, -3, 0.10)],
    [CssShadow(0, 4, 6, -2, 0.10), CssShadow(0, 10, 15, -3, 0.18)],
  ),

  // Tailwind v4 shadows without overrides (shadcn/ui): same in light and dark.
  twXs(
    'xs · Tailwind',
    [CssShadow(0, 1, 2, 0, 0.05)],
    [CssShadow(0, 1, 2, 0, 0.05)],
  ),
  twSm(
    'sm · Tailwind',
    [CssShadow(0, 1, 3, 0, 0.1), CssShadow(0, 1, 2, -1, 0.1)],
    [CssShadow(0, 1, 3, 0, 0.1), CssShadow(0, 1, 2, -1, 0.1)],
  ),
  twMd(
    'md · Tailwind',
    [CssShadow(0, 4, 6, -1, 0.1), CssShadow(0, 2, 4, -2, 0.1)],
    [CssShadow(0, 4, 6, -1, 0.1), CssShadow(0, 2, 4, -2, 0.1)],
  ),
  twLg(
    'lg · Tailwind',
    [CssShadow(0, 10, 15, -3, 0.1), CssShadow(0, 4, 6, -4, 0.1)],
    [CssShadow(0, 10, 15, -3, 0.1), CssShadow(0, 4, 6, -4, 0.1)],
  ),
  twXl(
    'xl · Tailwind',
    [CssShadow(0, 20, 25, -5, 0.1), CssShadow(0, 8, 10, -6, 0.1)],
    [CssShadow(0, 20, 25, -5, 0.1), CssShadow(0, 8, 10, -6, 0.1)],
  ),

  // Neobrutalism (RetroUI) "hard" shadows: offset, no blur, in the
  // border color (or the one given in `shadowColor`).
  hardXs('hard xs · 1px', [], [], hardOffset: 1),
  hardSm('hard sm · 2px', [], [], hardOffset: 2),
  hard('hard · 3px', [], [], hardOffset: 3),
  hardMd('hard md · 4px', [], [], hardOffset: 4),
  hardLg('hard lg · 6px', [], [], hardOffset: 6),
  hardXl('hard xl · 10px', [], [], hardOffset: 10, hardSpread: 1),

  // Ring around the border (shadcn/ui: focus-visible:ring-[3px]): a hard
  // shadow with no offset, 3px wide.
  ring3('ring · 3px', [], [], hardOffset: 0, hardSpread: 3);

  const ShadowToken(
    this.label,
    this.light,
    this.dark, {
    this.hardOffset,
    this.hardSpread = 0,
  });

  final String label;
  final List<CssShadow> light;
  final List<CssShadow> dark;

  /// Offset (x = y) of a hard shadow; null for blurred CSS shadows.
  final double? hardOffset;
  final double hardSpread;

  bool get isHard => hardOffset != null;

  /// Blurred CSS-style shadows (for non-hard tokens).
  List<BoxShadow> resolve(Brightness b) => [
    for (final s in b == Brightness.dark ? dark : light) s.toBoxShadow(),
  ];

  /// Shadows with the color for hard shadows ([hardColor]).
  List<BoxShadow> resolveWith(Brightness b, Color hardColor) => isHard
      ? [
          BoxShadow(
            color: hardColor,
            offset: Offset(hardOffset!, hardOffset!),
            spreadRadius: hardSpread,
          ),
        ]
      : resolve(b);
}
