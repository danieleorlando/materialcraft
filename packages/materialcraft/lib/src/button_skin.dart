import 'package:material_ui/material_ui.dart';

/// Look of a button in one state. `null` fields inherit from the normal
/// state.
@immutable
class ButtonSkinState {
  /// Look of one state; unset fields inherit from the normal state.
  const new({
    this.colors,
    this.foreground,
    this.border,
    this.shadows,
    this.offset,
  });

  /// One color = solid fill; two = vertical gradient (top → bottom).
  final List<Color>? colors;

  /// Text and icon color.
  final Color? foreground;

  /// Border color (the width is [ButtonSkin.borderWidth]).
  final Color? border;

  /// CSS-style shadows, painted outside the button.
  final List<BoxShadow>? shadows;

  /// Offset of the button in this state (does not affect layout).
  final Offset? offset;
}

/// Paints the background (gradients included), border, CSS-style shadows,
/// focus ring and press effect of Material buttons through
/// [ButtonStyle.backgroundBuilder].
///
/// Usage: `skin.applyTo(FilledButton.styleFrom(...))`.
@immutable
class ButtonSkin {
  /// A skin; [normal] is the look at rest, the other states override it.
  const new({
    required this.normal,
    this.hovered = const ButtonSkinState(),
    this.pressed = const ButtonSkinState(),
    this.focused = const ButtonSkinState(),
    this.disabled = const ButtonSkinState(),
    this.radius = 20,
    this.borderWidth = 0,
    this.pressScale = 1,
    this.focusRing,
    this.focusRingWidth = 2,
    this.focusRingOffset = 2,
    this.focusRingOffsetColor,
    this.duration = const Duration(milliseconds: 150),
  });

  /// Look at rest.
  final ButtonSkinState normal;

  /// Look under the pointer.
  final ButtonSkinState hovered;

  /// Look while pressed.
  final ButtonSkinState pressed;

  /// Look with the keyboard focus.
  final ButtonSkinState focused;

  /// Look when disabled.
  final ButtonSkinState disabled;

  /// Corner radius.
  final double radius;

  /// Border width (0 = no border).
  final double borderWidth;

  /// Scale of the button while pressed (1 = no effect).
  final double pressScale;

  /// Color of the keyboard focus ring (`null` = no ring).
  final Color? focusRing;

  /// Width of the focus ring.
  final double focusRingWidth;

  /// Gap between the button and the focus ring.
  final double focusRingOffset;

  /// Color of the gap between button and ring (`null` = transparent).
  final Color? focusRingOffsetColor;

  /// Duration of color, border and shadow transitions.
  final Duration duration;

  /// Copy with a different radius (used for the small / xs sizes).
  ButtonSkin copyWith({double? radius}) => ButtonSkin(
    normal: normal,
    hovered: hovered,
    pressed: pressed,
    focused: focused,
    disabled: disabled,
    radius: radius ?? this.radius,
    borderWidth: borderWidth,
    pressScale: pressScale,
    focusRing: focusRing,
    focusRingWidth: focusRingWidth,
    focusRingOffset: focusRingOffset,
    focusRingOffsetColor: focusRingOffsetColor,
    duration: duration,
  );

  /// Margin within which shadows and the focus ring can extend past the
  /// button without being clipped by the Material.
  static const double bleed = 24;

  static const Curve _pressCurve = Cubic(0.4, 0, 0.2, 1);
  static const Duration _pressIn = Duration(milliseconds: 220);
  static const Duration _pressOut = Duration(milliseconds: 420);

  /// Effective style for a set of states: disabled > pressed > hovered >
  /// focused > normal.
  ButtonSkinState resolve(Set<WidgetState> states) {
    final layers = <ButtonSkinState>[
      if (states.contains(WidgetState.disabled))
        disabled
      else ...[
        if (states.contains(WidgetState.pressed)) pressed,
        if (states.contains(WidgetState.hovered)) hovered,
        if (states.contains(WidgetState.focused)) focused,
      ],
      normal,
    ];
    T? pick<T>(T? Function(ButtonSkinState s) field) {
      for (final layer in layers) {
        final value = field(layer);
        if (value != null) return value;
      }
      return null;
    }

    return ButtonSkinState(
      colors: pick((s) => s.colors),
      foreground: pick((s) => s.foreground),
      border: pick((s) => s.border),
      shadows: pick((s) => s.shadows),
      offset: pick((s) => s.offset),
    );
  }

