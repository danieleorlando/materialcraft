import 'package:flutter/material.dart';

/// Buttons that can have an extra style in the theme.
enum AppButtonKind {
  elevated,
  filled,
  outlined,
  text,
  icon,
  danger,
  ghost,
  iconSecondary,
}

/// Button sizes. `medium` is the one defined by the theme.
enum AppButtonSize { medium, large, small, xs }

/// Button styles that Material has no theme for: variants (e.g. danger) and
/// sizes (large, small, xs). Read them with
/// [AppButtonStylesContext.buttonStyle].
@immutable
class AppButtonStyles extends ThemeExtension<AppButtonStyles> {
  const AppButtonStyles([this.styles = const {}]);

  final Map<(AppButtonKind, AppButtonSize), ButtonStyle> styles;

  /// Style for [kind] and [size]; `null` means "use the button's theme"
  /// (the case of medium for buttons that already have a Material theme).
  ButtonStyle? style(
    AppButtonKind kind, [
    AppButtonSize size = AppButtonSize.medium,
  ]) =>
      styles[(kind, size)] ??
      (size == AppButtonSize.medium
          ? null
          : styles[(kind, AppButtonSize.medium)]);

  @override
  AppButtonStyles copyWith({
    Map<(AppButtonKind, AppButtonSize), ButtonStyle>? styles,
  }) => AppButtonStyles(styles ?? this.styles);

  @override
  AppButtonStyles lerp(AppButtonStyles? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

extension AppButtonStylesContext on BuildContext {
  /// E.g. `FilledButton(style: context.buttonStyle(AppButtonKind.danger), ...)`
  /// or `OutlinedButton(style: context.buttonStyle(AppButtonKind.outlined,
  /// size: AppButtonSize.small), ...)`.
  ButtonStyle? buttonStyle(
    AppButtonKind kind, {
    AppButtonSize size = AppButtonSize.medium,
  }) => Theme.of(this).extension<AppButtonStyles>()?.style(kind, size);
}
