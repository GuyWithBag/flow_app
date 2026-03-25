import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class TimerGrabber extends StatelessWidget {
  final double progress;
  final Color color;
  final double size;
  final double strokeWidth;
  final double knobRadius;
  final double minProgress;
  final double maxProgress;
  final ValueChanged<Offset>? onDragStart;
  final ValueChanged<Offset>? onDragUpdate;
  final VoidCallback? onDragEnd;

  const TimerGrabber({
    super.key,
    required this.progress,
    required this.color,
    required this.size,
    required this.strokeWidth,
    required this.knobRadius,
    this.minProgress = 0.0,
    this.maxProgress = 1.0,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(minProgress, maxProgress);
    final center = Offset(size / 2, size / 2);
    final radius = size / 2;
    final knobAngle = -math.pi / 2 + (2 * math.pi * clampedProgress);

    final knobCenter = Offset(
      center.dx + radius * math.cos(knobAngle),
      center.dy + radius * math.sin(knobAngle),
    );

    // Hit area is larger than the visual knob for easier grabbing
    final hitRadius = knobRadius + 12;

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

          // Layer 4: Hit area with pointer interception
          if (onDragStart != null)
            Positioned(
              left: knobCenter.dx - hitRadius,
              top: knobCenter.dy - hitRadius,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) {
                  // Claim the pointer in the gesture arena so PageView
                  // cannot use it for scrolling
                  GestureBinding.instance.gestureArena
                      .add(event.pointer, _WinningEntry())
                      .resolve(GestureDisposition.accepted);
                  onDragStart!(event.position);
                },
                onPointerMove: onDragUpdate != null
                    ? (event) {
                        onDragUpdate!(event.position);
                      }
                    : null,
                onPointerUp: onDragEnd != null
                    ? (_) {
                        onDragEnd!();
                      }
                    : null,
                onPointerCancel: onDragEnd != null
                    ? (_) {
                        onDragEnd!();
                      }
                    : null,
                child: SizedBox(width: hitRadius * 2, height: hitRadius * 2),
              ),
            ),
        ],
      ),
    );
  }
}

/// A no-op arena member that wins the gesture arena,
/// preventing other recognizers (like PageView's scroll) from claiming the pointer.
class _WinningEntry extends GestureArenaMember {
  @override
  void acceptGesture(int pointer) {}

  @override
  void rejectGesture(int pointer) {}
}
