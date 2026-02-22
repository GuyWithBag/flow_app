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
      timerProvider.resetLoop();
      timerProvider.resetTimer();
      sessionProvider.clearCurrentSession();
    }

    void finishSession() {
      sessionProvider.completeCurrentSession();
      timerProvider.resetLoop();
      timerProvider.resetTimer();
      sessionProvider.clearCurrentSession();
    }

    void skipCycle() {
      sessionProvider.clearCurrentSession();
      timerProvider.resetTimer();
      if (timerProvider.currentType == TimerType.focus) {
        timerProvider.setTimerType(TimerType.breakTime);
      } else {
        timerProvider.incrementLoop();
        timerProvider.setTimerType(TimerType.focus);
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
            onPressed: finishSession,
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
