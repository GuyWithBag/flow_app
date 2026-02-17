import 'dart:async';
import 'dart:developer';
import 'package:flow_app/models/models.barrel.dart';
import 'package:flow_app/painters/painters.barrel.dart';
import 'package:flow_app/providers/providers.dart';
import 'package:flow_app/shared/enums/enums.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:flutter_picker_plus/flutter_picker_plus.dart';

// TODO: Make long focus and break toggleable
// TODO: Refactor all of the code so that you are able to separate them into their own files

class TimerScreen extends HookWidget {
  const TimerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final sessionProvider = Provider.of<SessionProvider>(context);
    final presetProvider = Provider.of<PresetProvider>(context);

    // --- RUNTIME STATE (not persisted) ---
    final playbackTotalDuration = useRef(timerProvider.remainingSeconds);
    final isDragging = useState(false);
    final controlsVisible = useState(true);
    final autoHideTimer = useRef<Timer?>(null);

    // Track previous running state to detect completion edge case
    final wasRunning = useRef(false);

    // --- LOGIC: HELPER FUNCTIONS ---

    void toggleControls() {
      if (controlsVisible.value) {
        controlsVisible.value = false;
        autoHideTimer.value?.cancel();
      } else {
        controlsVisible.value = true;
        autoHideTimer.value?.cancel();
        // Auto-hide again after 3 seconds if running
        autoHideTimer.value = Timer(const Duration(seconds: 3), () {
          if (timerProvider.isRunning) {
            controlsVisible.value = false;
          }
        });
      }
    }

    void _resetLoop() {
      timerProvider.resetLoop();
      timerProvider.resetTimer();
      sessionProvider.clearCurrentSession();
    }

