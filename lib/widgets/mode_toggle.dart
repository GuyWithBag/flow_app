import 'package:flow_app/models/models.barrel.dart';
import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ModeToggle extends StatelessWidget {
  const ModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final presetProvider = Provider.of<PresetProvider>(context);
    final sessionProvider = Provider.of<SessionProvider>(context);

    final isSessionActive = sessionProvider.isSessionActive;

    return Opacity(
      opacity: isSessionActive ? 0.5 : 1.0,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BouncingButton(
              onTap: isSessionActive
                  ? null
                  : () {
                      timerProvider.setTimerType(TimerType.focus);
                      final preset = presetProvider.selectedPreset;
                      timerProvider.setCustomDuration(preset.focusDuration);
                    },
              child: ModeButtonContent(
                label: 'Focus',
                isSelected: timerProvider.currentType == TimerType.focus,
              ),
            ),
            BouncingButton(
              onTap: isSessionActive
                  ? null
                  : () {
                      timerProvider.setTimerType(TimerType.breakTime);
                      final preset = presetProvider.selectedPreset;
                      timerProvider.setCustomDuration(preset.breakDuration);
                    },
              child: ModeButtonContent(
                label: 'Break',
                isSelected: timerProvider.currentType == TimerType.breakTime,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
