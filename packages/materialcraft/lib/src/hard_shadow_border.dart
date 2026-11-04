import 'package:flutter/material.dart';

/// Rounded rectangle with a border and a shadow: either "hard" (offset, no
/// blur, like the neobrutalism `box-shadow: 4px 4px 0 0`) or soft, CSS style
/// ([shadows], e.g. Tailwind's `shadow-sm`).
///
/// Use it as `shape:` in themes (card, dialog, menu, chip, FAB…): the shadow
/// is painted only outside the container, so it never covers the content.
class HardShadowBorder extends OutlinedBorder {
  const HardShadowBorder({
    super.side,
    this.radius = 0,
    this.shadowOffset = Offset.zero,
    this.shadowColor = const Color(0xFF000000),
    this.shadowSpread = 0,
    this.shadows = const [],
  });

  final double radius;
  final Offset shadowOffset;
  final Color shadowColor;
  final double shadowSpread;

  /// Soft (CSS) shadows, painted only outside the container.
  final List<BoxShadow> shadows;

  RoundedRectangleBorder get _shape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radius),
    side: side,
  );

  @override
  EdgeInsetsGeometry get dimensions => _shape.dimensions;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _shape.getInnerPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _shape.getOuterPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    paintSoftShadows(canvas, rect, radius, shadows);
    if (shadowOffset != Offset.zero || shadowSpread != 0) {
      paintHardShadow(
        canvas,
        rect,
        radius,
        shadowOffset,
        shadowSpread,
        shadowColor,
      );
    }
    _shape.paint(canvas, rect, textDirection: textDirection);
  }

  @override
  HardShadowBorder copyWith({
    BorderSide? side,
    double? radius,
    Offset? shadowOffset,
    Color? shadowColor,
    List<BoxShadow>? shadows,
  }) => HardShadowBorder(
    side: side ?? this.side,
    radius: radius ?? this.radius,
    shadowOffset: shadowOffset ?? this.shadowOffset,
    shadowColor: shadowColor ?? this.shadowColor,
    shadowSpread: shadowSpread,
    shadows: shadows ?? this.shadows,
  );

  @override
  ShapeBorder scale(double t) => HardShadowBorder(
    side: side.scale(t),
    radius: radius * t,
    shadowOffset: shadowOffset * t,
    shadowColor: shadowColor,
    shadowSpread: shadowSpread * t,
    shadows: [for (final s in shadows) s.scale(t)],
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is HardShadowBorder) return _lerp(a, this, t);
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is HardShadowBorder) return _lerp(this, b, t);
    return super.lerpTo(b, t);
  }

  static HardShadowBorder _lerp(
    HardShadowBorder a,
    HardShadowBorder b,
    double t,
  ) => HardShadowBorder(
    side: BorderSide.lerp(a.side, b.side, t),
    radius: _mix(a.radius, b.radius, t),
    shadowOffset: Offset.lerp(a.shadowOffset, b.shadowOffset, t)!,
    shadowColor: Color.lerp(a.shadowColor, b.shadowColor, t)!,
    shadowSpread: _mix(a.shadowSpread, b.shadowSpread, t),
    shadows: BoxShadow.lerpList(a.shadows, b.shadows, t) ?? const [],
  );

  @override
  bool operator ==(Object other) =>
      other is HardShadowBorder &&
      other.side == side &&
      other.radius == radius &&
      other.shadowOffset == shadowOffset &&
      other.shadowColor == shadowColor &&
      other.shadowSpread == shadowSpread &&
      _sameShadows(other.shadows, shadows);

  @override
  int get hashCode => Object.hash(
    side,
    radius,
    shadowOffset,
    shadowColor,
    shadowSpread,
    Object.hashAll(shadows),
  );
}

