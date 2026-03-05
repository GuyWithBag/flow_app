import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A custom grabber/knob widget that positions itself at the end of a circular progress arc.
///
/// This widget renders a 3-layer knob:
/// 1. Shadow layer (outermost) - subtle shadow effect
/// 2. White ring (middle) - border/highlight
/// 3. Colored core (innermost) - matches the progress color
class TimerGrabber extends StatelessWidget {
  /// Progress value from 0.0 to 1.0
  final double progress;

  /// Core knob color (matches progress arc)
  final Color color;

  /// Circle diameter
  final double size;

  /// Ring thickness (for radius calculation)
  final double strokeWidth;

  /// Knob radius
  final double knobRadius;

  const TimerGrabber({
    super.key,
    required this.progress,
    required this.color,
    required this.size,
    required this.strokeWidth,
    required this.knobRadius,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate the position of the knob based on progress
    final center = Offset(size / 2, size / 2);
    // CircularProgressIndicator draws on the outer edge, so the knob
    // should be positioned on the outer radius minus half stroke width
    final radius = (size / 2);

    // Start angle is at the top (-π/2)
    // Sweep angle is progress around the circle
    final knobAngle = -math.pi / 2 + (2 * math.pi * progress);

    final knobCenter = Offset(
      center.dx + radius * math.cos(knobAngle),
      center.dy + radius * math.sin(knobAngle),
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Layer 1: Shadow
          Positioned(
            left: knobCenter.dx - (knobRadius + 4),
            top: knobCenter.dy - (knobRadius + 4),
            child: Container(
              width: (knobRadius + 4) * 2,
              height: (knobRadius + 4) * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.15),
              ),
            ),
          ),

          // Layer 2: White ring
          Positioned(
            left: knobCenter.dx - knobRadius,
            top: knobCenter.dy - knobRadius,
            child: Container(
              width: knobRadius * 2,
              height: knobRadius * 2,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),

          // Layer 3: Colored core
          Positioned(
            left: knobCenter.dx - (knobRadius - 4),
            top: knobCenter.dy - (knobRadius - 4),
            child: Container(
              width: (knobRadius - 4) * 2,
              height: (knobRadius - 4) * 2,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
