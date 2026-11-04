import 'dart:math' as math;
import 'dart:ui' show Color;

import 'boardui_token_defs.dart';
import 'boardui_tokens.dart';
import 'color_math.dart';
import 'neobrutalism_tokens.dart';
import 'shadcn_tokens.dart';

// Palettes and token sets generated from a color chosen by the user. They're
// registered by key (derived from the colors, so stable): the ColorRefs
// (TokenColor, PaletteColor) find them with the same key.

String _hex(Color c) =>
    c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();

// --- Scales --------------------------------------------------------------------

/// Tailwind neutral families offered for BoardUI.
const neutralFamilies = <String, String>{
  'neutral': 'Neutral (BoardUI)',
  'slate': 'Slate · blue gray',
  'gray': 'Gray · cool gray',
  'zinc': 'Zinc · metallic gray',
  'stone': 'Stone · warm gray',
};

/// Hued families, candidates as a model for an accent.
const _hueFamilies = [
  'red', 'orange', 'amber', 'yellow', 'lime', 'green', 'emerald', 'teal', //
  'cyan', 'sky', 'blue', 'indigo', 'violet', 'purple', 'fuchsia', 'pink',
  'rose',
];

/// 50–950 scale (BoardUI also uses 925) for an accent.
Map<int, Color> accentScaleFor(Color accent) => _withShade925(
  tailwindScaleFrom(
    accent,
    tailwindOklch,
    candidates: _hueFamilies.where(tailwindOklch.containsKey),
  ),
);

/// Neutral scale: a Tailwind family, or generated from a gray.
Map<int, Color> neutralScaleFor({String? family, Color? custom}) {
  if (custom != null) {
    return _withShade925(
      tailwindScaleFrom(
        custom,
        tailwindOklch,
        candidates: neutralFamilies.keys,
      ),
    );
  }
  return _withShade925(boardPrimitives[family ?? 'neutral']!);
}

Map<int, Color> _withShade925(Map<int, Color> s) {
  if (s.containsKey(925) || !s.containsKey(900) || !s.containsKey(950)) {
    return s;
  }
  return {...s, 925: mixColors(s[900]!, 0.5, s[950]!, MixSpace.oklab)};
}

// --- BoardUI ricolorato ----------------------------------------------------------

final _boardSets = <String, Map<String, BoardToken>>{};

/// BoardUI tokens for a set (`null` = the official ones).
Map<String, BoardToken>? boardTokensFor(String? set) =>
    set == null ? boardTokens : _boardSets[set];

/// Recomputes all BoardUI tokens with [accent] and [neutral] and returns the
/// set key.
String registerBoardSet({
  required Map<int, Color> accent,
  required Map<int, Color> neutral,
}) {
  final key =
      'a${_hex(accent[500]!)}-n${_hex(neutral[500]!)}${_hex(neutral[100]!)}';
  _boardSets.putIfAbsent(key, () {
    Map<int, Color>? scale(String f) => switch (f) {
      'accent' => accent,
      'neutral' => neutral,
      _ => boardPrimitives[f],
    };
    return {
      for (final e in boardTokenDefs.entries)
        e.key: BoardToken(e.value.$1.eval(scale), e.value.$2.eval(scale)),
    };
  });
  return key;
}

// --- Neobrutalism from a primary ---------------------------------------------------

final _neoCustom = <String, Map<String, BoardToken>>{};

/// RetroUI palette (official or generated).
Map<String, BoardToken>? neoPaletteTokens(String palette) =>
    neoPalettes[palette] ?? _neoCustom[palette];

bool isCustomNeoPalette(String palette) => _neoCustom.containsKey(palette);

/// Generates and registers a RetroUI palette from [primary]; returns the key.
String registerNeoPalette(Color primary) {
  final key = 'custom-${_hex(primary)}';
  _neoCustom.putIfAbsent(key, () => generateNeoPalette(primary));
  return key;
}

