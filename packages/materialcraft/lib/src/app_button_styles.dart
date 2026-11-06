import 'package:material_ui/material_ui.dart';

/// Buttons that can have an extra style in the theme.
enum AppButtonKind {
  /// ElevatedButton.
  elevated,

  /// FilledButton.
  filled,

  /// OutlinedButton.
  outlined,

  /// TextButton.
  text,

  /// IconButton.
  icon,

  /// Destructive action (a FilledButton with the danger style).
  danger,

  /// Button without background or border until hovered.
  ghost,

  /// IconButton with the secondary style.
  iconSecondary,
}

/// Button sizes. `medium` is the one defined by the theme.
enum AppButtonSize {
  /// The size of the button's Material theme.
  medium,

  /// Larger than medium.
  large,

  /// Smaller than medium.
  small,

  /// The smallest size.
  xs,
}

/// Button styles that Material has no theme for: variants (e.g. danger) and
/// sizes (large, small, xs). Read them with
/// [AppButtonStylesContext.buttonStyle].
@immutable
class AppButtonStyles extends ThemeExtension<AppButtonStyles> {
  /// Extra styles, by button kind and size.
  const new([this.styles = const {}]);

  /// The styles, by button kind and size.
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

/// Reads [AppButtonStyles] from the theme.
extension AppButtonStylesContext on BuildContext {
  /// E.g. `FilledButton(style: context.buttonStyle(AppButtonKind.danger), ...)`
  /// or `OutlinedButton(style: context.buttonStyle(AppButtonKind.outlined,
  /// size: AppButtonSize.small), ...)`.
  ButtonStyle? buttonStyle(
    AppButtonKind kind, {
    AppButtonSize size = AppButtonSize.medium,
  }) => Theme.of(this).extension<AppButtonStyles>()?.style(kind, size);
}
