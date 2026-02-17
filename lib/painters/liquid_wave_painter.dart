import 'dart:math' as math;

import 'package:flutter/material.dart';

class LiquidWavePainter extends CustomPainter {
  final double waveValue;
  final double fillPercent;
  final Color color;
  final double waveHeight;
  final double waveFrequency;

  LiquidWavePainter({
    required this.waveValue,
    required this.fillPercent,
    required this.color,
    this.waveHeight = 15.0,
    this.waveFrequency = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPercent == 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    final baseHeight = size.height * (1 - fillPercent);
    path.moveTo(0, baseHeight);
    for (double i = 0.0; i <= size.width; i++) {
      path.lineTo(
        i,
        baseHeight +
            math.sin(
                  (i / size.width * 2 * math.pi * waveFrequency) +
                      (waveValue * 2 * math.pi),
                ) *
                waveHeight,
      );
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LiquidWavePainter oldDelegate) =>
      oldDelegate.waveValue != waveValue ||
      oldDelegate.fillPercent != fillPercent ||
      oldDelegate.color != color;
}
