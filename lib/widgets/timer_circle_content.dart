import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimerCircleContent extends StatelessWidget {
  final String formattedTime;
  final bool isRunning;
  final bool controlsVisible;

  const TimerCircleContent({
    super.key,
    required this.formattedTime,
    required this.isRunning,
    required this.controlsVisible,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formattedTime,
          style: GoogleFonts.dynaPuff(
            // fontWeight: FontWeight.bold,
            fontSize: 60,
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
              color: isDark ? Colors.grey.shade400 : Colors.black54,
              fontFamily: 'DynaPuff',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
