import 'package:flutter/material.dart';

class ScaleChip extends StatelessWidget {
  final int seconds;
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const ScaleChip({
    super.key,
    required this.seconds,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          onSelected();
        }
      },
    );
  }
}
