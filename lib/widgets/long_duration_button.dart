import 'package:flow_app/models/models.barrel.dart';
import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class LongDurationButton extends StatelessWidget {
  const LongDurationButton({super.key});

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final presetProvider = Provider.of<PresetProvider>(context);

    final preset = presetProvider.selectedPreset;
    if (preset == null) return const SizedBox.shrink();

    final isFocusMode = timerProvider.currentType == TimerType.focus;
    final longDuration = isFocusMode
        ? preset.longFocusDuration
        : preset.longBreakDuration;
    final regularDuration = isFocusMode
        ? preset.focusDuration
        : preset.breakDuration;
    final isActive = timerProvider.isLongDuration;
    final label = isFocusMode ? 'Long Focus' : 'Long Break';

    return FilterChip(
      label: Text('$label (${_formatDuration(longDuration)})'),
      selected: isActive,
      onSelected: timerProvider.isRunning
          ? null
          : (selected) {
              timerProvider.setLongDuration(selected);
              if (selected) {
                timerProvider.setCustomDuration(longDuration);
                if (timerProvider.fixedScaleDuration < longDuration) {
                  timerProvider.setFixedScaleDuration(longDuration);
                }
              } else {
                timerProvider.setCustomDuration(regularDuration);
              }
              HapticFeedback.mediumImpact();
            },
    );
  }
}
