import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/providers.barrel.dart';

class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton({super.key});

  String _getDefaultSessionName() {
    final now = DateTime.now();
    final formattedDate = DateFormat('MMM d, h:mm a').format(now);
    return 'Flow Session - $formattedDate';
  }

  void _showSessionNameDialog(
    BuildContext context,
    TimerProvider timerProvider,
    SessionProvider sessionProvider,
    PresetProvider presetProvider,
  ) {
    final defaultName = _getDefaultSessionName();
    final nameController = TextEditingController(text: defaultName);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Session'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Session Name',
            hintText: 'e.g., Morning Deep Work',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (_) {
            final name = nameController.text.trim();
            if (name.isNotEmpty) {
              _startSession(
                context,
                timerProvider,
                sessionProvider,
                presetProvider,
                name,
              );
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                _startSession(
                  context,
                  timerProvider,
                  sessionProvider,
                  presetProvider,
                  name,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _startSession(
    BuildContext context,
    TimerProvider timerProvider,
    SessionProvider sessionProvider,
    PresetProvider presetProvider,
    String sessionName,
  ) {
    final preset = presetProvider.selectedPreset;

    // Create the session
    sessionProvider.startSession(
      userId: 'current_user',
      name: sessionName,
      targetLoops: timerProvider.targetLoops,
      presetName: preset.name,
    );

    // Start the first loop
    sessionProvider.startLoop(
      type: timerProvider.currentType,
      duration: timerProvider.totalSeconds,
    );

    // Start the timer
    timerProvider.startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final sessionProvider = context.watch<SessionProvider>();
    final presetProvider = context.read<PresetProvider>();

    // final screenHeight = MediaQuery.of(context).size.height;
    // final isCompact = screenHeight < 700;
    // final buttonSize = isCompact ? 72.0 : 100.0;
    // final iconSize = isCompact ? 38.0 : 52.0;

    return ShadowIconButton(
      onTap: () {
        if (timerProvider.isRunning) {
          // Pause the timer
          timerProvider.pauseTimer();
        } else {
          if (sessionProvider.isSessionActive) {
            // Resume the timer (session already exists)
            timerProvider.startTimer();
          } else {
            // No active session - check if we should auto-name or show dialog
            if (timerProvider.autoNameSessions) {
              // Auto-name and start immediately
              _startSession(
                context,
                timerProvider,
                sessionProvider,
                presetProvider,
                _getDefaultSessionName(),
              );
            } else {
              // Show naming dialog
              _showSessionNameDialog(
                context,
                timerProvider,
                sessionProvider,
                presetProvider,
              );
            }
          }
        }
      },
      // constraints: BoxConstraints.expand(width: buttonSize, height: buttonSize),
      icon: timerProvider.isRunning
          ? Icons.pause_rounded
          : Icons.play_arrow_rounded,
    );
  }
}
