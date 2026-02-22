import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';

class TimerTopControls extends StatelessWidget {
  const TimerTopControls({
    super.key,
    required this.timerProvider,
    required this.showPresetSelector,
  });

  final TimerProvider timerProvider;
  final bool showPresetSelector;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Flow',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            Row(
              spacing: 8,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      "Loop ${timerProvider.currentLoop} / ${timerProvider.targetLoops}",
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                PresetSelector(),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
