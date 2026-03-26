import 'package:flutter/material.dart';

class ShadowIconButton extends StatelessWidget {
  const ShadowIconButton({
    super.key,
    this.onTap,
    required this.icon,
    this.size = 56,
    this.color,
  });

  final Function()? onTap;
  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        fill: 1,
        color: onTap == null
            ? Colors.grey.shade200
            : color ?? Theme.of(context).colorScheme.surface,
        size: size,
        fontWeight: FontWeight.w900,

        shadows: [
          Shadow(
            offset: Offset(1, 1), // X and Y offset
            blurRadius: 3.0, // Blur radius
            color: Colors.grey.shade700.withAlpha(
              200,
            ), // Shadow color and opacity
          ),
        ],
      ),
    );
  }
}
