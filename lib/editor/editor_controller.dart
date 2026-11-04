import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../model/color_choice.dart';
import '../model/global_tokens.dart';
import '../model/presets.dart';
import '../model/surface_config.dart';
import '../model/theme_config.dart';
import '../model/theme_json.dart';
import '../model/theme_layers.dart';
import 'storage/storage.dart';

/// Section selected in the sidebar.
sealed class EditorSection {
  const EditorSection();
}

/// Colors, fonts and density.
class GlobalSection extends EditorSection {
  const GlobalSection();

  @override
  bool operator ==(Object other) => other is GlobalSection;

  @override
  int get hashCode => 0;
}

/// Global properties (shape, depth, typography, sizing, motion).
class GeneralSection extends EditorSection {
  const GeneralSection();

  @override
  bool operator ==(Object other) => other is GeneralSection;

  @override
  int get hashCode => 5;
}

/// Base style (Material 3, BoardUI, Neobrutalism).
class StyleSection extends EditorSection {
  const StyleSection();

  @override
  bool operator ==(Object other) => other is StyleSection;

  @override
  int get hashCode => 6;
}

class ButtonSection extends EditorSection {
  const ButtonSection(this.kind);

  final ButtonKind kind;

  @override
  bool operator ==(Object other) =>
      other is ButtonSection && other.kind == kind;

  @override
  int get hashCode => kind.hashCode;
}

class TextFieldSection extends EditorSection {
  const TextFieldSection();

  @override
  bool operator ==(Object other) => other is TextFieldSection;

  @override
  int get hashCode => 1;
}

class ButtonSizesSection extends EditorSection {
  const ButtonSizesSection();

  @override
  bool operator ==(Object other) => other is ButtonSizesSection;

  @override
  int get hashCode => 4;
}

class TypographySection extends EditorSection {
  const TypographySection();

  @override
  bool operator ==(Object other) => other is TypographySection;

  @override
  int get hashCode => 2;
}

class SurfaceSection extends EditorSection {
  const SurfaceSection(this.kind);

  final SurfaceKind kind;

  @override
  bool operator ==(Object other) =>
      other is SurfaceSection && other.kind == kind;

  @override
  int get hashCode => Object.hash(3, kind);
}

class EditorController extends ChangeNotifier {
  /// Preset (base layer) + user edits.
  LayeredTheme theme = LayeredTheme();

  /// Theme name (project file).
  String themeName = 'My theme';

  /// Autosaves in the browser after every change.
  bool autosave = true;

  Timer? _saveTimer;

  @override
  void notifyListeners() {
    super.notifyListeners();
    if (!autosave) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(
      const Duration(milliseconds: 500),
      () => writeAutosave(toJsonString()),
    );
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  String toJsonString() => const JsonEncoder.withIndent(
    '  ',
  ).convert(layeredThemeToJson(theme, name: themeName));

  /// File name for the download: "My theme" → my-theme.materialcraft.json
  String get fileName {
    final slug = themeName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return '${slug.isEmpty ? 'theme' : slug}.materialcraft.json';
  }

  /// Replaces the theme being edited (wizard, opening a file).
  Future<void> adopt(LayeredTheme next, {String? name}) async {
    final r = next.resolved;
    if (r.fontFamily != null) await preloadFont(r.fontFamily!);
    if (r.headFontFamily != null) await preloadFont(r.headFontFamily!);
    theme = next;
    if (name != null && name.trim().isNotEmpty) themeName = name.trim();
    notifyListeners();
  }

  /// Opens a project file. Throws [FormatException] if it isn't valid.
  Future<void> openJson(String text) async {
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      throw const FormatException('The file is not valid JSON.');
    }
    final loaded = layeredThemeFromJson(json);
    await adopt(loaded.theme, name: loaded.name);
  }

  /// Restores the last autosaved theme. True if there was one.
  Future<bool> restoreAutosave() async {
    final text = readAutosave();
    if (text == null) return false;
    try {
      await openJson(text);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// The user's edits: the panels write here (`null` = inherit).
  ThemeConfig get edits => theme.edits;

  /// Preset + edits: preview, export and the values shown in the panels.
  ThemeConfig get resolved => theme.resolved;

  /// Preset + global properties: a component's "inherited" value.
  ThemeConfig get base => theme.baseConfig;

  /// The preset alone.
  ThemeConfig get presetOnly => theme.presetConfig;

  /// Chosen colors (write here with [update]).
  ColorChoice get colors => theme.colors;

  /// Global properties (write here with [update]).
  GlobalTokens get globals => theme.globals;

  ThemePreset get preset => theme.base;

  /// There are hand-made choices on top of the preset (global or components).
  bool get hasEdits => theme.hasUserChoices;

  /// Where an inherited value comes from: from the global properties if the
  /// globals change it relative to the preset, otherwise from the preset.
  String sourceOf(Object? withGlobals, Object? presetValue) =>
      withGlobals == presetValue ? preset.name : 'Global';

  EditorSection selected = const ButtonSection(ButtonKind.filled);

  void select(EditorSection section) {
    selected = section;
    notifyListeners();
  }

  /// Changes the base style. With [keepEdits] the hand-made edits
  /// stay on top of the new preset.
  Future<void> applyPreset(ThemePreset preset, {bool keepEdits = false}) async {
    final probe = ThemeConfig();
    preset.applyWithColors(probe, keepEdits ? colors : ColorChoice());
    if (keepEdits) {
      applyGlobals(probe, globals);
      probe.overlay(edits);
    }
    if (probe.fontFamily != null) await preloadFont(probe.fontFamily!);
    if (probe.headFontFamily != null) await preloadFont(probe.headFontFamily!);
    theme.setBase(preset, keepEdits: keepEdits);
    notifyListeners();
  }

  Future<void> setFont(String? family) async {
    if (family != null) await preloadFont(family);
    update(() => edits.fontFamily = family);
  }

  Future<void> setHeadFont(String? family) async {
    if (family != null) await preloadFont(family);
    update(() => edits.headFontFamily = family);
  }

  /// Downloads the font (weights 300–800) before using it in the preview.
  ///
  /// If the font arrived while the preview was already painted, text
  /// would be measured with one font and painted with another: in debug
  /// Flutter throws the `debugSize == size` assertion in TextPainter.paint.
  static Future<void> preloadFont(String family) async {
    try {
      for (final w in const [
        FontWeight.w300,
        FontWeight.w400,
        FontWeight.w500,
        FontWeight.w600,
        FontWeight.w700,
        FontWeight.w800,
      ]) {
        GoogleFonts.getFont(family, fontWeight: w);
      }
      await GoogleFonts.pendingFonts();
    } catch (_) {
      // Offline or font not available: the system fallback is used.
    }
  }

  /// Applies a change to [edits] and updates the UI.
  void update(VoidCallback mutate) {
    mutate();
    theme.invalidate();
    notifyListeners();
  }
}
