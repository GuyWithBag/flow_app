import 'package:flow_app/models/models.barrel.dart';
import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flow_app/services/ad_service.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    // Watch directly so this widget rebuilds whenever session state changes,
    // regardless of whether the parent has rebuilt yet.
    final isSessionActive = context.watch<SessionProvider>().isSessionActive;

    void resetLoop() {
      timerProvider.resetTimerToPreset(presetProvider.selectedPreset);
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
      final themeProvider = context.read<ThemeProvider>();

      // Complete current loop as skipped
      sessionProvider.completeCurrentLoop(skipped: true);
      timerProvider.resetTimerToPreset(presetProvider.selectedPreset);

      if (timerProvider.currentType == TimerType.focus) {
        // Check if this was the last focus loop
        if (timerProvider.currentLoop >= timerProvider.targetLoops) {
          sessionProvider.finishSession(context);
          timerProvider.resetLoop();
          timerProvider.resetTimerToPreset(presetProvider.selectedPreset);
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
          // Go to break
          timerProvider.setTimerType(TimerType.breakTime);
          themeProvider.updateTimerType(TimerType.breakTime);
          final preset = presetProvider.selectedPreset;
          sessionProvider.startLoop(
            type: TimerType.breakTime,
            duration: preset.breakDuration,
          );
          if (timerProvider.autoStartBreak) {
            timerProvider.startTimer();
          }
        }
      } else {
        // After skipping break, go to next focus
        timerProvider.incrementLoop();
        timerProvider.setTimerType(TimerType.focus);
        themeProvider.updateTimerType(TimerType.focus);

        if (timerProvider.currentLoop > timerProvider.targetLoops) {
          sessionProvider.finishSession(context);
          timerProvider.resetLoop();
          timerProvider.resetTimerToPreset(presetProvider.selectedPreset);
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

    final adService = context.watch<AdService>();
    final sideButtonsSize = 30.0;

    return Row(
      children: [
        BouncingButton(
          child: ShadowIconButton(
            onTap: resetLoop,
            icon: Icons.refresh_rounded,
            size: sideButtonsSize,
          ),
        ),
        const Spacer(flex: 3),
        // BouncingButton(
        //   child: IconButton.filled(
        //     onPressed: sessionProvider.isSessionActive ? finishSession : null,
        //     icon: const Icon(Icons.stop),
        //     style: filledFlatButton,
        //   ),
        // ),
        BouncingButton(
          child: ShadowIconButton(
            onTap: isSessionActive ? finishSession : null,
            icon: Icons.stop_rounded,
          ),
        ),
        const Spacer(flex: 1),
        BouncingButton(child: PlayPauseButton()),
        const Spacer(flex: 1),
        BouncingButton(
          // child: IconButton(
          //   onPressed: skipCycle,
          //   icon: const Icon(Icons.skip_next),
          //   style: filledFlatButton,
          // ),
          child: ShadowIconButton(
            icon: Icons.skip_next_rounded,
            onTap: skipCycle,
          ),
        ),
        const Spacer(flex: 3),
        BouncingButton(
          // child: IconButton(
          //   onPressed: () {
          //     if (!context.read<PurchaseProvider>().isNoAds) {
          //       adService.iAd?.show();
          //     }
          //     _showSettingsSheet(context, timerProvider);
          //   },
          //   icon: const Icon(Icons.tune),
          //   style: filledFlatButton,
          // ),
          child: ShadowIconButton(
            onTap: () {
              _showSettingsSheet(context, timerProvider);
              if (!context.read<PurchaseProvider>().isNoAds) {
                adService.maybeShowInterstitial(
                  id: 'timer_settings',
                  frequency: 3,
                );
              }
            },
            icon: Icons.tune_rounded,
            size: sideButtonsSize,
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
            return TimerSettingsMenu(scrollController: scrollController);
          },
        );
      },
    );
  }
}
