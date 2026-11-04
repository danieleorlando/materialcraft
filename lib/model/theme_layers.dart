import 'color_choice.dart';
import 'global_tokens.dart';
import 'presets.dart';
import 'surface_config.dart';
import 'text_field_config.dart';
import 'theme_config.dart';
import 'typography_config.dart';

/// Layered theme: base style (preset) with the chosen colors → global
/// properties → user edits on individual components.
///
/// Each value resolves from the most specific layer: if the user set it
/// on the component it wins, otherwise it comes from the global
/// properties, then from the preset, then from the Material 3 default. This way
/// you can change preset (e.g. another palette) without
/// losing the edits made by hand.
class LayeredTheme {
  LayeredTheme({ThemePreset? base}) : _base = base ?? ThemePreset.material3;

  ThemePreset _base;
  ThemePreset get base => _base;

  /// Chosen colors (empty = the style's official colors).
  final ColorChoice colors = ColorChoice();

  /// Global properties (radius, borders, shadows, height, motion).
  final GlobalTokens globals = GlobalTokens();

  /// Only the user's edits (`null` = inherit).
  final ThemeConfig edits = ThemeConfig();

  ThemeConfig? _presetConfig;
  ThemeConfig? _baseConfig;
  ThemeConfig? _resolved;

  /// The preset with the chosen colors.
  ThemeConfig get presetConfig => _presetConfig ??= _build(0);

  /// Preset + global properties, without the component edits.
  ThemeConfig get baseConfig => _baseConfig ??= _build(1);

  /// All layers: this is what the preview and the export see.
  ThemeConfig get resolved => _resolved ??= _build(2);

  ThemeConfig _build(int layers) {
    final c = ThemeConfig();
    _base.applyWithColors(c, colors);
    if (layers >= 1) applyGlobals(c, globals);
    if (layers >= 2) c.overlay(edits);
    return c;
  }

  bool get hasUserChoices =>
      !colors.isEmpty || !globals.isEmpty || !edits.isDefault;

  /// Changes the base style. With [keepEdits] the edits stay on top.
  void setBase(ThemePreset preset, {bool keepEdits = false}) {
    _base = preset;
    if (!keepEdits) {
      edits.reset();
      globals.reset();
      colors.reset();
    }
    invalidate();
  }

  /// Call after every change to [edits].
  void invalidate() {
    _presetConfig = null;
    _baseConfig = null;
    _resolved = null;
  }
}

T? _pick<T>(T? over, T? under) => over ?? under;

extension ThemeConfigOverlay on ThemeConfig {
  /// Applies the values set in [o] on top of this configuration.
  void overlay(ThemeConfig o) {
    seed = _pick(o.seed, seed);
    schemeVariant = _pick(o.schemeVariant, schemeVariant);
    fontFamily = _pick(o.fontFamily, fontFamily);
    headFontFamily = _pick(o.headFontFamily, headFontFamily);
    schemeOverrides.addAll(o.schemeOverrides);
    density = _pick(o.density, density);
    shrinkWrap = _pick(o.shrinkWrap, shrinkWrap);
    for (final k in ButtonKind.values) {
      buttons[k]!.overlay(o.buttons[k]!);
    }
    textField.overlay(o.textField);
    for (final k in ButtonSizeKey.values) {
      buttonSizes[k]!.overlay(o.buttonSizes[k]!);
    }
    for (final r in TextRole.values) {
      typography.styles[r]!.overlay(o.typography.styles[r]!);
    }
    for (final k in SurfaceKind.values) {
      surfaces[k]!.overlay(o.surfaces[k]!);
    }
  }
}

extension StateStyleOverlay on StateStyle {
  void overlay(StateStyle o) {
    fill = _pick(o.fill, fill);
    fillEnd = _pick(o.fillEnd, fillEnd);
    foreground = _pick(o.foreground, foreground);
    border = _pick(o.border, border);
    shadow = _pick(o.shadow, shadow);
    shadowColor = _pick(o.shadowColor, shadowColor);
    offsetX = _pick(o.offsetX, offsetX);
    offsetY = _pick(o.offsetY, offsetY);
  }
}

extension ButtonConfigOverlay on ButtonConfig {
  void overlay(ButtonConfig o) {
    for (final k in ButtonStateKey.values) {
      states[k]!.overlay(o.states[k]!);
    }
    borderWidth = _pick(o.borderWidth, borderWidth);
    radius = _pick(o.radius, radius);
    paddingH = _pick(o.paddingH, paddingH);
    paddingV = _pick(o.paddingV, paddingV);
    minHeight = _pick(o.minHeight, minHeight);
    minWidth = _pick(o.minWidth, minWidth);
    iconSize = _pick(o.iconSize, iconSize);
    fontSize = _pick(o.fontSize, fontSize);
    fontWeight = _pick(o.fontWeight, fontWeight);
    letterSpacing = _pick(o.letterSpacing, letterSpacing);
    lineHeight = _pick(o.lineHeight, lineHeight);
    hoverUnderline = _pick(o.hoverUnderline, hoverUnderline);
    headFont = _pick(o.headFont, headFont);
    pressScale = _pick(o.pressScale, pressScale);
    focusRing = _pick(o.focusRing, focusRing);
    focusRingWidth = _pick(o.focusRingWidth, focusRingWidth);
    focusRingOffset = _pick(o.focusRingOffset, focusRingOffset);
    focusRingOffsetColor = _pick(o.focusRingOffsetColor, focusRingOffsetColor);
    transitionMs = _pick(o.transitionMs, transitionMs);
  }
}

