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
    final themeProvider = context.watch<ThemeProvider>();

    final isSessionActive = sessionProvider.isSessionActive;

    void onTap(TimerType toType) {
      if (timerProvider.currentType == toType) return;

      timerProvider.setTimerType(toType);
      themeProvider.updateTimerType(toType);
      if (toType == TimerType.focus) {
        timerProvider.setCustomDuration(
          presetProvider.selectedPreset.focusDuration,
        );
      } else {
        timerProvider.setCustomDuration(
          presetProvider.selectedPreset.breakDuration,
        );
      }
    }

    return Opacity(
      opacity: isSessionActive ? 0.5 : 1.0,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BouncingButton(
              onTap: () => onTap(TimerType.focus),

              child: ModeButtonContent(
                label: 'Focus',
                isSelected: timerProvider.currentType == TimerType.focus,
              ),
            ),
            BouncingButton(
              onTap: () => onTap(TimerType.breakTime),
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
