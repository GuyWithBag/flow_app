import 'package:flutter/material.dart';

class ModeButtonContent extends StatelessWidget {
  final String label;
  final bool isSelected;

  const ModeButtonContent({
    super.key,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.transparent,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