  /// Opacity of the Material 3 state layer for states without an explicit
  /// background.
  double _overlayOpacity(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) return 0;
    if (states.contains(WidgetState.pressed)) {
      return pressed.colors == null ? 0.10 : 0;
    }
    if (states.contains(WidgetState.hovered)) {
      return hovered.colors == null ? 0.08 : 0;
    }
    if (states.contains(WidgetState.focused)) {
      return focused.colors == null && focusRing == null ? 0.10 : 0;
    }
    return 0;
  }

  /// Returns [base] painted by this skin (background, border, shadows,
  /// focus ring and press effect); the other properties of [base] stay.
  ButtonStyle applyTo(ButtonStyle base) {
    final foreground = WidgetStateProperty.resolveWith(
      (states) => resolve(states).foreground,
    );
    return base.copyWith(
      backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(0),
      side: const WidgetStatePropertyAll(BorderSide.none),
      shape: WidgetStatePropertyAll(_BleedShape(radius)),
      foregroundColor: foreground,
      iconColor: foreground,
      animationDuration: duration,
      backgroundBuilder: _build,
    );
  }

  Widget _build(BuildContext context, Set<WidgetState> states, Widget? child) {
    final s = resolve(states);
    final enabled = !states.contains(WidgetState.disabled);
    final isPressed = enabled && states.contains(WidgetState.pressed);

    final colors = s.colors ?? const <Color>[];
    var stops = switch (colors.length) {
      0 => const [Colors.transparent, Colors.transparent],
      1 => [colors[0], colors[0]],
      _ => colors,
    };
    final overlay = _overlayOpacity(states);
    final fg = s.foreground;
    if (overlay > 0 && fg != null) {
      final layer = fg.withValues(alpha: fg.a * overlay);
      stops = [for (final c in stops) Color.alphaBlend(layer, c)];
    }

    final decoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: stops,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: borderWidth > 0
          ? Border.all(
              color: s.border ?? Colors.transparent,
              width: borderWidth,
            )
          : null,
      boxShadow: s.shadows,
    );

    // As in CSS (border-box), the border widens the button but not its height.
    Widget result = TweenAnimationBuilder<Decoration>(
      tween: DecorationTween(end: decoration),
      duration: isPressed ? Duration.zero : duration,
      curve: Curves.ease,
      builder: (context, value, child) {
        // Like CSS box-shadow, the shadow is visible only outside the shape:
        // with a transparent background (outline) it must not show through.
        final box = value as BoxDecoration;
        final shadows = box.boxShadow;
        final decorated = DecoratedBox(
          decoration: shadows == null ? box : box.copyWith(boxShadow: []),
          child: child,
        );
        if (shadows == null || shadows.isEmpty) return decorated;
        return CustomPaint(
          painter: _OuterShadowPainter(shadows, radius),
          child: decorated,
        );
      },
      child: borderWidth > 0
          ? Padding(
              padding: EdgeInsets.symmetric(horizontal: borderWidth),
              child: child,
            )
          : child,
    );

    final ring = focusRing;
    if (ring != null) {
      final showRing = enabled && states.contains(WidgetState.focused);
      final o = focusRingOffset;
      final w = focusRingWidth;
      final offsetColor = focusRingOffsetColor;
      result = Stack(
        clipBehavior: Clip.none,
        fit: StackFit.passthrough,
        children: [
          result,
          if (showRing && o > 0 && offsetColor != null)
            _ring(inset: -o, width: o, color: offsetColor, radius: radius + o),
          if (showRing)
            _ring(
              inset: -(o + w),
              width: w,
              color: ring,
              radius: radius + o + w,
            ),
        ],
      );
    }

    // The widget depends on the skin, not on the state: this way the tree
    // does not change on the first hover and the offset animates.
    final hasOffsets = [
      normal,
      hovered,
      pressed,
      focused,
      disabled,
    ].any((state) => state.offset != null);
    if (hasOffsets) {
      final offset = s.offset ?? Offset.zero;
      result = TweenAnimationBuilder<Offset>(
        tween: Tween(end: offset),
        duration: duration,
        curve: Curves.ease,
        builder: (context, value, child) =>
            Transform.translate(offset: value, child: child),
        child: result,
      );
    }

    if (pressScale != 1) {
      result = AnimatedScale(
        scale: isPressed ? pressScale : 1,
        duration: isPressed ? _pressIn : _pressOut,
        curve: _pressCurve,
        child: result,
      );
    }
    return result;
  }

  static Widget _ring({
    required double inset,
    required double width,
    required Color color,
    required double radius,
  }) {
    return Positioned(
      left: inset,
      top: inset,
      right: inset,
      bottom: inset,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: color, width: width),
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }
}

/// Paints the shadows only outside the button's rounded rectangle.
class _OuterShadowPainter extends CustomPainter {
  const new(this.shadows, this.radius);

  final List<BoxShadow> shadows;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas
      ..save()
      ..clipPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(shape.outerRect.inflate(1000))
          ..addRRect(shape),
      );
    for (final s in shadows) {
      canvas.drawRRect(
        shape.shift(s.offset).inflate(s.spreadRadius),
        s.toPaint(),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OuterShadowPainter old) =>
      old.radius != radius || old.shadows != shadows;
}

/// Shape of the button's Material: paints nothing ([ButtonSkin] does) and has
/// a clip area enlarged by [ButtonSkin.bleed], so shadows and the focus ring
/// are not clipped.
class _BleedShape extends OutlinedBorder {
  const new(this.radius);

  final double radius;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(
        RRect.fromRectAndRadius(
          rect.inflate(ButtonSkin.bleed),
          Radius.circular(radius + ButtonSkin.bleed),
        ),
      );

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => _BleedShape(radius * t);

  @override
  _BleedShape copyWith({BorderSide? side}) => this;

  @override
  bool operator ==(Object other) =>
      other is _BleedShape && other.radius == radius;

  @override
  int get hashCode => radius.hashCode;
}
