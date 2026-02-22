import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/providers.barrel.dart';

class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton({super.key});

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final sessionProvider = context.read<SessionProvider>();
    final presetProvider = context.read<PresetProvider>();
    // return Container(
    //   width: 80,
    //   height: 80,
    //   decoration: BoxDecoration(
    //     shape: BoxShape.circle,
    //     color: color,
    //     boxShadow: [
    //       BoxShadow(
    //         color: color.withValues(alpha: 0.4),
    //         blurRadius: 15,
    //         offset: const Offset(0, 5),
    //       ),
    //     ],
    //   ),
    //   child: Icon(
    //     timerProvider.isRunning ? Icons.pause : Icons.play_arrow_rounded,
    //     size: 45,
    //     color: Colors.white,
    //   ),
    // );
    final screenHeight = MediaQuery.of(context).size.height;
    final isCompact = screenHeight < 700;
    final buttonSize = isCompact ? 72.0 : 100.0;
    final iconSize = isCompact ? 38.0 : 52.0;

    return IconButton.filled(
      onPressed: () {
        if (timerProvider.isRunning) {
          timerProvider.pauseTimer();
        } else {
          final preset = presetProvider.selectedPreset;
          sessionProvider.startSession(
            userId: 'current_user',
            type: timerProvider.currentType,
            duration: timerProvider.totalSeconds,
            presetName: preset.name,
          );
          timerProvider.startTimer();
        }
      },
      constraints: BoxConstraints.expand(width: buttonSize, height: buttonSize),
      icon: Icon(
        timerProvider.isRunning ? Icons.pause : Icons.play_arrow_rounded,
        size: iconSize,
        color: Colors.white,
      ),
    );
  }
}
