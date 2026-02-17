import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/providers.dart';

class PlayPauseButton extends StatelessWidget {
  final Color color;

  const PlayPauseButton({Key? key, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(
        timerProvider.isRunning ? Icons.pause : Icons.play_arrow_rounded,
        size: 45,
        color: Colors.white,
      ),
    );
  }
}