extension ButtonSizeSpecOverlay on ButtonSizeSpec {
  void overlay(ButtonSizeSpec o) {
    radius = _pick(o.radius, radius);
    paddingH = _pick(o.paddingH, paddingH);
    paddingV = _pick(o.paddingV, paddingV);
    minHeight = _pick(o.minHeight, minHeight);
    iconSize = _pick(o.iconSize, iconSize);
    fontSize = _pick(o.fontSize, fontSize);
    fontWeight = _pick(o.fontWeight, fontWeight);
    letterSpacing = _pick(o.letterSpacing, letterSpacing);
    lineHeight = _pick(o.lineHeight, lineHeight);
  }
}

extension FieldStateStyleOverlay on FieldStateStyle {
  void overlay(FieldStateStyle o) {
    fill = _pick(o.fill, fill);
    border = _pick(o.border, border);
    borderWidth = _pick(o.borderWidth, borderWidth);
    placeholder = _pick(o.placeholder, placeholder);
    icon = _pick(o.icon, icon);
    shadow = _pick(o.shadow, shadow);
    shadowColor = _pick(o.shadowColor, shadowColor);
  }
}

extension TextFieldConfigOverlay on TextFieldConfig {
  void overlay(TextFieldConfig o) {
    for (final k in FieldStateKey.values) {
      states[k]!.overlay(o.states[k]!);
    }
    radius = _pick(o.radius, radius);
    dense = _pick(o.dense, dense);
    underline = _pick(o.underline, underline);
    textInset = _pick(o.textInset, textInset);
    paddingEnd = _pick(o.paddingEnd, paddingEnd);
    paddingV = _pick(o.paddingV, paddingV);
    iconBox = _pick(o.iconBox, iconBox);
    inputFontSize = _pick(o.inputFontSize, inputFontSize);
    inputWeight = _pick(o.inputWeight, inputWeight);
    inputLineHeight = _pick(o.inputLineHeight, inputLineHeight);
    inputLetterSpacing = _pick(o.inputLetterSpacing, inputLetterSpacing);
    inputColor = _pick(o.inputColor, inputColor);
    cursor = _pick(o.cursor, cursor);
    helperFontSize = _pick(o.helperFontSize, helperFontSize);
    helperWeight = _pick(o.helperWeight, helperWeight);
    helperLetterSpacing = _pick(o.helperLetterSpacing, helperLetterSpacing);
    helperColor = _pick(o.helperColor, helperColor);
    errorColor = _pick(o.errorColor, errorColor);
  }
}

extension TypeSpecOverlay on TypeSpec {
  void overlay(TypeSpec o) {
    if (o.isEmpty) return;
    size = _pick(o.size, size);
    lineHeight = _pick(o.lineHeight, lineHeight);
    weight = _pick(o.weight, weight);
    letterSpacing = _pick(o.letterSpacing, letterSpacing);
    headFont = _pick(o.headFont, headFont);
    // The style is no longer the original design system's.
    source = o.source;
  }
}

extension SurfaceConfigOverlay on SurfaceConfig {
  void overlay(SurfaceConfig o) {
    background = _pick(o.background, background);
    foreground = _pick(o.foreground, foreground);
    borderColor = _pick(o.borderColor, borderColor);
    borderWidth = _pick(o.borderWidth, borderWidth);
    radius = _pick(o.radius, radius);
    elevation = _pick(o.elevation, elevation);
    accent = _pick(o.accent, accent);
    titleStyle = _pick(o.titleStyle, titleStyle);
    bodyStyle = _pick(o.bodyStyle, bodyStyle);
    height = _pick(o.height, height);
    shadow = _pick(o.shadow, shadow);
    paddingH = _pick(o.paddingH, paddingH);
    paddingV = _pick(o.paddingV, paddingV);
    innerRadius = _pick(o.innerRadius, innerRadius);
    selectedForeground = _pick(o.selectedForeground, selectedForeground);
    accentEnd = _pick(o.accentEnd, accentEnd);
    shadowColor = _pick(o.shadowColor, shadowColor);
    width = _pick(o.width, width);
    thumbSize = _pick(o.thumbSize, thumbSize);
    trackBorderWidth = _pick(o.trackBorderWidth, trackBorderWidth);
  }
}
