// --- BOUNCING BUTTON ANIMATION ---
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class BouncingButton extends HookWidget {
  final Widget child;
  final VoidCallback onTap;

  const BouncingButton({Key? key, required this.child, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 100),
    );

    final scaleAnimation = useAnimation(
      Tween<double>(
        begin: 1.0,
        end: 0.9,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut)),
    );

    return GestureDetector(
      onTapDown: (_) => controller.forward(),
      onTapUp: (_) {
        controller.reverse();
        onTap();
      },
      onTapCancel: () => controller.reverse(),
      child: Transform.scale(scale: scaleAnimation, child: child),
    );
  }
}
