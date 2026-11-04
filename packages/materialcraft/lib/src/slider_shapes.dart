import 'package:flutter/material.dart';

/// Slider thumb: filled circle with a border and CSS-style shadows. It grows
/// slightly while dragged.
class SoftSliderThumbShape extends SliderComponentShape {
  const SoftSliderThumbShape({
    this.radius = 10,
    required this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.shadows = const [],
    this.pressedScale = 1.1,
    this.cornerRadius,
  });

  final double radius;
  final Color color;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow> shadows;

  /// Scale of the thumb while dragged.
  final double pressedScale;

  /// Corner radius: `null` = circle, 0 = square.
  final double? cornerRadius;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size.fromRadius(radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    _paintSoftThumb(
      context.canvas,
      center,
      radius: radius * (1 + (pressedScale - 1) * activationAnimation.value),
      color: color,
      borderColor: borderColor,
      borderWidth: borderWidth,
      shadows: shadows,
      cornerRadius: cornerRadius,
    );
  }
}

/// Like [SoftSliderThumbShape], for the two thumbs of a `RangeSlider`.
class SoftRangeSliderThumbShape extends RangeSliderThumbShape {
  const SoftRangeSliderThumbShape({
    this.radius = 10,
    required this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.shadows = const [],
    this.pressedScale = 1.1,
    this.cornerRadius,
  });

  final double radius;
  final Color color;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow> shadows;
  final double pressedScale;
  final double? cornerRadius;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size.fromRadius(radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    TextDirection? textDirection,
    required SliderThemeData sliderTheme,
    Thumb? thumb,
    bool? isPressed,
  }) {
    final scale = (isPressed ?? false)
        ? pressedScale
        : 1 + (pressedScale - 1) * activationAnimation.value;
    _paintSoftThumb(
      context.canvas,
      center,
      radius: radius * scale,
      color: color,
      borderColor: borderColor,
      borderWidth: borderWidth,
      shadows: shadows,
      cornerRadius: cornerRadius,
    );
  }
}

void _paintSoftThumb(
  Canvas canvas,
  Offset center, {
  required double radius,
  required Color color,
  Color? borderColor,
  double borderWidth = 1,
  List<BoxShadow> shadows = const [],
  double? cornerRadius,
}) {
  RRect shape(double inflate, Offset shift) => RRect.fromRectAndRadius(
    Rect.fromCircle(center: center + shift, radius: radius + inflate),
    Radius.circular(cornerRadius ?? radius + inflate),
  );
  for (final s in shadows) {
    canvas.drawRRect(shape(s.spreadRadius, s.offset), s.toPaint());
  }
  canvas.drawRRect(shape(0, Offset.zero), Paint()..color = color);
  if (borderColor != null && borderWidth > 0) {
    canvas.drawRRect(
      shape(-borderWidth / 2, Offset.zero),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
  }
}

/// Slider track whose active part is a horizontal gradient.
class GradientSliderTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  const GradientSliderTrackShape({
    required this.activeColors,
    this.borderColor,
    this.borderWidth = 0,
    this.cornerRadius,
  });

  /// Gradient colors of the active part (left to right).
  final List<Color> activeColors;

  /// Border around the whole track (0 = none).
  final Color? borderColor;
  final double borderWidth;

  /// Corner radius: `null` = pill.
  final double? cornerRadius;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final radius = Radius.circular(cornerRadius ?? rect.height / 2);
    final canvas = context.canvas;
    final enabled = enableAnimation.value > 0.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()
        ..color =
            (enabled
                ? sliderTheme.inactiveTrackColor
                : sliderTheme.disabledInactiveTrackColor) ??
            Colors.grey,
    );

    final ltr = textDirection == TextDirection.ltr;
    final active = Rect.fromLTRB(
      ltr ? rect.left : thumbCenter.dx,
      rect.top,
      ltr ? thumbCenter.dx : rect.right,
      rect.bottom,
    );
    if (active.width <= 0) return;
    final paint = Paint();
    if (enabled && activeColors.length > 1) {
      paint.shader = LinearGradient(
        colors: ltr ? activeColors : activeColors.reversed.toList(),
      ).createShader(active);
    } else {
      paint.color = enabled
          ? (activeColors.isEmpty
                ? sliderTheme.activeTrackColor ?? Colors.blue
                : activeColors.first)
          : sliderTheme.disabledActiveTrackColor ?? Colors.grey;
    }
    canvas.drawRRect(RRect.fromRectAndRadius(active, radius), paint);
    final border = borderColor;
    if (border != null && borderWidth > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius).deflate(borderWidth / 2),
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth,
      );
    }
  }
}

/// Like [GradientSliderTrackShape], for a `RangeSlider`: the active part goes
/// from the first to the second thumb.
class GradientRangeSliderTrackShape extends RangeSliderTrackShape
    with BaseRangeSliderTrackShape {
  const GradientRangeSliderTrackShape({
    required this.activeColors,
    this.borderColor,
    this.borderWidth = 0,
    this.cornerRadius,
  });

  final List<Color> activeColors;
  final Color? borderColor;
  final double borderWidth;
  final double? cornerRadius;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset startThumbCenter,
    required Offset endThumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final radius = Radius.circular(cornerRadius ?? rect.height / 2);
    final canvas = context.canvas;
    final enabled = enableAnimation.value > 0.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()
        ..color =
            (enabled
                ? sliderTheme.inactiveTrackColor
                : sliderTheme.disabledInactiveTrackColor) ??
            Colors.grey,
    );

    final left = startThumbCenter.dx < endThumbCenter.dx
        ? startThumbCenter.dx
        : endThumbCenter.dx;
    final right = startThumbCenter.dx < endThumbCenter.dx
        ? endThumbCenter.dx
        : startThumbCenter.dx;
    final active = Rect.fromLTRB(left, rect.top, right, rect.bottom);
    if (active.width > 0) {
      final ltr = textDirection == TextDirection.ltr;
      final paint = Paint();
      if (enabled && activeColors.length > 1) {
        paint.shader = LinearGradient(
          colors: ltr ? activeColors : activeColors.reversed.toList(),
        ).createShader(active);
      } else {
        paint.color = enabled
            ? (activeColors.isEmpty
                  ? sliderTheme.activeTrackColor ?? Colors.blue
                  : activeColors.first)
            : sliderTheme.disabledActiveTrackColor ?? Colors.grey;
      }
      // Between the two thumbs the corners stay sharp, as in CSS.
      canvas.drawRect(active, paint);
    }
    final border = borderColor;
    if (border != null && borderWidth > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius).deflate(borderWidth / 2),
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth,
      );
    }
  }
}
