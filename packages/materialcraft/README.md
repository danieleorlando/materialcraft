# materialcraft

Runtime widgets and theme helpers for Flutter themes generated with
[**MaterialCraft**](https://github.com/danieleorlando/materialcraft), a visual
theme editor for Material 3
([try it online](https://materialcraft.danieleorlando.me)).

MaterialCraft exports a plain `app_theme.dart`. In *standalone* mode the file
bundles everything it needs. In *package* mode it imports this package
instead, so the exported file stays short and you get fixes with
`flutter pub upgrade` without exporting the theme again.

Everything here sits **on top of Material**: theme extensions, borders and
shapes that plug into the standard Material themes, plus a few explicit
helpers. Nothing replaces or shadows a Material widget.

## What's inside

| API | What it does |
| --- | --- |
| `ButtonSkin` / `ButtonSkinState` | Per-state gradients, CSS-like inner and outer shadows, focus ring and press effect for Material buttons. |
| `AppButtonStyles` + `context.buttonStyle(...)` | Extra button variants (danger, ghost, …) and sizes (large, small, xs) as a `ThemeExtension`. |
| `HardShadowBorder` / `HardShadowInputBorder` | Borders with a hard, offset shadow (neobrutalism) for cards, dialogs, menus and text fields. |
| `AppSwitch` / `AppSwitchStyle` | A switch with the theme's geometry (square thumb, borders). Without an `AppSwitchStyle` it renders the regular Material `Switch`. |
| `SoftSliderThumbShape`, `GradientSliderTrackShape` (+ range variants) | Slider thumb with border and shadow, gradient track. |

## Usage

```yaml
dependencies:
  materialcraft: ^0.1.0
```

```dart
import 'app_theme.dart'; // exported by MaterialCraft

MaterialApp(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  home: ...,
);
```

Extra button styles and sizes:

```dart
FilledButton(
  style: context.buttonStyle(AppButtonKind.danger),
  onPressed: () {},
  child: const Text('Delete'),
);

OutlinedButton(
  style: context.buttonStyle(AppButtonKind.outlined, size: AppButtonSize.small),
  onPressed: () {},
  child: const Text('Small'),
);
```

A switch that follows the theme:

```dart
AppSwitch(value: on, onChanged: (v) => setState(() => on = v));
```

## Author

Built by **Daniele Orlando** ([@danieleorlando](https://github.com/danieleorlando)).
