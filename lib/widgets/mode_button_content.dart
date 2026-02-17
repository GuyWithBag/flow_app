import 'package:flutter/material.dart';

class ModeButtonContent extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final bool isDark;

  const ModeButtonContent({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? activeColor : Colors.transparent,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }
}
