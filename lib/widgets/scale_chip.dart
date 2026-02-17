import 'package:flutter/material.dart';

class ScaleChip extends StatelessWidget {
  final int seconds;
  final String label;
  final ValueNotifier<int> notifier;
  final StateSetter setState;

  const ScaleChip({
    Key? key,
    required this.seconds,
    required this.label,
    required this.notifier,
    required this.setState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSelected = notifier.value == seconds;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() => notifier.value = seconds);
        }
      },
    );
  }
}
