import 'dart:math' as math;

import 'package:flutter/material.dart';

class TimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final double knobRadius;

  TimerPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    this.strokeWidth = 20.0,
    this.knobRadius = 15.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress;
      const startAngle = -math.pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      final knobAngle = startAngle + sweepAngle;
      final knobCenter = Offset(
        center.dx + radius * math.cos(knobAngle),
        center.dy + radius * math.sin(knobAngle),
      );
      canvas.drawCircle(
        knobCenter,
        knobRadius + 4,
        Paint()..color = Colors.black.withValues(alpha: 0.15),
      );
      canvas.drawCircle(knobCenter, knobRadius, Paint()..color = Colors.white);
      canvas.drawCircle(knobCenter, knobRadius - 4, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant TimerPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}
