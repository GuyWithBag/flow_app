import 'package:flow_app/models/models.barrel.dart';
import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AddPresetDialog extends HookWidget {
  final PresetProvider presetProvider;
  final TimerProvider timerProvider;

  const AddPresetDialog({
    Key? key,
    required this.presetProvider,
    required this.timerProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Using useTextEditingController for automatic disposal
    final nameController = useTextEditingController();
    final focusMinutesController = useTextEditingController(text: '25');
    final focusSecondsController = useTextEditingController(text: '0');
    final breakMinutesController = useTextEditingController(text: '5');
    final breakSecondsController = useTextEditingController(text: '0');
    final longFocusMinutesController = useTextEditingController(text: '50');
    final longFocusSecondsController = useTextEditingController(text: '0');
    final longBreakMinutesController = useTextEditingController(text: '15');
    final longBreakSecondsController = useTextEditingController(text: '0');

    void createPreset() {
      final name = nameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a preset name')),
        );
        return;
      }

      final focusMinutes = int.tryParse(focusMinutesController.text) ?? 0;
      final focusSeconds = int.tryParse(focusSecondsController.text) ?? 0;
      final breakMinutes = int.tryParse(breakMinutesController.text) ?? 0;
      final breakSeconds = int.tryParse(breakSecondsController.text) ?? 0;
      final longFocusMinutes =
          int.tryParse(longFocusMinutesController.text) ?? 0;
      final longFocusSeconds =
          int.tryParse(longFocusSecondsController.text) ?? 0;
      final longBreakMinutes =
          int.tryParse(longBreakMinutesController.text) ?? 0;
      final longBreakSeconds =
          int.tryParse(longBreakSecondsController.text) ?? 0;

      final focusDuration = (focusMinutes * 60) + focusSeconds;
      final breakDuration = (breakMinutes * 60) + breakSeconds;
      final longFocusDuration = (longFocusMinutes * 60) + longFocusSeconds;
      final longBreakDuration = (longBreakMinutes * 60) + longBreakSeconds;

      if (focusDuration <= 0 ||
          breakDuration <= 0 ||
          longFocusDuration <= 0 ||
          longBreakDuration <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All durations must be greater than 0')),
        );
        return;
      }

      final newPreset = PomodoroPreset(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        focusDuration: focusDuration,
        breakDuration: breakDuration,
        longFocusDuration: longFocusDuration,
        longBreakDuration: longBreakDuration,
      );

      presetProvider.addPreset(newPreset);
      presetProvider.selectPreset(newPreset);

      if (timerProvider.currentType == TimerType.focus) {
        timerProvider.setCustomDuration(focusDuration);
      } else {
        timerProvider.setCustomDuration(breakDuration);
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preset "$name" created and selected')),
      );
    }

    return AlertDialog(
      title: const Text('Create Custom Preset'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Preset Name',
                hintText: 'e.g., My Custom Preset',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            DurationInputSection(
              title: 'Focus Duration',
              minutesController: focusMinutesController,
              secondsController: focusSecondsController,
            ),
            const SizedBox(height: 16),
            DurationInputSection(
              title: 'Break Duration',
              minutesController: breakMinutesController,
              secondsController: breakSecondsController,
            ),
            const SizedBox(height: 16),
            DurationInputSection(
              title: 'Long Focus Duration',
              minutesController: longFocusMinutesController,
              secondsController: longFocusSecondsController,
            ),
            const SizedBox(height: 16),
            DurationInputSection(
              title: 'Long Break Duration',
              minutesController: longBreakMinutesController,
              secondsController: longBreakSecondsController,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: createPreset, child: const Text('Create')),
      ],
    );
  }
}
