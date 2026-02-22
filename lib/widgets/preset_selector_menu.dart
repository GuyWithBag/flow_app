import 'package:flow_app/models/models.barrel.dart';
import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';

class PresetSelectorMenu extends StatelessWidget {
  final PresetProvider presetProvider;
  final TimerProvider timerProvider;
  final bool showAddButton;
  final VoidCallback? onPresetSelected;
  final ScrollController? scrollController;

  const PresetSelectorMenu({
    super.key,
    required this.presetProvider,
    required this.timerProvider,
    this.showAddButton = true,
    this.onPresetSelected,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pomodoro Presets',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (showAddButton)
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddPresetDialog(context),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: presetProvider.presets.length,
            itemBuilder: (context, index) {
              final preset = presetProvider.presets[index];
              final isSelected = presetProvider.selectedPreset.id == preset.id;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isSelected ? 4 : 1,
                color: isSelected
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isSelected
                      ? BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        )
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
                  trailing: !_isDefaultPreset(preset.id)
                      ? IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () =>
                              _showEditPresetDialog(context, preset),
                        )
                      : null,
                  onTap: () {
                    presetProvider.selectPreset(preset);
                    if (timerProvider.currentType == TimerType.focus) {
                      timerProvider.setCustomDuration(preset.focusDuration);
                    } else {
                      timerProvider.setCustomDuration(preset.breakDuration);
                    }
                    onPresetSelected?.call();
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _isDefaultPreset(String id) {
    return id == 'classic' || id == 'light_study' || id == 'heavy_study';
  }

  void _showAddPresetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddPresetDialog(
        presetProvider: presetProvider,
        timerProvider: timerProvider,
      ),
    );
  }

  void _showEditPresetDialog(BuildContext context, PomodoroPreset preset) {
    final nameController = TextEditingController(text: preset.name);
    final focusMinutes = ValueNotifier(preset.focusDuration ~/ 60);
    final breakMinutes = ValueNotifier(preset.breakDuration ~/ 60);
    final longFocusMinutes = ValueNotifier(preset.longFocusDuration ~/ 60);
    final longBreakMinutes = ValueNotifier(preset.longBreakDuration ~/ 60);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Preset'),
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
          TextButton(
            onPressed: () {
              presetProvider.deletePreset(preset.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final updatedPreset = preset.copyWith(
                  name: nameController.text,
                  focusDuration: focusMinutes.value * 60,
                  breakDuration: breakMinutes.value * 60,
                  longFocusDuration: longFocusMinutes.value * 60,
                  longBreakDuration: longBreakMinutes.value * 60,
                );
                presetProvider.updatePreset(updatedPreset);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
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
              max: 120,
              divisions: 119,
              onChanged: (v) => value.value = v.toInt(),
            ),
          ],
        );
      },
    );
  }
}
