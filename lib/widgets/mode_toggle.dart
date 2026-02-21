import 'package:flow_app/models/models.barrel.dart';
import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ModeToggle extends StatelessWidget {
  const ModeToggle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final presetProvider = Provider.of<PresetProvider>(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BouncingButton(
            onTap: () {
              timerProvider.setTimerType(TimerType.focus);
              final preset = presetProvider.selectedPreset;
              if (preset != null) {
                timerProvider.setCustomDuration(preset.focusDuration);
              }
            },
            child: ModeButtonContent(
              label: 'Focus',
              isSelected: timerProvider.currentType == TimerType.focus,
            ),
          ),
          BouncingButton(
            onTap: () {
              timerProvider.setTimerType(TimerType.breakTime);
              final preset = presetProvider.selectedPreset;
              if (preset != null) {
                timerProvider.setCustomDuration(preset.breakDuration);
              }
            },
            child: ModeButtonContent(
              label: 'Break',
              isSelected: timerProvider.currentType == TimerType.breakTime,
            ),
          ),
        ],
      ),
    );
  }
}