/// Rules derived from the 7 official palettes (see the calibration test):
/// - hover: the same color, darker (L −0.07);
/// - muted: light tint of the primary (L 0.90, C 0.04), muted-foreground
///   dark tint (L 0.47);
/// - near-white background with a hint of tint; white card; black border and
///   text;
/// - accent: light, vivid complementary color;
/// - in dark: dark tinted-gray backgrounds and borders, primary lightened if
///   dark;
/// - text on colors: black or white depending on contrast (WCAG).
Map<String, BoardToken> generateNeoPalette(Color primary) {
  final (l, c, h) = toOklch(primary);
  Color tint(double lum, double chroma, [double hue = double.nan]) =>
      fromOklch(lum, chroma, hue.isNaN ? h : hue);

  final hover = tint(math.max(0.2, l - 0.07), c * 1.05);
  final darkPrimary = l < 0.6 ? tint(l + 0.08, c * 0.9) : primary;
  final darkHover = l < 0.6 ? primary : hover;
  final accent = tint(0.88, 0.15, (h + 180) % 360);
  final mutedFgC = (c * 0.7).clamp(0.07, 0.14);

  const black = Color(0xFF000000);
  const white = Color(0xFFFFFFFF);
  const fgDark = Color(0xFFF5F5F5);
  const destructive = Color(0xFFE63946);

  BoardToken t(Color light, Color dark) => BoardToken(light, dark);
  BoardToken on(Color light, Color dark) =>
      BoardToken(onColorBold(light), onColorBold(dark));

  final bgL = tint(0.985, math.min(0.006, c));
  final bgD = tint(0.17, math.min(0.006, c));
  final cardD = tint(0.21, math.min(0.007, c));
  final secondaryL = tint(0.25, math.min(0.01, c));
  final secondaryD = tint(0.27, math.min(0.007, c));
  final mutedL = tint(0.90, math.min(0.04, c));
  final mutedD = tint(0.30, math.min(0.045, c));

  return {
    'background': t(bgL, bgD),
    'foreground': t(black, fgDark),
    'card': t(white, cardD),
    'card-foreground': t(black, fgDark),
    'popover': t(white, cardD),
    'primary': t(primary, darkPrimary),
    'primary-hover': t(hover, darkHover),
    'primary-foreground': on(primary, darkPrimary),
    'secondary': t(secondaryL, secondaryD),
    'secondary-foreground': on(secondaryL, secondaryD),
    'muted': t(mutedL, mutedD),
    'muted-foreground': t(
      tint(0.47, math.min(mutedFgC, c)),
      tint(0.80, math.min(0.085, c)),
    ),
    'accent': t(accent, accent),
    'accent-foreground': on(accent, accent),
    'destructive': t(destructive, destructive),
    'destructive-foreground': t(white, white),
    'border': t(black, tint(0.30, math.min(0.007, c))),
    'input': t(white, white),
  };
}

// --- shadcn/ui --------------------------------------------------------------------

final _shadcnCustom = <String, Map<String, BoardToken>>{};

/// shadcn token: the accent (official or generated) wins over the base color.
BoardToken? shadcnToken(String base, String? accent, String name) {
  if (accent != null) {
    final a = shadcnAccents[accent] ?? _shadcnCustom[accent];
    final t = a?[name];
    if (t != null) return t;
  }
  return shadcnBaseColors[base]?[name];
}

/// Generates and registers a shadcn accent from [primary]; returns the key.
String registerShadcnAccent(Color primary) {
  final key = 'custom-${_hex(primary)}';
  _shadcnCustom.putIfAbsent(key, () => generateShadcnAccent(primary));
  return key;
}

/// The recipe of the 17 official accents (see the calibration test), on the
/// color's Tailwind scale: primary = the color in light and the next
/// shade in dark; text on top = shade 50 if readable (4.5:1),
/// otherwise 900 (like yellow and lime); charts 300/500/600/700/800;
/// zinc secondary as in all accents.
Map<String, BoardToken> generateShadcnAccent(Color primary) {
  final scale = accentScaleFor(primary);
  final shades = scale.keys.toList()..sort();
  // Shade the color corresponds to (the identical one in the scale).
  final anchor = scale.entries
      .reduce(
        (a, b) => deltaE(a.value, primary) <= deltaE(b.value, primary) ? a : b,
      )
      .key;
  int step(int from, int by) {
    final i = (shades.indexOf(from) + by).clamp(0, shades.length - 1);
    return shades[i];
  }

  final dark = scale[step(anchor, 1)]!;
  final fgLight = scale[50]!;
  final fgDark = scale[900]!;
  final fg = contrastRatio(primary, fgLight) >= 4.5 ? fgLight : fgDark;
  final zinc = shadcnAccents['blue']!;
  BoardToken t(Color l, Color d) => BoardToken(l, d);
  return {
    'primary': t(primary, dark),
    'primary-foreground': t(
      fg,
      contrastRatio(dark, fgLight) >= 4.5 ? fgLight : fgDark,
    ),
    'secondary': zinc['secondary']!,
    'secondary-foreground': zinc['secondary-foreground']!,
    'chart-1': t(scale[300]!, scale[300]!),
    'chart-2': t(scale[500]!, scale[500]!),
    'chart-3': t(scale[600]!, scale[600]!),
    'chart-4': t(scale[700]!, scale[700]!),
    'chart-5': t(scale[800]!, scale[800]!),
    'sidebar-primary': t(scale[600]!, scale[500]!),
    // Not used by components; the official ones don't follow a single rule.
    'sidebar-primary-foreground': t(scale[50]!, scale[50]!),
  };
}
