#!/usr/bin/env python3
"""Generates lib/model/boardui_tokens.dart from the BoardUI and Tailwind v4 CSS.

Sources (copied into tool/boardui/, MIT license):
  - theme.css           BoardUI styles/theme.css
  - tailwind-theme.css  tailwindcss@4.1.11 theme.css (palette OKLCH)

Resolves every --color-* token for light (:root) and dark (.dark): var()
references, color-mix in srgb/oklab (also with transparent), hex, rgb() with
alpha, oklch(). Tailwind primitives are overridden by BoardUI's (@theme),
including the accent-* aliases (= blue-*).

Usage: python3 -I tool/gen_boardui_tokens.py
"""

import math
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "tool" / "boardui"
OUT = ROOT / "lib" / "model" / "boardui_tokens.dart"
OUT_DEFS = ROOT / "lib" / "model" / "boardui_token_defs.dart"


# --- color conversions -------------------------------------------------------

def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def linear_to_srgb(c):
    c = max(0.0, min(1.0, c))
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055


def oklab_to_srgb(L, a, b):
    l_ = L + 0.3963377774 * a + 0.2158037573 * b
    m_ = L - 0.1055613458 * a - 0.0638541728 * b
    s_ = L - 0.0894841775 * a - 1.2914855480 * b
    l, m, s = l_ ** 3, m_ ** 3, s_ ** 3
    r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
    g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
    bb = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
    return linear_to_srgb(r), linear_to_srgb(g), linear_to_srgb(bb)


def srgb_to_oklab(r, g, b):
    r, g, b = srgb_to_linear(r), srgb_to_linear(g), srgb_to_linear(b)
    l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
    l_, m_, s_ = l ** (1 / 3), m ** (1 / 3), s ** (1 / 3)
    return (
        0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
        1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
        0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_,
    )


# A color is (r, g, b, a) with sRGB components in [0, 1].
TRANSPARENT = (0.0, 0.0, 0.0, 0.0)


def parse_literal(v):
    v = v.strip()
    if v == "transparent":
        return TRANSPARENT
    m = re.fullmatch(r"#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})", v)
    if m:
        h = m.group(1)
        if len(h) == 3:
            h = "".join(c * 2 for c in h)
        a = int(h[6:8], 16) / 255 if len(h) == 8 else 1.0
        return (int(h[0:2], 16) / 255, int(h[2:4], 16) / 255, int(h[4:6], 16) / 255, a)
    m = re.fullmatch(r"rgba?\(\s*([\d.]+)[\s,]+([\d.]+)[\s,]+([\d.]+)\s*(?:[/,]\s*([\d.]+%?))?\s*\)", v)
    if m:
        a = m.group(4)
        alpha = 1.0 if a is None else (float(a[:-1]) / 100 if a.endswith("%") else float(a))
        return (float(m.group(1)) / 255, float(m.group(2)) / 255, float(m.group(3)) / 255, alpha)
    m = re.fullmatch(r"oklch\(\s*([\d.]+)%\s+([\d.]+)\s+([\d.]+)\s*\)", v)
    if m:
        L, C, H = float(m.group(1)) / 100, float(m.group(2)), float(m.group(3))
        a, b = C * math.cos(math.radians(H)), C * math.sin(math.radians(H))
        return (*oklab_to_srgb(L, a, b), 1.0)
    return None


def mix(c1, p1, c2, space):
    """color-mix(in <space>, c1 p1, c2) with premultiplied alpha (CSS Color 5)."""
    p2 = 1 - p1
    alpha = c1[3] * p1 + c2[3] * p2
    if alpha == 0:
        return TRANSPARENT
    if space == "oklab":
        a1 = srgb_to_oklab(*c1[:3]) if c1[3] > 0 else (0, 0, 0)
        a2 = srgb_to_oklab(*c2[:3]) if c2[3] > 0 else (0, 0, 0)
    else:
        a1, a2 = c1[:3], c2[:3]
    ch = [(x * c1[3] * p1 + y * c2[3] * p2) / alpha for x, y in zip(a1, a2)]
    rgb = oklab_to_srgb(*ch) if space == "oklab" else ch
    return (*rgb, alpha)


# --- parsing CSS ----------------------------------------------------------------

def strip_comments(s):
    return re.sub(r"/\*.*?\*/", "", s, flags=re.S)


