import 'dart:math' as math;
import 'dart:ui' show Color;

// --- Conversions (the same as tool/gen_boardui_tokens.py) --------------------

double _toLinear(double c) =>
    c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _toSrgb(double c) {
  final x = c.clamp(0.0, 1.0);
  return x <= 0.0031308 ? 12.92 * x : 1.055 * math.pow(x, 1 / 2.4) - 0.055;
}

double _cbrt(double x) =>
    x < 0 ? -math.pow(-x, 1 / 3).toDouble() : math.pow(x, 1 / 3).toDouble();

/// sRGB (0–1) → OKLab.
(double, double, double) srgbToOklab(double r, double g, double b) {
  r = _toLinear(r);
  g = _toLinear(g);
  b = _toLinear(b);
  final l = _cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  final m = _cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  final s = _cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  return (
    0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
  );
}

/// Linear components (no clamp), to know whether a color is in gamut.
(double, double, double) _oklabToLinear(double L, double a, double b) {
  final l = math.pow(L + 0.3963377774 * a + 0.2158037573 * b, 3).toDouble();
  final m = math.pow(L - 0.1055613458 * a - 0.0638541728 * b, 3).toDouble();
  final s = math.pow(L - 0.0894841775 * a - 1.2914855480 * b, 3).toDouble();
  return (
    4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
  );
}

/// OKLab → sRGB (0–1), with clamp like the generator.
(double, double, double) oklabToSrgb(double L, double a, double b) {
  final (r, g, bb) = _oklabToLinear(L, a, b);
  return (_toSrgb(r), _toSrgb(g), _toSrgb(bb));
}

/// Color in OKLCH: L (0–1), C (≈0–0.4), H (degrees).
typedef Oklch = (double, double, double);

Oklch toOklch(Color c) {
  final (L, a, b) = srgbToOklab(c.r, c.g, c.b);
  return (L, math.sqrt(a * a + b * b), (_deg(math.atan2(b, a)) + 360) % 360);
}

