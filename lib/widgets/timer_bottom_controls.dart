import 'package:flow_app/models/models.barrel.dart';
import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flow_app/shared/enums/enums.barrel.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_picker_plus/flutter_picker_plus.dart';

class TimerBottomControls extends StatelessWidget {
  const TimerBottomControls({
    super.key,
    required this.controlsVisible,
    required this.isDark,
    required this.timerProvider,
    required this.presetProvider,
    required this.sessionProvider,
    required this.currentColor,
  });

  final ValueNotifier<bool> controlsVisible;
  final bool isDark;
  final TimerProvider timerProvider;
  final PresetProvider presetProvider;
  final SessionProvider sessionProvider;
  final Color currentColor;

  @override
  Widget build(BuildContext context) {
    void _resetLoop() {
      timerProvider.resetLoop();
      timerProvider.resetTimer();
      sessionProvider.clearCurrentSession();
    }

    void _finishSession() {
      sessionProvider.completeCurrentSession();
      timerProvider.resetLoop();
      timerProvider.resetTimer();
      sessionProvider.clearCurrentSession();
    }

    void _skipCycle() {
      sessionProvider.clearCurrentSession();
      timerProvider.resetTimer();
      if (timerProvider.currentType == TimerType.focus) {
        // Skip focus → go to break
        timerProvider.setTimerType(TimerType.breakTime);
      } else {
        // Skip break → go to focus, increment loop
        timerProvider.incrementLoop();
        timerProvider.setTimerType(TimerType.focus);
      }
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final isCompact = screenHeight < 700;
    final btnSize = isCompact ? 36.0 : 48.0;
    final iconSize = isCompact ? 20.0 : 24.0;

    final filledFlatButton = IconButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      foregroundColor: Theme.of(context).colorScheme.inverseSurface,
      minimumSize: Size(btnSize, btnSize),
      maximumSize: Size(btnSize, btnSize),
      iconSize: iconSize,
    );

    return AnimatedSlide(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      offset: controlsVisible.value ? Offset.zero : const Offset(0, 2.0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: controlsVisible.value ? 1.0 : 0.0,
        child: Row(
          children: [
            // Reset button
            BouncingButton(
              child: IconButton(
                onPressed: _resetLoop,
                icon: const Icon(Icons.refresh),
                style: filledFlatButton,
              ),
            ),
            const Spacer(flex: 3),
            // Finish button
            BouncingButton(
              child: IconButton.filled(
                onPressed: _finishSession,
                icon: const Icon(Icons.stop),
                style: filledFlatButton,
              ),
            ),
            const Spacer(flex: 1),
            // Play/Pause button
            BouncingButton(child: PlayPauseButton()),
            const Spacer(flex: 1),
            // Skip button
            BouncingButton(
              child: IconButton(
                onPressed: _skipCycle,
                icon: const Icon(Icons.skip_next),
                style: filledFlatButton,
              ),
            ),
            const Spacer(flex: 3),
            // Settings button
            BouncingButton(
              child: IconButton(
                onPressed: () {
                  _showSettingsSheet(context, timerProvider, isDark);
                },
                icon: const Icon(Icons.tune),
                style: filledFlatButton,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SETTINGS SHEET ---
  void _showSettingsSheet(
    BuildContext context,
    TimerProvider timerProvider,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Timer Settings",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SettingsSectionHeader(title: "Cycle Configuration"),
                    SwitchListTile(
                      title: const Text("Auto-start Break"),
                      subtitle: const Text("Start break when focus ends"),
                      value: timerProvider.autoStartBreak,
                      onChanged: (val) {
                        timerProvider.setAutoStartBreak(val);
                        setState(() {});
                      },
                      activeColor: Colors.blue,
                    ),
                    SwitchListTile(
                      title: const Text("Auto-start Focus"),
                      subtitle: const Text("Start focus when break ends"),
                      value: timerProvider.autoStartFocus,
                      onChanged: (val) {
                        timerProvider.setAutoStartFocus(val);
                        setState(() {});
                      },
                      activeColor: Colors.blue,
                    ),
                    ListTile(
                      title: const Text("Total Loops"),
                      subtitle: Text(
                        "${timerProvider.targetLoops} Focus Sessions",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
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
                    const Divider(),
                    const SettingsSectionHeader(title: "Sound"),
                    DropdownButtonFormField<SoundType>(
                      value: timerProvider.selectedSound,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: SoundType.values.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(
                            s.toString().split('.').last.toUpperCase(),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          timerProvider.setSelectedSound(val);
                          setState(() {});
                        }
                      },
                    ),
                    const Divider(),
                    const SettingsSectionHeader(title: "Visuals"),
                    SwitchListTile(
                      title: const Text("Show Background Liquid"),
                      value: timerProvider.showBackgroundLiquid,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        timerProvider.setShowBackgroundLiquid(val);
                        setState(() {});
                      },
                    ),
                    SwitchListTile(
                      title: const Text("Show Circle Liquid"),
                      value: timerProvider.showInnerLiquid,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        timerProvider.setShowInnerLiquid(val);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Set Max Scale of Timer",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
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
                            Navigator.pop(context);
                            _showCustomScalePicker(
                              context,
                              timerProvider,
                              isDark,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCustomScalePicker(
    BuildContext context,
    TimerProvider timerProvider,
    bool isDark,
  ) {
    final currentMins = (timerProvider.fixedScaleDuration / 60).round();
    Picker(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      headerColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
      textStyle: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 20,
      ),
      confirmText: "Set Scale",
      confirmTextStyle: const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.bold,
      ),
      cancelTextStyle: TextStyle(color: isDark ? Colors.grey : Colors.black54),
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
    ).showModal(
      context,
      builder: (context, pickerWidget) => SafeArea(child: pickerWidget),
    );
  }
}
