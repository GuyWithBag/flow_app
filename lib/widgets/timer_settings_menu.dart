import 'package:file_picker/file_picker.dart';
import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flow_app/shared/enums/enums.barrel.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_picker_plus/flutter_picker_plus.dart';

class TimerSettingsMenu extends StatelessWidget {
  const TimerSettingsMenu({
    super.key,
    required this.timerProvider,
    this.scrollController,
  });

  final TimerProvider timerProvider;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final iconButtonStyle = theme.iconButtonTheme.style!.copyWith(
      backgroundColor: WidgetStatePropertyAll(Colors.transparent),
      elevation: WidgetStatePropertyAll(0),
    );

    return StatefulBuilder(
      builder: (context, setState) {
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
                style: Theme.of(
                  context,
                ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const MenuSubsectionTitle(title: "Cycle Configuration"),
              SwitchListTile(
                title: const Text("Auto-start Break"),
                subtitle: const Text("Start break when focus ends"),
                value: timerProvider.autoStartBreak,
                onChanged: (val) {
                  timerProvider.setAutoStartBreak(val);
                  setState(() {});
                },
                activeThumbColor: accentColor,
              ),
              SwitchListTile(
                title: const Text("Auto-start Focus"),
                subtitle: const Text("Start focus when break ends"),
                value: timerProvider.autoStartFocus,
                onChanged: (val) {
                  timerProvider.setAutoStartFocus(val);
                  setState(() {});
                },
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
                      onPressed: () {
                        if (timerProvider.targetLoops > 1) {
                          timerProvider.setTargetLoops(
                            timerProvider.targetLoops - 1,
                          );
                          setState(() {});
                        }
                      },
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
                      onPressed: () {
                        timerProvider.setTargetLoops(
                          timerProvider.targetLoops + 1,
                        );
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const MenuSubsectionTitle(title: "Sound"),
              DropdownButtonFormField<SoundType>(
                initialValue: timerProvider.selectedSound,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: SoundType.values.map((s) {
                  String label = s.toString().split('.').last.toUpperCase();
                  if (s == SoundType.custom &&
                      timerProvider.customSoundPath != null) {
                    final fileName = timerProvider.customSoundPath!
                        .split('/')
                        .last;
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
                      timerProvider.setCustomSoundPath(
                        result.files.single.path!,
                      );
                      timerProvider.setSelectedSound(SoundType.custom);
                    }
                  } else {
                    timerProvider.setSelectedSound(val);
                  }
                  setState(() {});
                },
              ),
              SwitchListTile(
                title: const Text("Play Default Notification Sound"),
                subtitle: const Text(
                  "Play the system sound with the notification",
                ),
                value: timerProvider.playDefaultSound,
                onChanged: (val) {
                  timerProvider.setPlayDefaultSound(val);
                  setState(() {});
                },
                activeThumbColor: accentColor,
              ),
              const SizedBox(height: 16),
              const MenuSubsectionTitle(title: "Session"),
              SwitchListTile(
                title: const Text("Auto-name Sessions"),
                subtitle: const Text(
                  "Automatically name sessions with date/time",
                ),
                value: timerProvider.autoNameSessions,
                onChanged: (val) {
                  timerProvider.setAutoNameSessions(val);
                  setState(() {});
                },
                activeThumbColor: accentColor,
              ),
              const SizedBox(height: 16),
              const MenuSubsectionTitle(title: "Controls"),
              SwitchListTile(
                title: const Text("Auto-hide Controls"),
                subtitle: const Text("Hide controls when timer is running"),
                value: timerProvider.autoHideControls,
                onChanged: (val) {
                  timerProvider.setAutoHideControls(val);
                  setState(() {});
                },
                activeThumbColor: accentColor,
              ),
              const SizedBox(height: 16),
              const MenuSubsectionTitle(title: "Visuals"),
              SwitchListTile(
                title: const Text("Show Background Liquid"),
                value: timerProvider.showBackgroundLiquid,
                onChanged: (val) {
                  timerProvider.setShowBackgroundLiquid(val);
                  setState(() {});
                },
                activeThumbColor: accentColor,
              ),
              SwitchListTile(
                title: const Text("Show Circle Liquid"),
                value: timerProvider.showInnerLiquid,
                onChanged: (val) {
                  timerProvider.setShowInnerLiquid(val);
                  setState(() {});
                },
                activeThumbColor: accentColor,
              ),
              const SizedBox(height: 10),
              Text(
                "Set Max Scale of Timer",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ScaleChip(
                    seconds: 900,
                    label: "15m",
                    isSelected: timerProvider.fixedScaleDuration == 900,
                    onSelected: () {
                      timerProvider.setFixedScaleDuration(900);
                      setState(() {});
                    },
                  ),
                  ScaleChip(
                    seconds: 1500,
                    label: "25m",
                    isSelected: timerProvider.fixedScaleDuration == 1500,
                    onSelected: () {
                      timerProvider.setFixedScaleDuration(1500);
                      setState(() {});
                    },
                  ),
                  ScaleChip(
                    seconds: 1800,
                    label: "30m",
                    isSelected: timerProvider.fixedScaleDuration == 1800,
                    onSelected: () {
                      timerProvider.setFixedScaleDuration(1800);
                      setState(() {});
                    },
                  ),
                  ScaleChip(
                    seconds: 3600,
                    label: "60m",
                    isSelected: timerProvider.fixedScaleDuration == 3600,
                    onSelected: () {
                      timerProvider.setFixedScaleDuration(3600);
                      setState(() {});
                    },
                  ),
                  ActionChip(
                    label: const Text("Custom Scale"),
                    onPressed: () {
                      _showCustomScalePicker(
                        context,
                        timerProvider,
                        accentColor,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
      headerDecoration: BoxDecoration(),
      confirmText: "Set Scale",
      textStyle: theme.textTheme.bodyMedium!.copyWith(
        fontWeight: FontWeight.bold,
      ),
      confirmTextStyle: theme.textTheme.titleMedium!.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
      cancelTextStyle: theme.textTheme.titleMedium!.copyWith(
        color: Theme.of(context).disabledColor,
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
        final data = picker.getSelectedValues();
        final mins = data[0] as int;
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
