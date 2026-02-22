import 'package:flow_app/models/models.barrel.dart';
import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';

class TimerBottomControls extends StatelessWidget {
  const TimerBottomControls({
    super.key,
    required this.timerProvider,
    required this.presetProvider,
    required this.sessionProvider,
    required this.currentColor,
  });

  final TimerProvider timerProvider;
  final PresetProvider presetProvider;
  final SessionProvider sessionProvider;
  final Color currentColor;

  @override
  Widget build(BuildContext context) {
    void resetLoop() {
      if (sessionProvider.isSessionActive) {
        // Show confirmation dialog if session is active
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Reset Session?'),
            content: const Text(
              'This will cancel the current session and discard all progress.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  sessionProvider.cancelSession();
                  timerProvider.resetLoop();
                  timerProvider.resetTimerToPreset(
                    presetProvider.selectedPreset,
                  );
                  Navigator.pop(ctx);
                },
                child: const Text('Reset'),
              ),
            ],
          ),
        );
      } else {
        // No active session, just reset
        timerProvider.resetLoop();
        timerProvider.resetTimerToPreset(presetProvider.selectedPreset);
      }
    }

    void finishSession() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('End Session'),
          content: const Text(
            'Do you want to finish this session (save progress) or cancel it (discard)?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                sessionProvider.cancelSession();
                timerProvider.resetLoop();
                timerProvider.resetTimerToPreset(presetProvider.selectedPreset);
                Navigator.pop(ctx);
              },
              child: const Text('Cancel Session'),
            ),
            ElevatedButton(
              onPressed: () {
                sessionProvider.finishSession(context);
                timerProvider.resetLoop();
                timerProvider.resetTimerToPreset(presetProvider.selectedPreset);
                Navigator.pop(ctx);
              },
              child: const Text('Finish Session'),
            ),
          ],
        ),
      );
    }

    void skipCycle() {
      // Complete current loop as skipped
      sessionProvider.completeCurrentLoop(skipped: true);
      timerProvider.resetTimerToPreset(presetProvider.selectedPreset);

      if (timerProvider.currentType == TimerType.focus) {
        // After skipping focus, go to break
        timerProvider.setTimerType(TimerType.breakTime);
        final preset = presetProvider.selectedPreset;
        sessionProvider.startLoop(
          type: TimerType.breakTime,
          duration: preset.breakDuration,
        );
        if (timerProvider.autoStartBreak) {
          timerProvider.startTimer();
        }
      } else {
        // After skipping break, go to next focus
        timerProvider.incrementLoop();
        timerProvider.setTimerType(TimerType.focus);

        // Check if we've completed all loops
        if (timerProvider.currentLoop > timerProvider.targetLoops) {
          sessionProvider.finishSession(context);
          timerProvider.resetLoop();
          // Show completion dialog
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Great Flow!"),
              content: Text(
                "You completed ${timerProvider.targetLoops} focus sessions!",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Finish"),
                ),
              ],
            ),
          );
        } else {
          final preset = presetProvider.selectedPreset;
          sessionProvider.startLoop(
            type: TimerType.focus,
            duration: preset.focusDuration,
          );
          if (timerProvider.autoStartFocus) {
            timerProvider.startTimer();
          }
        }
      }
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final isCompact = screenHeight < 700;
    final btnSize = isCompact ? 36.0 : 48.0;
    final iconSize = isCompact ? 20.0 : 24.0;

    final filledFlatButton = IconButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      foregroundColor: Theme.of(context).colorScheme.inverseSurface,
      minimumSize: Size(btnSize, btnSize),
      maximumSize: Size(btnSize, btnSize),
      iconSize: iconSize,
    );

    return Row(
      children: [
        BouncingButton(
          child: IconButton(
            onPressed: resetLoop,
            icon: const Icon(Icons.refresh),
            style: filledFlatButton,
          ),
        ),
        const Spacer(flex: 3),
        BouncingButton(
          child: IconButton.filled(
            onPressed: sessionProvider.isSessionActive ? finishSession : null,
            icon: const Icon(Icons.stop),
            style: filledFlatButton,
          ),
        ),
        const Spacer(flex: 1),
        BouncingButton(child: PlayPauseButton()),
        const Spacer(flex: 1),
        BouncingButton(
          child: IconButton(
            onPressed: skipCycle,
            icon: const Icon(Icons.skip_next),
            style: filledFlatButton,
          ),
        ),
        const Spacer(flex: 3),
        BouncingButton(
          child: IconButton(
            onPressed: () {
              _showSettingsSheet(context, timerProvider);
            },
            icon: const Icon(Icons.tune),
            style: filledFlatButton,
          ),
        ),
      ],
    );
  }

  void _showSettingsSheet(BuildContext context, TimerProvider timerProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return TimerSettingsMenu(
              timerProvider: timerProvider,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }
}
