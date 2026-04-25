import 'package:file_picker/file_picker.dart';
import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flow_app/shared/enums/enums.barrel.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_picker_plus/flutter_picker_plus.dart';
import 'package:provider/provider.dart';

class TimerSettingsMenu extends HookWidget {
  const TimerSettingsMenu({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final timerProvider = context.watch<TimerProvider>();
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    final iconButtonStyle = theme.iconButtonTheme.style!.copyWith(
      backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(0),
    );

    return SafeArea(
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 12,
        ),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Timer Settings',
            style: theme.textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const MenuSubsectionTitle(title: "Visuals"),

          SwitchListTile(
            title: const Text("Show Background Liquid"),
            value: timerProvider.showBackgroundLiquid,
            onChanged: (val) => timerProvider.setShowBackgroundLiquid(val),
            activeThumbColor: accentColor,
          ),

          SwitchListTile(
            title: const Text("Show Circle Liquid"),
            value: timerProvider.showInnerLiquid,
            onChanged: (val) => timerProvider.setShowInnerLiquid(val),
            activeThumbColor: accentColor,
          ),

          SwitchListTile(
            title: const Text("Hide Circle When Controls Hidden"),
            subtitle: const Text(
              "Show only the timer label when controls are hidden",
            ),
            value: timerProvider.hideCircleWithControls,
            onChanged: (val) => timerProvider.setHideCircleWithControls(val),
            activeThumbColor: accentColor,
          ),

          const SizedBox(height: 10),
          Text("Set Max Scale of Timer", style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ScaleChip(
                seconds: 60,
                label: "1m",
                isSelected: timerProvider.fixedScaleDuration == 60,
                onSelected: () => timerProvider.setFixedScaleDuration(60),
              ),
              ScaleChip(
                seconds: 900,
                label: "15m",
                isSelected: timerProvider.fixedScaleDuration == 900,
                onSelected: () => timerProvider.setFixedScaleDuration(900),
              ),
              ScaleChip(
                seconds: 1500,
                label: "25m",
                isSelected: timerProvider.fixedScaleDuration == 1500,
                onSelected: () => timerProvider.setFixedScaleDuration(1500),
              ),
              ScaleChip(
                seconds: 1800,
                label: "30m",
                isSelected: timerProvider.fixedScaleDuration == 1800,
                onSelected: () => timerProvider.setFixedScaleDuration(1800),
              ),
              ScaleChip(
                seconds: 3600,
                label: "60m",
                isSelected: timerProvider.fixedScaleDuration == 3600,
                onSelected: () => timerProvider.setFixedScaleDuration(3600),
              ),
              ActionChip(
                label: const Text("Custom Scale"),
                onPressed: () =>
                    _showCustomScalePicker(context, timerProvider, accentColor),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const MenuSubsectionTitle(title: "Cycle Configuration"),

          SwitchListTile(
            title: const Text("Auto-start Break"),
            subtitle: const Text("Start break when focus ends"),
            value: timerProvider.autoStartBreak,
            onChanged: (val) => timerProvider.setAutoStartBreak(val),
            activeThumbColor: accentColor,
          ),

          SwitchListTile(
            title: const Text("Auto-start Focus"),
            subtitle: const Text("Start focus when break ends"),
            value: timerProvider.autoStartFocus,
            onChanged: (val) => timerProvider.setAutoStartFocus(val),
            activeThumbColor: accentColor,
          ),

          ListTile(
            title: const Text("Total Loops"),
            subtitle: Text("${timerProvider.targetLoops} Focus Sessions"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  style: iconButtonStyle,
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: timerProvider.targetLoops > 1
                      ? () => timerProvider.setTargetLoops(
                          timerProvider.targetLoops - 1,
                        )
                      : null,
                ),
                Text(
                  "${timerProvider.targetLoops}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  style: iconButtonStyle,
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => timerProvider.setTargetLoops(
                    timerProvider.targetLoops + 1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const MenuSubsectionTitle(title: "Sound"),

          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text("Focus Complete Sound"),
          ),
          _SoundDropdown(
            value: timerProvider.focusCompleteSound,
            customPath: timerProvider.focusCustomSoundPath,
            onChanged: (val, customPath) {
              if (customPath != null) {
                timerProvider.setFocusCustomSoundPath(customPath);
              }
              timerProvider.setFocusCompleteSound(val);
            },
          ),

          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text("Break Complete Sound"),
          ),
          _SoundDropdown(
            value: timerProvider.breakCompleteSound,
            customPath: timerProvider.breakCustomSoundPath,
            onChanged: (val, customPath) {
              if (customPath != null) {
                timerProvider.setBreakCustomSoundPath(customPath);
              }
              timerProvider.setBreakCompleteSound(val);
            },
          ),

          ListTile(
            title: const Text("Sound Repeats"),
            subtitle: Text(
              timerProvider.soundLoops == 1
                  ? "Play once"
                  : "Play ${timerProvider.soundLoops} times",
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  style: iconButtonStyle,
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: timerProvider.soundLoops > 1
                      ? () => timerProvider.setSoundLoops(
                          timerProvider.soundLoops - 1,
                        )
                      : null,
                ),
                Text(
                  "${timerProvider.soundLoops}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  style: iconButtonStyle,
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: timerProvider.soundLoops < 10
                      ? () => timerProvider.setSoundLoops(
                          timerProvider.soundLoops + 1,
                        )
                      : null,
                ),
              ],
            ),
          ),

          SwitchListTile(
            title: const Text("Play Sound in Silent/Vibrate Mode"),
            subtitle: const Text(
              "Override device silent mode for timer alerts",
            ),
            value: timerProvider.playSoundInSilentMode,
            onChanged: (val) => timerProvider.setPlaySoundInSilentMode(val),
            activeThumbColor: accentColor,
          ),

          SwitchListTile(
            title: const Text("Play Default Notification Sound"),
            subtitle: const Text("Play the system sound with the notification"),
            value: timerProvider.playDefaultSound,
            onChanged: (val) => timerProvider.setPlayDefaultSound(val),
            activeThumbColor: accentColor,
          ),

          const SizedBox(height: 16),
          const MenuSubsectionTitle(title: "Session"),

          SwitchListTile(
            title: const Text("Auto-name Sessions"),
            subtitle: const Text("Automatically name sessions with date/time"),
            value: timerProvider.autoNameSessions,
            onChanged: (val) => timerProvider.setAutoNameSessions(val),
            activeThumbColor: accentColor,
          ),

          const SizedBox(height: 16),
          const MenuSubsectionTitle(title: "Controls"),

          SwitchListTile(
            title: const Text("Auto-hide Controls"),
            subtitle: const Text("Hide controls when timer is running"),
            value: timerProvider.autoHideControls,
            onChanged: (val) => timerProvider.setAutoHideControls(val),
            activeThumbColor: accentColor,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showCustomScalePicker(
    BuildContext context,
    TimerProvider timerProvider,
    Color accentColor,
  ) {
    final currentMins = (timerProvider.fixedScaleDuration / 60).round();
    final theme = Theme.of(context);

    final picker = Picker(
      headerDecoration: const BoxDecoration(),
      confirmText: "Set Scale",
      textStyle: theme.textTheme.bodyMedium!.copyWith(
        fontWeight: FontWeight.bold,
      ),
      confirmTextStyle: theme.textTheme.titleMedium!.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
      cancelTextStyle: theme.textTheme.titleMedium!.copyWith(
        color: theme.disabledColor,
      ),
      adapter: NumberPickerAdapter(
        data: [
          NumberPickerColumn(
            begin: 1,
            end: 240,
            initValue: currentMins,
            suffix: const Text(" min"),
          ),
        ],
      ),
      title: const Text("Set Max Scale"),
      onConfirm: (Picker picker, List<int> values) {
        final mins = picker.getSelectedValues()[0] as int;
        timerProvider.setFixedScaleDuration(mins * 60);
      },
    );

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: picker.makePicker(),
          ),
        );
      },
    );
  }
}

class _SoundDropdown extends StatelessWidget {
  const _SoundDropdown({
    required this.value,
    required this.customPath,
    required this.onChanged,
  });

  final SoundType value;
  final String? customPath;
  final void Function(SoundType value, String? customPath) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<SoundType>(
      initialValue: value,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      items: SoundType.values.map((s) {
        String label = s.name.toUpperCase();
        if (s == SoundType.custom && customPath != null) {
          final fileName = customPath!.split('/').last;
          label = 'CUSTOM ($fileName)';
        }
        return DropdownMenuItem(value: s, child: Text(label));
      }).toList(),
      onChanged: (val) async {
        if (val == null) return;
        if (val == SoundType.custom) {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.audio,
          );
          if (result != null && result.files.single.path != null) {
            onChanged(SoundType.custom, result.files.single.path!);
          }
        } else {
          onChanged(val, null);
        }
      },
    );
  }
}
