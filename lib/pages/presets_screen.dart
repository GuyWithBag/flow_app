import 'package:flow_app/models/models.dart';
import 'package:flow_app/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

class PresetsScreen extends HookWidget {
  const PresetsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final presetProvider = Provider.of<PresetProvider>(context);
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Pomodoro Presets'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPresetDialog(context, presetProvider),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16 + kToolbarHeight, 16, 16),
        itemCount: presetProvider.presets.length,
        itemBuilder: (context, index) {
          final preset = presetProvider.presets[index];
          final isSelected = presetProvider.selectedPreset?.id == preset.id;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: isSelected ? 4 : 1,
            color: isSelected ? const Color(0xFF66BB6A).withOpacity(0.1) : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isSelected
                  ? const BorderSide(color: Color(0xFF66BB6A), width: 2)
                  : BorderSide.none,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                preset.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Focus: ${preset.focusDuration ~/ 60}m  •  Break: ${preset.breakDuration ~/ 60}m  •  Long Focus: ${preset.longFocusDuration ~/ 60}m  •  Long Break: ${preset.longBreakDuration ~/ 60}m',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Color(0xFF66BB6A))
                  : null,
              onTap: () {
                presetProvider.selectPreset(preset);
                timerProvider.setCustomDuration(preset.focusDuration);
                Navigator.pop(context);
              },
            ),
          );
        },
      ),
    );
  }

  void _showAddPresetDialog(BuildContext context, PresetProvider provider) {
    final nameController = TextEditingController();
    final focusMinutes = ValueNotifier(25);
    final breakMinutes = ValueNotifier(5);
    final longFocusMinutes = ValueNotifier(50);
    final longBreakMinutes = ValueNotifier(15);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Preset'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Preset Name'),
              ),
              const SizedBox(height: 16),
              _buildMinuteSlider('Focus Duration', focusMinutes),
              _buildMinuteSlider('Break Duration', breakMinutes),
              _buildMinuteSlider('Long Focus Duration', longFocusMinutes),
              _buildMinuteSlider('Long Break Duration', longBreakMinutes),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final preset = PomodoroPreset(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  focusDuration: focusMinutes.value * 60,
                  breakDuration: breakMinutes.value * 60,
                  longFocusDuration: longFocusMinutes.value * 60,
                  longBreakDuration: longBreakMinutes.value * 60,
                );
                provider.addPreset(preset);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildMinuteSlider(String label, ValueNotifier<int> value) {
    return ValueListenableBuilder<int>(
      valueListenable: value,
      builder: (context, val, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label: $val minutes'),
            Slider(
              value: val.toDouble(),
              min: 1,
              max: 60,
              divisions: 59,
              onChanged: (v) => value.value = v.toInt(),
            ),
          ],
        );
      },
    );
  }
}
