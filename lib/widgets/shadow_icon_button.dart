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

  Color _disabledColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey.shade900 : Colors.grey.shade300;
  }

  Color _shadowColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.black.withAlpha(200)
        : Colors.grey.shade700.withAlpha(200);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        fill: 1,
        color: onTap == null
            ? _disabledColor(context)
            : color ??
                  (isDark == true
                      ? Colors.grey.shade800
                      : Theme.of(context).colorScheme.surface),
        size: size,
        fontWeight: FontWeight.w900,
        shadows: [
          Shadow(
            offset: Offset(1, 1),
            blurRadius: 3.0,
            color: _shadowColor(context),
          ),
        ],
      ),
    );
  }
}