bool _sameShadows(List<BoxShadow> a, List<BoxShadow> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Paints (blurred) CSS shadows only outside the rounded rectangle.
void paintSoftShadows(
  Canvas canvas,
  Rect rect,
  double radius,
  List<BoxShadow> shadows,
) {
  if (shadows.isEmpty) return;
  final shape = RRect.fromRectAndRadius(rect, Radius.circular(radius));
  canvas.save();
  canvas.clipPath(
    Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(1000))
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

double _mix(double a, double b, double t) => a + (b - a) * t;

/// Paints the hard shadow of [rect] only where it sticks out.
void paintHardShadow(
  Canvas canvas,
  Rect rect,
  double radius,
  Offset offset,
  double spread,
  Color color,
) {
  final inner = RRect.fromRectAndRadius(rect, Radius.circular(radius));
  final outer = RRect.fromRectAndRadius(
    rect.inflate(spread).shift(offset),
    Radius.circular(radius + spread),
  );
  // Clip to the outside of the shape, then paint: on the web (CanvasKit)
  // Path.combine(difference) gets concentric rectangles wrong (focus ring)
  // and fills the inside too.
  canvas.save();
  canvas.clipPath(
    Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(outer.outerRect.inflate(1))
      ..addRRect(inner),
  );
  canvas.drawRRect(outer, Paint()..color = color);
  canvas.restore();
}

/// Text field border with a hard shadow (per state, via
/// `WidgetStateInputBorder.resolveWith`).
class HardShadowInputBorder extends OutlineInputBorder {
  const HardShadowInputBorder({
    super.borderSide,
    super.borderRadius = BorderRadius.zero,
    super.gapPadding,
    this.shadowOffset = Offset.zero,
    this.shadowColor = const Color(0xFF000000),
    this.shadowSpread = 0,
    this.shadows = const [],
  });

  final Offset shadowOffset;
  final Color shadowColor;

  /// Shadow spread: with a zero offset it becomes a ring (focus ring).
  final double shadowSpread;

  /// Soft (CSS) shadows, e.g. `shadow-xs`, only outside the field.
  final List<BoxShadow> shadows;

  @override
  HardShadowInputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
    Offset? shadowOffset,
    Color? shadowColor,
    double? shadowSpread,
    List<BoxShadow>? shadows,
  }) => HardShadowInputBorder(
    borderSide: borderSide ?? this.borderSide,
    borderRadius: borderRadius ?? this.borderRadius,
    gapPadding: gapPadding ?? this.gapPadding,
    shadowOffset: shadowOffset ?? this.shadowOffset,
    shadowColor: shadowColor ?? this.shadowColor,
    shadowSpread: shadowSpread ?? this.shadowSpread,
    shadows: shadows ?? this.shadows,
  );

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    paintSoftShadows(canvas, rect, borderRadius.topLeft.x, shadows);
    if (shadowOffset != Offset.zero || shadowSpread != 0) {
      paintHardShadow(
        canvas,
        rect,
        borderRadius.topLeft.x,
        shadowOffset,
        shadowSpread,
        shadowColor,
      );
    }
    super.paint(
      canvas,
      rect,
      gapStart: gapStart,
      gapExtent: gapExtent,
      gapPercentage: gapPercentage,
      textDirection: textDirection,
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is OutlineInputBorder) {
      final from = a is HardShadowInputBorder ? a.shadowOffset : Offset.zero;
      final fromSpread = a is HardShadowInputBorder ? a.shadowSpread : 0.0;
      final fromColor = a is HardShadowInputBorder
          ? a.shadowColor
          : shadowColor.withValues(alpha: 0);
      return HardShadowInputBorder(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        borderRadius: BorderRadius.lerp(a.borderRadius, borderRadius, t)!,
        gapPadding: _mix(a.gapPadding, gapPadding, t),
        shadowOffset: Offset.lerp(from, shadowOffset, t)!,
        shadowColor: Color.lerp(fromColor, shadowColor, t)!,
        shadowSpread: _mix(fromSpread, shadowSpread, t),
        shadows:
            BoxShadow.lerpList(
              a is HardShadowInputBorder ? a.shadows : const [],
              shadows,
              t,
            ) ??
            const [],
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is OutlineInputBorder && b is! HardShadowInputBorder) {
      return HardShadowInputBorder(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        borderRadius: BorderRadius.lerp(borderRadius, b.borderRadius, t)!,
        gapPadding: _mix(gapPadding, b.gapPadding, t),
        shadowOffset: Offset.lerp(shadowOffset, Offset.zero, t)!,
        shadowColor: Color.lerp(
          shadowColor,
          shadowColor.withValues(alpha: 0),
          t,
        )!,
        shadowSpread: _mix(shadowSpread, 0, t),
        shadows: BoxShadow.lerpList(shadows, const [], t) ?? const [],
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  bool operator ==(Object other) =>
      other is HardShadowInputBorder &&
      super == other &&
      other.shadowOffset == shadowOffset &&
      other.shadowColor == shadowColor &&
      other.shadowSpread == shadowSpread &&
      _sameShadows(other.shadows, shadows);

  @override
  int get hashCode => Object.hash(
    super.hashCode,
    shadowOffset,
    shadowColor,
    shadowSpread,
    Object.hashAll(shadows),
  );
}
