import 'package:flutter/material.dart';

class AnimatedVisibility extends StatelessWidget {
  const AnimatedVisibility({
    super.key,
    required this.visible,
    required this.child,
    this.slideOffset = const Offset(0, 2.0),
    this.slideDuration = const Duration(milliseconds: 500),
    this.opacityDuration = const Duration(milliseconds: 400),
    this.curve = Curves.easeInOutCubic,
    this.maintainSize = false,
  });

  final bool visible;
  final Widget child;
  final Offset slideOffset;
  final Duration slideDuration;
  final Duration opacityDuration;
  final Curve curve;

  /// If true, the widget will take up space even when not visible.
  /// If false, the widget will be removed from the layout when not visible.
  final bool maintainSize;

  @override
  Widget build(BuildContext context) {
    if (!maintainSize && !visible) {
      return const SizedBox.shrink();
    }

    return AnimatedSlide(
      duration: slideDuration,
      curve: curve,
      offset: visible ? Offset.zero : slideOffset,
      child: AnimatedOpacity(
        duration: opacityDuration,
        opacity: visible ? 1.0 : 0.0,
        child: child,
      ),
    );
  }
}
