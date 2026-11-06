import 'package:material_ui/material_ui.dart';

/// Geometry of the switch painted by [AppSwitch]. Colors come from
/// `SwitchThemeData` (track, thumb, outline), just like for `Switch`.
@immutable
class AppSwitchStyle extends ThemeExtension<AppSwitchStyle> {
  /// Switch geometry; the defaults are Material 3's.
  const new({
    this.width = 52,
    this.height = 32,
    this.thumbSize = 24,
    this.trackRadius,
    this.thumbRadius,
    this.thumbBorder = false,
    this.thumbShadows = const [],
    this.duration = const Duration(milliseconds: 150),
  });

  /// Outer size of the track, border included (like CSS border-box).
  final double width;

  /// Outer height of the track, border included.
  final double height;

  /// Side of the thumb.
  final double thumbSize;

  /// Corner radius of the track (`null` = pill).
  final double? trackRadius;

  /// Corner radius of the thumb (`null` = circle).
  final double? thumbRadius;

  /// The thumb has the same outline as the track.
  final bool thumbBorder;

  /// Shadows of the thumb.
  final List<BoxShadow> thumbShadows;

  /// Duration of the thumb movement.
  final Duration duration;

  @override
  AppSwitchStyle copyWith({
    double? width,
    double? height,
    double? thumbSize,
    double? trackRadius,
    double? thumbRadius,
    bool? thumbBorder,
    List<BoxShadow>? thumbShadows,
    Duration? duration,
  }) => AppSwitchStyle(
    width: width ?? this.width,
    height: height ?? this.height,
    thumbSize: thumbSize ?? this.thumbSize,
    trackRadius: trackRadius ?? this.trackRadius,
    thumbRadius: thumbRadius ?? this.thumbRadius,
    thumbBorder: thumbBorder ?? this.thumbBorder,
    thumbShadows: thumbShadows ?? this.thumbShadows,
    duration: duration ?? this.duration,
  );

  @override
  AppSwitchStyle lerp(AppSwitchStyle? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

/// A switch that follows the theme's [AppSwitchStyle]: square thumb, borders
/// and shadows that Material's `Switch` does not support. Without the
/// extension in the theme it renders a regular `Switch`, so it works with any
/// theme.
///
/// ```dart
/// AppSwitch(value: on, onChanged: (v) => setState(() => on = v))
/// ```
class AppSwitch extends StatefulWidget {
  /// A switch; [value] and [onChanged] work like in `Switch`.
  const new({
    required this.value,
    required this.onChanged,
    super.key,
    this.focusNode,
    this.autofocus = false,
  });

  /// Whether the switch is on.
  final bool value;

  /// Called with the new value; `null` disables the switch.
  final ValueChanged<bool>? onChanged;

  /// Focus node, as in `Switch`.
  final FocusNode? focusNode;

  /// Whether to take the focus when first shown.
  final bool autofocus;

  @override
  State<AppSwitch> createState() => _AppSwitchState();
}

class _AppSwitchState extends State<AppSwitch> {
  bool _hovered = false;
  bool _focused = false;

  bool get _enabled => widget.onChanged != null;

  void _toggle() {
    if (_enabled) widget.onChanged!(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.extension<AppSwitchStyle>();
    if (style == null) {
      return Switch(
        value: widget.value,
        onChanged: widget.onChanged,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
      );
    }

    final cs = theme.colorScheme;
    final sw = theme.switchTheme;
    final states = <WidgetState>{
      if (widget.value) WidgetState.selected,
      if (!_enabled) WidgetState.disabled,
      if (_hovered && _enabled) WidgetState.hovered,
      if (_focused && _enabled) WidgetState.focused,
    };
    final on = widget.value;
    final trackColor =
        sw.trackColor?.resolve(states) ??
        (on ? cs.primary : cs.surfaceContainerHighest);
    final thumbColor =
        sw.thumbColor?.resolve(states) ?? (on ? cs.onPrimary : cs.outline);
    final outlineColor =
        sw.trackOutlineColor?.resolve(states) ??
        (on ? Colors.transparent : cs.outline);
    final outlineWidth = sw.trackOutlineWidth?.resolve(states) ?? 2;

    final innerW = style.width - outlineWidth * 2;
    final innerH = style.height - outlineWidth * 2;
    final inset = (innerH - style.thumbSize) / 2;
    final travel = innerW - style.thumbSize - inset * 2;
    final side = BorderSide(color: outlineColor, width: outlineWidth);

    final thumb = Container(
      width: style.thumbSize,
      height: style.thumbSize,
      decoration: BoxDecoration(
        color: thumbColor,
        border: style.thumbBorder && outlineWidth > 0
            ? Border.fromBorderSide(side)
            : null,
        borderRadius: BorderRadius.circular(
          style.thumbRadius ?? style.thumbSize / 2,
        ),
        boxShadow: style.thumbShadows,
      ),
    );

    Widget track = Container(
      width: style.width,
      height: style.height,
      decoration: BoxDecoration(
        color: trackColor,
        border: outlineWidth > 0 ? Border.fromBorderSide(side) : null,
        borderRadius: BorderRadius.circular(
          style.trackRadius ?? style.height / 2,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedPositioned(
            duration: style.duration,
            curve: const Cubic(0.4, 0, 0.2, 1),
            left:
                inset +
                (on == (Directionality.of(context) == TextDirection.ltr)
                    ? travel
                    : 0),
            top: inset,
            child: thumb,
          ),
        ],
      ),
    );

    // Minimum tap target, like Material's Switch.
    if (theme.materialTapTargetSize == MaterialTapTargetSize.padded) {
      track = ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: kMinInteractiveDimension,
          minHeight: kMinInteractiveDimension,
        ),
        child: Center(widthFactor: 1, heightFactor: 1, child: track),
      );
    }

    return Semantics(
      toggled: on,
      enabled: _enabled,
      onTap: _enabled ? _toggle : null,
      child: FocusableActionDetector(
        enabled: _enabled,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _toggle();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _enabled ? _toggle : null,
          onHorizontalDragEnd: _enabled
              ? (d) {
                  final v = d.primaryVelocity ?? 0;
                  final rtl = Directionality.of(context) == TextDirection.rtl;
                  final toOn = rtl ? v < 0 : v > 0;
                  if (v != 0 && toOn != on) _toggle();
                }
              : null,
          child: track,
        ),
      ),
    );
  }
}
