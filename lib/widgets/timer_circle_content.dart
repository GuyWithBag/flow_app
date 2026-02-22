import 'package:flutter/material.dart';

class TimerCircleContent extends StatelessWidget {
  final String formattedTime;
  final bool isRunning;
  final bool controlsVisible;
  final bool isDark;

  const TimerCircleContent({
    super.key,
    required this.formattedTime,
    required this.isRunning,
    required this.controlsVisible,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formattedTime,
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            key: ValueKey("$isRunning-$controlsVisible"),
            isRunning
                ? (controlsVisible ? "Running" : "Tap for controls")
                : "Tap to Edit",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade300 : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
