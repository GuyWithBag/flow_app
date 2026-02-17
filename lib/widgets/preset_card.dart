import 'package:flutter/material.dart';

import '../models/models.dart';

class PresetCard extends StatelessWidget {
  final PomodoroPreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const PresetCard({
    Key? key,
    required this.preset,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? const Color(0xFF66BB6A).withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: Color(0xFF66BB6A), width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          preset.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Focus: ${preset.focusDuration ~/ 60}m  •  Break: ${preset.breakDuration ~/ 60}m  •  Long Focus: ${preset.longFocusDuration ~/ 60}m  •  Long Break: ${preset.longBreakDuration ~/ 60}m',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Color(0xFF66BB6A))
            : null,
        onTap: onTap,
      ),
    );
  }
}
