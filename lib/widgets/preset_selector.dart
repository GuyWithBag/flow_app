import 'package:flow_app/models/models.dart';
import 'package:flow_app/providers/providers.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PresetSelector extends StatelessWidget {
  final bool isDark;

  const PresetSelector({Key? key, required this.isDark}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final presetProvider = Provider.of<PresetProvider>(context);
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings_applications,
                size: 18,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Preset:',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                presetProvider.selectedPreset?.name ?? 'None',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () => _showPresetSelector(
              context,
              presetProvider,
              timerProvider,
              isDark,
            ),
            child: Text(
              presetProvider.selectedPreset != null ? 'Change' : 'Select',
              style: TextStyle(
                color: isDark ? Colors.blue.shade300 : Colors.blue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPresetSelector(
    BuildContext context,
    PresetProvider presetProvider,
    TimerProvider timerProvider,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Preset',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddPresetDialog(
                      context,
                      presetProvider,
                      timerProvider,
                      isDark,
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Custom Preset'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Available Presets',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: presetProvider.presets.length,
                  itemBuilder: (context, index) {
                    final preset = presetProvider.presets[index];
                    final isSelected =
                        presetProvider.selectedPreset?.id == preset.id;

                    return PresetCard(
                      preset: preset,
                      isSelected: isSelected,
                      onTap: () {
                        presetProvider.selectPreset(preset);
                        if (timerProvider.currentType == TimerType.focus) {
                          timerProvider.setCustomDuration(preset.focusDuration);
                        } else {
                          timerProvider.setCustomDuration(preset.breakDuration);
                        }
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    presetProvider.clearPreset();
                    Navigator.pop(context);
                  },
                  child: const Text('Clear Selection'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddPresetDialog(
    BuildContext context,
    PresetProvider presetProvider,
    TimerProvider timerProvider,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (context) => AddPresetDialog(
        presetProvider: presetProvider,
        timerProvider: timerProvider,
      ),
    );
  }
}
