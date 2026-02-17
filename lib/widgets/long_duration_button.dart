import 'package:flow_app/models/models.dart';
import 'package:flow_app/providers/providers.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class LongDurationButton extends StatelessWidget {
  final Color focusColor;
  final Color breakColor;
  final bool isDark;

  const LongDurationButton({
    Key? key,
    required this.focusColor,
    required this.breakColor,
    required this.isDark,
  }) : super(key: key);

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
    final currentColor = isFocusMode ? focusColor : breakColor;
    final buttonLabel = isFocusMode ? 'Long Focus' : 'Long Break';
    final formattedDuration = _formatDuration(longDuration);

    return BouncingButton(
      onTap: () {
        if (timerProvider.isRunning) return;
        timerProvider.setCustomDuration(longDuration);
        HapticFeedback.mediumImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: currentColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: currentColor.withOpacity(0.4), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 18, color: currentColor),
            const SizedBox(width: 8),
            Text(
              '$buttonLabel ($formattedDuration)',
              style: TextStyle(
                color: currentColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
