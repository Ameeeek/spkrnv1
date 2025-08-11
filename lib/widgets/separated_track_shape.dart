import 'package:flutter/material.dart';

class SeparatedTrackShape extends SliderTrackShape {
  final double gapWidth;

  const SeparatedTrackShape({this.gapWidth = 4});

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 4.0;
    final trackLeft = offset.dx + sliderTheme.overlayShape!
            .getPreferredSize(isEnabled, isDiscrete)
            .width /
        2;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width -
        sliderTheme.overlayShape!.getPreferredSize(isEnabled, isDiscrete).width;

    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    Offset? secondaryOffset,
  }) {
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Paint activePaint = Paint()
      ..color = sliderTheme.activeTrackColor ?? Colors.blue;
    final Paint inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? Colors.grey;

    final double gap = gapWidth / 1.5;

    // LEFT SIDE (active track)
    final Rect leftRect = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      thumbCenter.dx - gap,
      trackRect.bottom,
    );

    final RRect leftRounded = RRect.fromRectAndCorners(
      leftRect,
      topLeft: Radius.circular(trackRect.height / 2),
      bottomLeft: Radius.circular(trackRect.height / 2),
    );

    context.canvas.drawRRect(leftRounded, activePaint);

    // RIGHT SIDE (inactive track)
    final Rect rightRect = Rect.fromLTRB(
      thumbCenter.dx + gap,
      trackRect.top,
      trackRect.right,
      trackRect.bottom,
    );

    final RRect rightRounded = RRect.fromRectAndCorners(
      rightRect,
      topRight: Radius.circular(trackRect.height / 2),
      bottomRight: Radius.circular(trackRect.height / 2),
    );

    context.canvas.drawRRect(rightRounded, inactivePaint);
  }
}