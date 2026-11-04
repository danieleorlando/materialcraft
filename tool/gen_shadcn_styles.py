#!/usr/bin/env python3
"""Generates lib/model/shadcn_styles.dart from the 8 shadcn/ui styles.

Sources: tool/shadcn/styles/style-*.css (apps/v4/registry/styles, MIT) and
tool/shadcn/config.ts (preset fonts). Every style defines the same `.cn-*`
classes with `@apply` of Tailwind utilities: here we translate them into the
values the preset uses (heights, padding, radii, text, rings, shadows).

Base radius --radius 0.625rem (10px): sm 0.6× · md 0.8× · lg 1× ·
xl 1.4× · 2xl 1.8× · 3xl 2.2× · 4xl 2.6×.

Usage: python3 -I tool/gen_shadcn_styles.py
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "tool" / "shadcn"
OUT = ROOT / "lib" / "model" / "shadcn_styles.dart"

STYLES = ["vega", "nova", "maia", "lyra", "mira", "luma", "rhea", "sera"]
R = 10.0
RADII = {
    "none": 0, "sm": R * 0.6, "md": R * 0.8, "lg": R, "xl": R * 1.4,
    "2xl": R * 1.8, "3xl": R * 2.2, "4xl": R * 2.6, "full": 9999,
    "": R * 0.4,  # `rounded` = 0.25rem... not used by the styles
}
TEXT = {"xs": (12, 16), "sm": (14, 20), "base": (16, 24), "lg": (18, 28)}
FONTS = {
    "inter": "Inter", "geist": "Geist", "figtree": "Figtree",
    "jetbrains-mono": "JetBrains Mono", "noto-sans": "Noto Sans",
}


def classes(style):
    css = (SRC / "styles" / f"style-{style}.css").read_text()
    return {
        m.group(1): m.group(2).split()
        for m in re.finditer(r"\.(cn-[a-z0-9-]+)\s*\{\s*@apply\s+([^;]*);", css)
    }


def plain(tokens):
    """Utilities without variants (no `hover:`, `data-...:` etc.)."""
    return [t for t in tokens if ":" not in t.split("[")[0]]


def spacing(v):
    if v.startswith("[") and v.endswith("]"):
        inner = v[1:-1]
        if inner.endswith("px"):
            return float(inner[:-2])
        if inner.endswith("rem"):
            return float(inner[:-3]) * 16
        return None
    try:
        return float(v) * 4
    except ValueError:
        return None


def find(tokens, prefix):
    """Value of the last `prefix-<v>` utility (e.g. h-9 -> '9')."""
    val = None
    for t in plain(tokens):
        if t.startswith(prefix + "-"):
            val = t[len(prefix) + 1:]
    return val


def length(tokens, prefix, default=None):
    v = find(tokens, prefix)
    s = spacing(v) if v is not None else None
    return default if s is None else s


def radius(tokens, default=None):
    for t in reversed(plain(tokens)):
        if t == "rounded":
            return RADII["sm"]
        m = re.fullmatch(r"rounded-(none|sm|md|lg|xl|2xl|3xl|4xl|full)", t)
        if m:
            return RADII[m.group(1)]
        m = re.fullmatch(r"rounded-\[(\d+(?:\.\d+)?)px\]", t)
        if m:
            return float(m.group(1))
        m = re.fullmatch(r"rounded-\[min\(var\(--radius-(\w+)\),(\d+)px\)\]", t)
        if m:
            return min(RADII[m.group(1)], float(m.group(2)))
    return default


def text(tokens, default=None):
    """(size, line height) from text-xs, text-sm/relaxed, text-[0.8rem]."""
    out = default
    for t in plain(tokens):
        m = re.fullmatch(r"text-(xs|sm|base|lg)(?:/(relaxed|normal))?", t)
        if m:
            size, lh = TEXT[m.group(1)]
            if m.group(2) == "relaxed":
                lh = round(size * 1.625, 2)
            out = (size, lh)
        m = re.fullmatch(r"text-\[(\d*\.?\d+)rem\]", t)
        if m:
            size = float(m.group(1)) * 16
            out = (size, round(size * 1.5, 2))
    # md:text-* (desktop) vince su text-base.
    for t in tokens:
        m = re.fullmatch(r"md:text-(xs|sm|base)(?:/(relaxed|normal))?", t)
        if m:
            size, lh = TEXT[m.group(1)]
            if m.group(2) == "relaxed":
                lh = round(size * 1.625, 2)
            out = (size, lh)
    return out


def bg_alpha(tokens, token="input"):
    """Opacity of bg-<token>/NN without variants (0 if absent)."""
    for t in plain(tokens):
        m = re.fullmatch(rf"bg-{token}/(\d+)", t)
        if m:
            return int(m.group(1)) / 100
    return 0


def weight(tokens, default=500):
    for t in plain(tokens):
        m = re.fullmatch(r"font-(normal|medium|semibold|bold)", t)
        if m:
            return {"normal": 400, "medium": 500, "semibold": 600, "bold": 700}[m.group(1)]
    return default


def ring(tokens, default_width=0):
    """(width, opacity) of the focus ring."""
    width, alpha = default_width, 0.5
    for t in tokens:
        m = re.fullmatch(r"(?:focus-visible:)?ring-(\d+|\[(\d+)px\])", t)
        if m and "focus-visible" in t:
            width = float(m.group(2) or m.group(1))
        m = re.fullmatch(r"focus-visible:ring-ring/(\d+)", t)
        if m:
            alpha = int(m.group(1)) / 100
    return width, alpha


def shadow(tokens):
    for t in plain(tokens):
        m = re.fullmatch(r"shadow-(xs|sm|md|lg|xl|none)", t)
        if m:
            return m.group(1)
    return "none"


def ring1(tokens):
    """Border made with ring-1 ring-foreground/NN (light, dark)."""
    if "ring-1" not in tokens:
        return None
    light = dark = None
    for t in tokens:
        m = re.fullmatch(r"(dark:)?ring-foreground/(\d+)", t)
        if m:
            if m.group(1):
                dark = int(m.group(2)) / 100
            else:
                light = int(m.group(2)) / 100
    if light is None:
        return None
    return light, dark if dark is not None else light


def group_size(tokens, name):
    """switch: group-data-[size=default]/switch:size-4 (or h-/w-)."""
    w = h = None
    for t in tokens:
        m = re.fullmatch(rf"group-data-\[size=default\]/{name}:(size|w|h)-([\w.\[\]]+)", t)
        if m:
            v = spacing(m.group(2))
            if m.group(1) in ("size", "w"):
                w = v
            if m.group(1) in ("size", "h"):
                h = v
    return w, h


def switch_size(tokens):
    w = h = None
    for t in tokens:
        m = re.fullmatch(r"data-\[size=default\]:(w|h)-([\w.\[\]]+)", t)
        if m:
            v = spacing(m.group(2))
            if m.group(1) == "w":
                w = v
            else:
                h = v
    return w, h


def bg_ref(tokens, prefix=""):
    """Background `{prefix}bg-<token>[/NN]` as "token" or "token/NN" (or None)."""
    out = None
    for t in tokens:
        if not t.startswith(prefix + "bg-"):
            continue
        rest = t[len(prefix) + 3:]
        if ":" in rest or rest.startswith("["):
            continue
        out = rest
    return out


def quoted(v):
    return "null" if v is None else f"'{v}'"


def fonts():
    cfg = (SRC / "config.ts").read_text()
    out = {}
    for m in re.finditer(r'name: "radix-(\w+)",.*?font: "([\w-]+)"', cfg, re.S):
        out[m.group(1)] = FONTS.get(m.group(2), "Inter")
    return out


def num(v):
    if v is None:
        return "null"
    v = round(float(v), 2)
    return str(int(v)) if v == int(v) else str(v)


def spec(style, font):
    c = classes(style)
    btn = c["cn-button"]
    bsz = {k: c.get(f"cn-button-size-{k}", []) for k in
           ["default", "xs", "sm", "lg", "icon"]}
    b_radius = radius(btn, 0)
    b_text = text(btn, TEXT["sm"])
    ring_w, ring_a = ring(btn, 3)

    def size(k):
        t = bsz[k]
        h = length(t, "h") or length(t, "size")
        return (h, length(t, "px", 0), text(t, b_text), radius(t, b_radius))

    outline = c["cn-button-variant-outline"]
    inp = c["cn-input"]
    i_ring = ring(inp, 3)
    card = c["cn-card"]
    dialog = c["cn-dialog-content"]
    menu = c["cn-dropdown-menu-content"]
    item = c["cn-dropdown-menu-item"]
    sw = c["cn-switch"]
    sw_w, sw_h = switch_size(sw)
    th_w, th_h = group_size(c["cn-switch-thumb"], "switch")
    track = c["cn-slider-track"]
    thumb = c["cn-slider-thumb"]
    thumb_border = (
        "none" if "border-none" in thumb or "border" not in plain(thumb)
        else "ring" if "border-ring" in thumb else "primary"
    )
    toggle = c["cn-toggle"]
    toggle_sz = c["cn-toggle-size-default"]
    chk = c["cn-checkbox"]
    tabs = c["cn-tabs-trigger"]
    card_spacing = None
    for t in card:
        m = re.fullmatch(r"\[--card-spacing:--spacing\((\d+)\)\]", t)
        if m:
            card_spacing = int(m.group(1)) * 4

    tracking = 0
    if "tracking-widest" in btn:
        tracking = 0.1  # em
    elif "tracking-wider" in btn:
        tracking = 0.05

    fields = {
        "name": f"'{style}'",
        "font": f"'{font}'",
        "buttonRadius": num(b_radius),
        "buttonFontSize": num(b_text[0]),
        "buttonLineHeight": num(b_text[1]),
        "buttonWeight": num(weight(btn)),
        "buttonTracking": num(tracking),
        "buttonUppercase": "true" if "uppercase" in btn else "false",
        "pressDown": "true" if any("translate-y-px" in t for t in btn) else "false",
        "ringWidth": num(ring_w),
        "ringAlpha": num(ring_a),
        "sizes": "{" + ", ".join(
            f"'{k}': ({', '.join(num(x) if not isinstance(x, tuple) else f'({num(x[0])}, {num(x[1])})' for x in size(k))})"
            for k in bsz
        ) + "}",
        "outlineShadow": "true" if shadow(outline) == "xs" else "false",
        "destructiveSoft": "true" if "bg-destructive/10" in c["cn-button-variant-destructive"] else "false",
        "primaryHoverAlpha": num(next((int(t.split("/")[1]) / 100 for t in c["cn-button-variant-default"] if t.startswith("hover:bg-primary/")), 0.9)),
        "secondaryHoverMix": "true" if any("color-mix" in t for t in c["cn-button-variant-secondary"]) else "false",
        "outlineBg": quoted(bg_ref(outline)),
        "outlineBgDark": quoted(bg_ref(outline, "dark:")),
        "outlineHover": quoted(bg_ref(outline, "hover:")),
        "outlineHoverDark": quoted(bg_ref(outline, "dark:hover:")),
        "ghostHover": quoted(bg_ref(c["cn-button-variant-ghost"], "hover:")),
        "ghostHoverDark": quoted(bg_ref(c["cn-button-variant-ghost"], "dark:hover:")),
        "menuRing": "null" if ring1(menu) is None else f"({num(ring1(menu)[0])}, {num(ring1(menu)[1])})",
        "outlineDarkTransparent": "true" if "dark:bg-transparent" in outline else "false",
        "inputHeight": num(length(inp, "h", 36)),
        "inputRadius": num(radius(inp, 0)),
        "inputPaddingH": num(length(inp, "px", 12)),
        "inputFontSize": num(text(inp, TEXT["sm"])[0]),
        "inputLineHeight": num(text(inp, TEXT["sm"])[1]),
        "inputFillAlpha": num(bg_alpha(inp)),
        "inputUnderline": "true" if "border-b-input" in inp else "false",
        "inputShadow": "true" if shadow(inp) == "xs" else "false",
        "inputRingWidth": num(i_ring[0]),
        "inputRingAlpha": num(i_ring[1]),
        "cardRadius": num(radius(card, 0)),
        "cardRing": "null" if ring1(card) is None else f"({num(ring1(card)[0])}, {num(ring1(card)[1])})",
        "cardShadow": f"'{shadow(card)}'",
        "cardPadding": num(card_spacing or 24),
        "dialogRadius": num(radius(dialog, 0)),
        "dialogPadding": num(length(dialog, "p", 24)),
        "dialogShadow": f"'{shadow(dialog)}'",
        "dialogRing": "null" if ring1(dialog) is None else f"({num(ring1(dialog)[0])}, {num(ring1(dialog)[1])})",
        "menuRadius": num(radius(menu, 0)),
        "menuPadding": num(length(menu, "p", 0)),
        "menuShadow": f"'{shadow(menu)}'",
        "itemRadius": num(radius(item, 0)),
        "itemPaddingH": num(length(item, "px", 8)),
        "itemPaddingV": num(length(item, "py", 6)),
        "itemFontSize": num(text(item, TEXT["sm"])[0]),
        "itemWeight": num(weight(item, 400)),
        "tooltipRadius": num(radius(c["cn-tooltip-content"], 0)),
        "badgeRadius": num(radius(c["cn-badge"], 0)),
        "toastRadius": num(radius(c["cn-toast"], 0)),
        "toggleRadius": num(radius(toggle, 0)),
        "toggleHeight": num(length(toggle_sz, "h", 36)),
        "togglePaddingH": num(length(toggle_sz, "px", 8)),
        "toggleFontSize": num(text(toggle, TEXT["sm"])[0]),
        "checkboxRadius": num(radius(chk, 0)),
        "checkboxFillAlpha": num(bg_alpha(chk)),
        "switchWidth": num(sw_w),
        "switchHeight": num(sw_h),
        "switchThumbWidth": num(th_w),
        "switchThumbHeight": num(th_h),
        "switchBorder": num(2 if "border-2" in sw else 1),
        "sliderTrack": num(length(track, "h") or next(
            (spacing(t.split("-")[-1]) for t in track if t.startswith("data-horizontal:h-")), 6)),
        "sliderTrackFillAlpha": num(bg_alpha(track)),
        "sliderThumbWidth": num(length(thumb, "w") or length(thumb, "size")),
        "sliderThumbHeight": num(length(thumb, "h") or length(thumb, "size")),
        "sliderThumbRadius": num(radius(thumb, 0)),
        "sliderThumbBorder": f"'{thumb_border}'",
        "sliderThumbFill": "'primary'" if "bg-primary" in thumb else "'white'",
        "sliderThumbShadow": f"'{shadow(thumb)}'",
        "tabsFontSize": num(text(tabs, TEXT["sm"])[0]),
    }
    body = ",\n".join(f"    {k}: {v}" for k, v in fields.items())
    return f"  '{style}': ShadcnStyleSpec(\n{body},\n  ),"


def main():
    f = fonts()
    missing = [s for s in STYLES if s not in f]
    if missing:
        sys.exit(f"Missing fonts for: {missing}")
    out = [
        "// GENERATED by tool/gen_shadcn_styles.py: do not edit by hand.",
        "//",
        "// The 8 shadcn/ui styles (apps/v4/registry/styles, MIT) translated",
        "// into the values used by the preset. See tool/shadcn/.",
        "",
        "import 'shadcn_style_spec.dart';",
        "",
        "const shadcnStyles = <String, ShadcnStyleSpec>{",
    ]
    for s in STYLES:
        out.append(spec(s, f[s]))
    out.append("};")
    OUT.write_text("\n".join(out) + "\n")
    print(f"{len(STYLES)} styles -> {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
