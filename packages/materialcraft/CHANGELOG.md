## 0.2.0

**Breaking:** built on [`material_ui`](https://pub.dev/packages/material_ui)
instead of `package:flutter/material.dart`. Requires Flutter 3.47 / Dart 3.13
and an app migrated to `material_ui`
(`dart fix --apply --code=migrate_design_widgets`). Apps on Flutter before
3.47, or still on `flutter/material`, stay on 0.1.x, which keeps getting bug
fixes. See "Migrating from 0.1.x" in the README.

- All the libraries import `package:material_ui/material_ui.dart`.
- The public API is unchanged.
- The sources pass `very_good_analysis`, so the Standalone export, which
  bundles them, is clean in apps that use strict lints.

## 0.1.1

- New README with screenshots, a quick start and the list of styles.

## 0.1.0

- First release: `ButtonSkin`, `AppButtonStyles`, `HardShadowBorder`,
  `HardShadowInputBorder`, `AppSwitch`, slider shapes.
