import 'package:flow_app/models/models.dart';
import 'package:flow_app/providers/providers.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ModeToggle extends StatelessWidget {
  final Color focusColor;
  final Color breakColor;
  final bool isDark;

  const ModeToggle({
    Key? key,
    required this.focusColor,
    required this.breakColor,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final presetProvider = Provider.of<PresetProvider>(context);
    final themeProvider = context.read<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
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
              themeProvider.setModeAccentColor(
                context,
                TimerType.focus,
                focusColor,
              );
            },
            child: ModeButtonContent(
              label: 'Focus',
              isSelected: timerProvider.currentType == TimerType.focus,
              activeColor: focusColor,
              isDark: isDark,
            ),
          ),
          BouncingButton(
            onTap: () {
              timerProvider.setTimerType(TimerType.breakTime);
              final preset = presetProvider.selectedPreset;
              if (preset != null) {
                timerProvider.setCustomDuration(preset.breakDuration);
              }
              themeProvider.setModeAccentColor(
                context,
                TimerType.breakTime,
                breakColor,
              );
            },
            child: ModeButtonContent(
              label: 'Break',
              isSelected: timerProvider.currentType == TimerType.breakTime,
              activeColor: breakColor,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}
