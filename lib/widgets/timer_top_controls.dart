import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';

class TimerTopControls extends StatelessWidget {
  const TimerTopControls({
    super.key,
    required this.controlsVisible,
    required this.timerProvider,
    required this.isDark,
    required this.showPresetSelector,
  });

  final ValueNotifier<bool> controlsVisible;
  final TimerProvider timerProvider;
  final bool isDark;
  final bool showPresetSelector;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      offset: controlsVisible.value ? Offset.zero : const Offset(0, -2.0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: controlsVisible.value ? 1.0 : 0.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Flow',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
                // Preset Selector and Loop Indicator
                Row(
                  spacing: 8,
                  children: [
                    PresetSelector(),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          "Loop ${timerProvider.currentLoop} / ${timerProvider.targetLoops}",
                          style: Theme.of(context).textTheme.labelMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const ModeToggle(),
          ],
        ),
      ),
    );
  }
}
