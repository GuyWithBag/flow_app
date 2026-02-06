import 'package:flow_app/models/models.dart';
import 'package:flow_app/providers/providers.dart';
import 'package:flow_app/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

class TimerScreen extends HookWidget {
  const TimerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final focusColor = themeProvider.getAccentColorFor(TimerType.focus);
    final breakColor = themeProvider.getAccentColorFor(TimerType.breakTime);

    final currentColor = timerProvider.currentType == TimerType.focus
        ? focusColor
        : breakColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Center(
                child: Text(
                  'Flow',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Mode Toggle
            _buildModeToggle(context, timerProvider, focusColor, breakColor),

            const SizedBox(height: 40),

            // Circular Timer
            Expanded(
              child: Center(
                child: _buildCircularTimer(
                  context,
                  timerProvider,
                  currentColor,
                ),
              ),
            ),

            // Control Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildResetButton(context, timerProvider),
                  const SizedBox(width: 20),
                  _buildPlayPauseButton(context, timerProvider, currentColor),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle(
    BuildContext context,
    TimerProvider timerProvider,
    Color focusColor,
    Color breakColor,
  ) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModeButton(
              'Focus',
              timerProvider.currentType == TimerType.focus,
              focusColor,
              () => timerProvider.setTimerType(TimerType.focus),
            ),
            _buildModeButton(
              'Break',
              timerProvider.currentType == TimerType.breakTime,
              breakColor,
              () => timerProvider.setTimerType(TimerType.breakTime),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(
    String label,
    bool isSelected,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCircularTimer(
    BuildContext context,
    TimerProvider timerProvider,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => _showTimePicker(context, timerProvider),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade100,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),

          // Animated progress circle
          SizedBox(
            width: 280,
            height: 280,
            child: CustomPaint(
              painter: CircularProgressPainter(
                progress: timerProvider.progress,
                color: color,
              ),
            ),
          ),

          // Time and label
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timerProvider.formattedTime,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set Time',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(BuildContext context, TimerProvider timerProvider) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: timerProvider.resetTimer,
        customBorder: const CircleBorder(),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.refresh, size: 30, color: Colors.black54),
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton(
    BuildContext context,
    TimerProvider timerProvider,
    Color color,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (timerProvider.isRunning) {
            timerProvider.pauseTimer();
          } else {
            timerProvider.startTimer();
          }
        },
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
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
            timerProvider.isRunning ? Icons.pause : Icons.play_arrow,
            size: 40,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showTimePicker(BuildContext context, TimerProvider timerProvider) {
    if (timerProvider.isRunning) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => TimePickerSheet(
        initialSeconds: timerProvider.remainingSeconds,
        onTimeSelected: (seconds) {
          timerProvider.setCustomDuration(seconds);
          Navigator.pop(context);
        },
      ),
    );
  }
}