def block(src, selector):
    """Content of the first `selector {` block (balanced braces)."""
    i = src.find(selector + " {")
    if i < 0:
        sys.exit(f"Block not found: {selector}")
    j = src.index("{", i) + 1
    depth = 1
    k = j
    while depth:
        if src[k] == "{":
            depth += 1
        elif src[k] == "}":
            depth -= 1
        k += 1
    return src[j:k - 1]


def color_decls(body):
    return {
        m.group(1): " ".join(m.group(2).split())
        for m in re.finditer(r"--color-([a-z0-9-]+)\s*:\s*([^;]+);", body)
    }


def main():
    tw = strip_comments((SRC / "tailwind-theme.css").read_text())
    bu = strip_comments((SRC / "theme.css").read_text())

    primitives = color_decls(tw)  # tailwind: neutral-500, white, ...
    # BoardUI's @theme (the first block): primitive overrides + accent-*.
    first_theme = block(bu, "@theme")
    primitives.update(color_decls(first_theme))
    light = color_decls(block(bu, ":root"))
    dark = color_decls(block(bu, ".dark"))

    unresolved = []

    def resolve(name, mode, stack=()):
        if name in stack:
            sys.exit(f"Riferimento circolare: {' -> '.join(stack + (name,))}")
        table = [dark, light, primitives] if mode == "dark" else [light, primitives]
        for t in table:
            if name in t:
                return evaluate(t[name], mode, stack + (name,))
        unresolved.append(name)
        return None

    def evaluate(v, mode, stack):
        lit = parse_literal(v)
        if lit:
            return lit
        m = re.fullmatch(r"var\(--color-([a-z0-9-]+)\)", v)
        if m:
            return resolve(m.group(1), mode, stack)
        m = re.fullmatch(r"color-mix\(in (srgb|oklab),\s*(.+?)\s+([\d.]+)%,\s*(.+)\)", v)
        if m:
            c1 = evaluate(m.group(2), mode, stack)
            c2 = evaluate(m.group(4), mode, stack)
            if c1 is None or c2 is None:
                return None
            return mix(c1, float(m.group(3)) / 100, c2, m.group(1))
        return None  # gradients and the like: not colors

    def argb(c):
        r, g, b, a = (int(max(0, min(1, x)) * 255 + 0.5) for x in c)  # like Dart round()
        return f"0x{a:02X}{r:02X}{g:02X}{b:02X}"

    # Primitives: families with numeric shades (Tailwind + accent).
    families = {}
    for name in primitives:
        m = re.fullmatch(r"([a-z]+)-(\d+)", name)
        if m:
            c = resolve(name, "light")
            if c:
                families.setdefault(m.group(1), {})[int(m.group(2))] = argb(c)

    tokens = {}
    skipped = []
    for name in sorted(light.keys() | dark.keys()):
        cl = resolve(name, "light") if name in light else None
        cd = resolve(name, "dark")
        if cl is None and name in light:
            skipped.append(name)
            continue
        if cl is None:
            cl = cd
        if cd is None:
            skipped.append(name)
            continue
        tokens[name] = (argb(cl), argb(cd))

    if unresolved:
        sys.exit(f"Unresolved references: {sorted(set(unresolved))}")

    # --- Token definitions (to recolor accent and neutral) -----------
    # Like resolve/evaluate, but stops at the family-shade primitives and
    # returns a Dart expression: TPrim / TLit / TMix.
    def is_prim(name):
        return re.fullmatch(r"([a-z]+)-(\d+)", name) and name in primitives \
            and name not in light and name not in dark

    def def_resolve(name, mode, stack=()):
        m = re.fullmatch(r"([a-z]+)-(\d+)", name)
        if m and is_prim(name):
            return f"TPrim('{m.group(1)}', {m.group(2)})"
        table = [dark, light, primitives] if mode == "dark" else [light, primitives]
        for t in table:
            if name in t:
                return def_eval(t[name], mode, stack + (name,))
        return None

    def def_eval(v, mode, stack):
        lit = parse_literal(v)
        if lit:
            return f"TLit({argb(lit)})"
        m = re.fullmatch(r"var\(--color-([a-z0-9-]+)\)", v)
        if m:
            return def_resolve(m.group(1), mode, stack)
        m = re.fullmatch(r"color-mix\(in (srgb|oklab),\s*(.+?)\s+([\d.]+)%,\s*(.+)\)", v)
        if m:
            a = def_eval(m.group(2), mode, stack)
            b = def_eval(m.group(4), mode, stack)
            if a is None or b is None:
                return None
            return f"TMix(MixSpace.{m.group(1)}, {a}, {float(m.group(3)) / 100}, {b})"
        return None

    defs = {}
    for name in tokens:
        dl = def_resolve(name, "light") if name in light else None
        dd = def_resolve(name, "dark")
        defs[name] = (dl or dd, dd)

    # Primitive scales in OKLCH (from the float values, before rounding).
    def to_oklch(c):
        L, a, b = srgb_to_oklab(*c[:3])
        return L, math.hypot(a, b), math.degrees(math.atan2(b, a)) % 360

    oklch_fams = {}
    for name in primitives:
        m = re.fullmatch(r"([a-z]+)-(\d+)", name)
        if m and m.group(1) != "accent":
            c = resolve(name, "light")
            if c:
                oklch_fams.setdefault(m.group(1), {})[int(m.group(2))] = to_oklch(c)

    order = ["neutral", "accent", "blue", "red", "orange", "amber", "yellow",
             "lime", "green", "emerald", "teal", "cyan", "sky", "indigo",
             "violet", "purple", "fuchsia", "pink", "rose", "slate", "gray",
             "zinc", "stone"]
    fams = [f for f in order if f in families] + sorted(f for f in families if f not in order)

    out = [
        "// GENERATED by tool/gen_boardui_tokens.py: do not edit by hand.",
        "//",
        "// Colors of BoardUI (https://github.com/BoardUI/boardui, MIT) and of the",
        "// Tailwind CSS v4 palette (MIT). See tool/boardui/ for sources and licenses.",
        "",
        "import 'dart:ui' show Color;",
        "",
        "/// Semantic token with light and dark values.",
        "class BoardToken {",
        "  const BoardToken(this.light, this.dark);",
        "",
        "  final Color light;",
        "  final Color dark;",
        "}",
        "",
        "/// Primitive palette (Tailwind v4 + BoardUI overrides; accent = blue).",
        "const boardPrimitives = <String, Map<int, Color>>{",
    ]
    for f in fams:
        out.append(f"  '{f}': {{")
        for shade in sorted(families[f]):
            out.append(f"    {shade}: Color({families[f][shade]}),")
        out.append("  },")
    out.append("};")
    out.append("")
    out.append(f"/// BoardUI's {len(tokens)} semantic color tokens (`--color-*`).")
    out.append("const boardTokens = <String, BoardToken>{")
    for name, (l, d) in tokens.items():
        out.append(f"  '{name}': BoardToken(Color({l}), Color({d})),")
    out.append("};")
    OUT.write_text("\n".join(out) + "\n")

    d = [
        "// GENERATED by tool/gen_boardui_tokens.py: do not edit by hand.",
        "//",
        "// How BoardUI tokens are defined (references to scales and",
        "// color-mix), to recompute them with a different accent or neutrals.",
        "",
        "import 'color_math.dart';",
        "",
        "/// Token → (light definition, dark definition).",
        "const boardTokenDefs = <String, (TokenExpr, TokenExpr)>{",
    ]
    for name, (dl, dd) in defs.items():
        d.append(f"  '{name}': ({dl}, {dd}),")
    d.append("};")
    d.append("")
    d.append("/// Tailwind v4 (+ BoardUI) scales in OKLCH: family → shade → (L, C, H).")
    d.append("const tailwindOklch = <String, Map<int, (double, double, double)>>{")
    for f in fams:
        if f not in oklch_fams:
            continue
        d.append(f"  '{f}': {{")
        for shade in sorted(oklch_fams[f]):
            L, C, H = oklch_fams[f][shade]
            d.append(f"    {shade}: ({L:.6f}, {C:.6f}, {H:.4f}),")
        d.append("  },")
    d.append("};")
    OUT_DEFS.write_text("\n".join(d) + "\n")
    print(f"{len(fams)} famiglie primitive, {len(tokens)} token -> {OUT.relative_to(ROOT)}")
    if skipped:
        print(f"Skipped (not colors, e.g. gradients): {skipped}")


if __name__ == "__main__":
    main()