    void _handleSessionComplete(BuildContext ctx) {
      // Play Sound (Placeholder for AudioPlayer logic)
      log("Playing Sound: ${timerProvider.selectedSound}");

      if (timerProvider.currentType == TimerType.focus) {
        // Focus Finished
        if (timerProvider.currentLoop >= timerProvider.targetLoops) {
          // All Loops Done
          showDialog(
            context: ctx,
            builder: (_) => AlertDialog(
              title: const Text("Great Flow!"),
              content: Text(
                "You completed ${timerProvider.targetLoops} sessions.",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _resetLoop();
                    Navigator.pop(ctx);
                  },
                  child: const Text("Finish"),
                ),
              ],
            ),
          );
          timerProvider.resetLoop();
        } else {
          // Start Break
          timerProvider.setTimerType(TimerType.breakTime);
          themeProvider.setModeAccentColor(
            ctx,
            TimerType.breakTime,
            themeProvider.getAccentColorFor(TimerType.breakTime),
          );

          if (timerProvider.autoStartBreak) {
            final preset = presetProvider.selectedPreset;
            sessionProvider.startSession(
              userId: 'current_user',
              type: TimerType.breakTime,
              duration: preset?.breakDuration ?? 300,
              presetName: preset?.name,
            );
            timerProvider.startTimer();
          }
        }
      } else {
        // Break Finished
        timerProvider.incrementLoop();
        timerProvider.setTimerType(TimerType.focus);
        themeProvider.setModeAccentColor(
          ctx,
          TimerType.focus,
          themeProvider.getAccentColorFor(TimerType.focus),
        );

        if (timerProvider.autoStartFocus) {
          final preset = presetProvider.selectedPreset;
          sessionProvider.startSession(
            userId: 'current_user',
            type: TimerType.focus,
            duration: preset?.focusDuration ?? 1500,
            presetName: preset?.name,
          );
          timerProvider.startTimer();
        }
      }
    }

    // --- EFFECT: WATCH TIMER COMPLETION ---
    useEffect(() {
      if (wasRunning.value &&
          !timerProvider.isRunning &&
          timerProvider.remainingSeconds == 0) {
        sessionProvider.completeCurrentSession();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleSessionComplete(context);
        });
      }
      wasRunning.value = timerProvider.isRunning;
      return null;
    }, [timerProvider.isRunning, timerProvider.remainingSeconds]);

    // --- EFFECT: AUTO-HIDE CONTROLS ---
    useEffect(() {
      if (timerProvider.isRunning) {
        playbackTotalDuration.value = timerProvider.remainingSeconds;
        controlsVisible.value = false;
      } else {
        controlsVisible.value = true;
        autoHideTimer.value?.cancel();
      }
      return null;
    }, [timerProvider.isRunning]);

    // Animation Controller
    final waveController = useAnimationController(
      duration: const Duration(seconds: 2),
    )..repeat();

    // Colors
    final isDark = themeProvider.isDarkMode;
    final focusColor = themeProvider.getAccentColorFor(TimerType.focus);
    final breakColor = themeProvider.getAccentColorFor(TimerType.breakTime);
    final currentColor = timerProvider.currentType == TimerType.focus
        ? focusColor
        : breakColor;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    // Progress Calculation
    int currentMaxDuration;
    if (timerProvider.isRunning && timerProvider.useDynamicScale) {
      currentMaxDuration = playbackTotalDuration.value > 0
          ? playbackTotalDuration.value
          : 1;
    } else {
      currentMaxDuration = timerProvider.fixedScaleDuration;
    }
    double fillPercent = timerProvider.remainingSeconds / currentMaxDuration;
    fillPercent = fillPercent.clamp(0.0, 1.0);

    final int animDuration = isDragging.value
        ? 100
        : (timerProvider.isRunning ? 1000 : 800);
    final Curve animCurve = isDragging.value
        ? Curves.easeOut
        : (timerProvider.isRunning ? Curves.linear : Curves.easeOutCubic);

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. BACKGROUND LIQUID
          if (timerProvider.showBackgroundLiquid)
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: fillPercent),
                duration: Duration(milliseconds: animDuration),
                curve: animCurve,
                builder: (context, animatedBgFill, child) {
                  return AnimatedBuilder(
                    animation: waveController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: LiquidWavePainter(
                          waveValue: waveController.value,
                          fillPercent: animatedBgFill,
                          color: currentColor.withOpacity(
                            (timerProvider.waveContrast - 0.2 <= 0)
                                ? 0.1
                                : timerProvider.waveContrast - 0.2,
                          ),
                          waveHeight: 25.0,
                          waveFrequency: 1.2,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

          // 2. MAIN CONTENT
          SafeArea(
            child: Column(
              children: [
                // TOP CONTROLS
                AnimatedSlide(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutCubic,
                  offset: controlsVisible.value
                      ? Offset.zero
                      : const Offset(0, -2.0),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: controlsVisible.value ? 1.0 : 0.0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Flow',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                              // Preset Label and Loop Indicator
                              Row(
                                children: [
                                  // Preset Label
                                  if (presetProvider.selectedPreset != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: currentColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: currentColor.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        presetProvider.selectedPreset!.name,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  // Loop Indicator
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: currentColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "Loop ${timerProvider.currentLoop} / ${timerProvider.targetLoops}",
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        ModeToggle(
                          focusColor: focusColor,
                          breakColor: breakColor,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        // Long Duration Buttons
                        if (presetProvider.selectedPreset != null)
                          LongDurationButton(
                            focusColor: focusColor,
                            breakColor: breakColor,
                            isDark: isDark,
                          ),
                        const SizedBox(height: 10),
                        // Preset Selection Button
                        PresetSelector(isDark: isDark),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // TIMER CIRCLE
                Expanded(
                  child: Center(
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutCubic,
                      scale: controlsVisible.value ? 1.0 : 1.15,
                      child: LiquidTimerCircle(
                        color: currentColor,
                        maxDuration: currentMaxDuration,
                        fillPercent: fillPercent,
                        waveController: waveController,
                        isDragging: isDragging,
                        isDark: isDark,
                        contrast: timerProvider.waveContrast,
                        animDuration: animDuration,
                        animCurve: animCurve,
                        showInnerLiquid: timerProvider.showInnerLiquid,
                        controlsVisible: controlsVisible.value,
                        onCircleTap: toggleControls,
                      ),
                    ),
                  ),
                ),

                // BOTTOM CONTROLS
                AnimatedSlide(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutCubic,
                  offset: controlsVisible.value
                      ? Offset.zero
                      : const Offset(0, 2.0),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: controlsVisible.value ? 1.0 : 0.0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 40,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          BouncingButton(
                            onTap: _resetLoop,
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                              child: Icon(
                                Icons.refresh,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          BouncingButton(
                            onTap: () {
                              if (timerProvider.isRunning) {
                                timerProvider.pauseTimer();
                              } else {
                                final preset = presetProvider.selectedPreset;
                                sessionProvider.startSession(
                                  userId: 'current_user',
                                  type: timerProvider.currentType,
                                  duration: timerProvider.totalSeconds,
                                  presetName: preset?.name,
                                );
                                timerProvider.startTimer();
                              }
                            },
                            child: PlayPauseButton(color: currentColor),
                          ),
                          BouncingButton(
                            onTap: () => _showSettingsSheet(
                              context,
                              timerProvider,
                              isDark,
                            ),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                              child: Icon(
                                Icons.tune,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