/// OKLCH → Color. If the color is outside the sRGB gamut it reduces chroma
/// (better
/// than clipping the channels, which shifts the hue).
Color fromOklch(double L, double C, double H, {bool gamutMap = true}) {
  final h = H * math.pi / 180;
  var c = C;
  if (gamutMap) {
    bool inGamut(double c) {
      final (r, g, b) = _oklabToLinear(L, c * math.cos(h), c * math.sin(h));
      const e = 1e-6;
      return r >= -e &&
          r <= 1 + e &&
          g >= -e &&
          g <= 1 + e &&
          b >= -e &&
          b <= 1 + e;
    }

    if (!inGamut(c)) {
      var lo = 0.0;
      var hi = c;
      for (var i = 0; i < 24; i++) {
        final mid = (lo + hi) / 2;
        if (inGamut(mid)) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      c = lo;
    }
  }
  final (r, g, b) = oklabToSrgb(L, c * math.cos(h), c * math.sin(h));
  return _color(r, g, b, 1);
}

double _deg(double rad) => rad * 180 / math.pi;

/// Like the generator's Dart `round()`: channel 0–1 → 0–255.
int _byte(double x) => (x.clamp(0.0, 1.0) * 255 + 0.5).floor();

Color _color(double r, double g, double b, double a) =>
    Color.fromARGB(_byte(a), _byte(r), _byte(g), _byte(b));

/// Perceptual distance (OKLab) between two colors: < 0.02 is nearly invisible.
double deltaE(Color x, Color y) {
  final (l1, a1, b1) = srgbToOklab(x.r, x.g, x.b);
  final (l2, a2, b2) = srgbToOklab(y.r, y.g, y.b);
  return math.sqrt(
    (l1 - l2) * (l1 - l2) + (a1 - a2) * (a1 - a2) + (b1 - b2) * (b1 - b2),
  );
}

// --- Contrasto (WCAG 2) -------------------------------------------------------

double luminance(Color c) =>
    0.2126 * _toLinear(c.r) + 0.7152 * _toLinear(c.g) + 0.0722 * _toLinear(c.b);

double contrastRatio(Color a, Color b) {
  final la = luminance(a);
  final lb = luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

const _black = Color(0xFF000000);
const _white = Color(0xFFFFFFFF);

/// Large or bold text (buttons, headings): white if it reaches 3:1
/// (the WCAG threshold for large text), otherwise black. It's what the
/// RetroUI designers chose on all 7 palettes.
Color onColorBold(Color background, {Color light = _white}) =>
    contrastRatio(background, light) >= 3 ? light : _black;

/// Black or white, whichever reads better on [background].
Color onColor(Color background, {Color dark = _black, Color light = _white}) =>
    contrastRatio(background, dark) >= contrastRatio(background, light)
    ? dark
    : light;

// --- color-mix and BoardUI token definitions --------------------------------

enum MixSpace { srgb, oklab }

/// `color-mix(in <space>, a p, b)` with premultiplied alpha (CSS Color 5).
Color mixColors(Color a, double p, Color b, MixSpace space) {
  final q = 1 - p;
  final alpha = a.a * p + b.a * q;
  if (alpha == 0) return const Color(0x00000000);
  (double, double, double) ch(Color c) => c.a == 0
      ? (0, 0, 0)
      : space == MixSpace.oklab
      ? srgbToOklab(c.r, c.g, c.b)
      : (c.r, c.g, c.b);
  final (x1, y1, z1) = ch(a);
  final (x2, y2, z2) = ch(b);
  double m(double u, double v) => (u * a.a * p + v * b.a * q) / alpha;
  final (x, y, z) = (m(x1, x2), m(y1, y2), m(z1, z2));
  if (space == MixSpace.oklab) {
    final (r, g, bb) = oklabToSrgb(x, y, z);
    return _color(r, g, bb, alpha);
  }
  return _color(x, y, z, alpha);
}

/// How a token is defined: a reference to a scale, a fixed color or a mix.
sealed class TokenExpr {
  const TokenExpr();

  Color eval(Map<int, Color>? Function(String family) scale);
}

class TPrim extends TokenExpr {
  const TPrim(this.family, this.shade);

  final String family;
  final int shade;

  @override
  Color eval(Map<int, Color>? Function(String family) scale) {
    final c = scale(family)?[shade];
    if (c == null) throw ArgumentError('Missing shade: $family-$shade');
    return c;
  }
}

class TLit extends TokenExpr {
  const TLit(this.argb);

  final int argb;

  @override
  Color eval(Map<int, Color>? Function(String family) scale) => Color(argb);
}

class TMix extends TokenExpr {
  const TMix(this.space, this.a, this.p, this.b);

  final MixSpace space;
  final TokenExpr a;
  final double p;
  final TokenExpr b;

  @override
  Color eval(Map<int, Color>? Function(String family) scale) =>
      mixColors(a.eval(scale), p, b.eval(scale), space);
}

// --- Tailwind scales from a color --------------------------------------------

/// Generates a 50–950 scale for [color] modelled on a Tailwind family.
///
/// Picks the reference family with the closest hue (or
/// [reference]), puts [color] at the shade with the most similar lightness
/// and copies its lightness curve; chroma and hue follow the color, with
/// the same relative variations as the family. With a Tailwind color
/// (e.g. blue-500) it rebuilds its own scale.
Map<int, Color> tailwindScaleFrom(
  Color color,
  Map<String, Map<int, Oklch>> families, {
  String? reference,
  Iterable<String>? candidates,
  bool gamutMap = false,
}) {
  final (l0, c0, h0) = toOklch(color);
  double hueDist(double a, double b) {
    final d = (a - b).abs() % 360;
    return d > 180 ? 360 - d : d;
  }

  // Reference family and "anchor" shade.
  String? bestFam;
  int? bestShade;
  var best = double.infinity;
  for (final f
      in reference != null ? [reference] : (candidates ?? families.keys)) {
    final fam = families[f];
    if (fam == null) continue;
    for (final e in fam.entries) {
      final (l, c, h) = e.value;
      // Hue weighted by chroma (it matters little for grays), plus lightness
      // and chroma.
      final dh = hueDist(h, h0) / 180 * math.min(c, c0) * 4;
      final d = dh * dh + (l - l0) * (l - l0) + (c - c0) * (c - c0);
      if (d < best) {
        best = d;
        bestFam = f;
        bestShade = e.key;
      }
    }
  }
  final fam = families[bestFam]!;
  final (la, ca, ha) = fam[bestShade]!;
  return {
    for (final e in fam.entries)
      e.key: e.key == bestShade
          ? color
          : fromOklch(
              _remapL(e.value.$1, la, l0),
              ca == 0 ? c0 : e.value.$2 * c0 / ca,
              (h0 + _hueDelta(e.value.$3, ha) + 360) % 360,
              // Like the generator (and browsers on sRGB screens): channel
              // clipping, so a Tailwind color rebuilds its own scale.
              gamutMap: gamutMap,
            ),
  };
}

/// Shifts the family's lightness [l] so that the anchor [from]
/// lands on [to], keeping the endpoints (0 and 1).
double _remapL(double l, double from, double to) {
  if (l <= from) return from == 0 ? to : l * to / from;
  return from == 1 ? to : 1 - (1 - l) * (1 - to) / (1 - from);
}

double _hueDelta(double h, double ref) {
  var d = h - ref;
  if (d > 180) d -= 360;
  if (d < -180) d += 360;
  return d;
}
