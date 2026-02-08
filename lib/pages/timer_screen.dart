import 'dart:async';
import 'dart:math' as math;
import 'package:flow_app/models/models.dart';
import 'package:flow_app/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:flutter_picker_plus/flutter_picker_plus.dart';

// --- ENUMS & CONSTANTS ---
enum SoundType { bell, digital, bird, none }

class TimerScreen extends HookWidget {
  const TimerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    // --- CONFIGURATION STATE (Ideally saved to Preferences in a real app) ---
    final fixedScaleDuration = useState(60 * 60);
    final useDynamicScale = useState(false);
    final waveContrast = useState(0.8);

    // Cycle & Loop Settings
    final autoStartBreak = useState(true);
    final autoStartFocus = useState(false);
    final targetLoops = useState(
      4,
    ); // How many Focus sessions before big finish
    final currentLoop = useState(1);
    final selectedSound = useState(SoundType.bell);

    // Visibility Toggles
    final showInnerLiquid = useState(true);
    final showBackgroundLiquid = useState(true);

    // --- RUNTIME STATE ---
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
      currentLoop.value = 1;
      timerProvider.resetTimer();
    }

    void _handleSessionComplete(BuildContext ctx) {
      // Play Sound (Placeholder for AudioPlayer logic)
      print("Playing Sound: ${selectedSound.value}");

      if (timerProvider.currentType == TimerType.focus) {
        // Focus Finished
        if (currentLoop.value >= targetLoops.value) {
          // All Loops Done
          showDialog(
            context: ctx,
            builder: (_) => AlertDialog(
              title: const Text("Great Flow!"),
              content: Text("You completed ${targetLoops.value} sessions."),
              actions: [
                TextButton(
                  onPressed: () {
                    _resetLoop(); // Reset loops
                    Navigator.pop(ctx);
                  },
                  child: const Text("Finish"),
                ),
              ],
            ),
          );
          currentLoop.value = 1;
        } else {
          // Start Break
          timerProvider.setTimerType(TimerType.breakTime);
          // Set color theme
          themeProvider.setModeAccentColor(
            ctx,
            TimerType.breakTime,
            themeProvider.getAccentColorFor(TimerType.breakTime),
          );

          if (autoStartBreak.value) {
            timerProvider.startTimer();
          }
        }
      } else {
        // Break Finished
        currentLoop.value += 1; // Increment loop count
        timerProvider.setTimerType(TimerType.focus);
        // Set color theme
        themeProvider.setModeAccentColor(
          ctx,
          TimerType.focus,
          themeProvider.getAccentColorFor(TimerType.focus),
        );

        if (autoStartFocus.value) {
          timerProvider.startTimer();
        }
      }
    }

    // --- EFFECT: WATCH TIMER COMPLETION ---
    useEffect(() {
      // Check if we transitioned from running to 0 seconds
      if (wasRunning.value &&
          !timerProvider.isRunning &&
          timerProvider.remainingSeconds == 0) {
        // We need a slight delay to ensure the provider state is settled
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
    if (timerProvider.isRunning && useDynamicScale.value) {
      currentMaxDuration = playbackTotalDuration.value > 0
          ? playbackTotalDuration.value
          : 1;
    } else {
      currentMaxDuration = fixedScaleDuration.value;
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
          if (showBackgroundLiquid.value)
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
                            (waveContrast.value - 0.2 <= 0)
                                ? 0.1
                                : waveContrast.value - 0.2,
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
                                  "Loop ${currentLoop.value} / ${targetLoops.value}",
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
                        ),
                        const SizedBox(height: 10),
                        _buildModeToggle(
                          context,
                          timerProvider,
                          focusColor,
                          breakColor,
                          isDark,
                        ),
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
                      child: _buildLiquidTimerCircle(
                        context: context,
                        timerProvider: timerProvider,
                        color: currentColor,
                        maxDuration: currentMaxDuration,
                        fillPercent: fillPercent,
                        waveController: waveController,
                        isDragging: isDragging,
                        isDark: isDark,
                        contrast: waveContrast.value,
                        animDuration: animDuration,
                        animCurve: animCurve,
                        showInnerLiquid: showInnerLiquid.value,
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
                                timerProvider.startTimer();
                              }
                            },
                            child: _buildPlayPauseButton(
                              context,
                              timerProvider,
                              currentColor,
                            ),
                          ),

                          BouncingButton(
                            onTap: () => _showSettingsSheet(
                              context,
                              fixedScaleDuration,
                              useDynamicScale,
                              waveContrast,
                              showInnerLiquid,
                              showBackgroundLiquid,
                              autoStartBreak,
                              autoStartFocus,
                              targetLoops,
                              selectedSound,
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

  Widget _buildLiquidTimerCircle({
    required BuildContext context,
    required TimerProvider timerProvider,
    required Color color,
    required int maxDuration,
    required double fillPercent,
    required AnimationController waveController,
    required ValueNotifier<bool> isDragging,
    required bool isDark,
    required double contrast,
    required int animDuration,
    required Curve animCurve,
    required bool showInnerLiquid,
    required bool controlsVisible,
    required VoidCallback onCircleTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = 280.0;
        final center = Offset(size / 2, size / 2);
        final innerZoneRadius = (size / 2) - 45.0;

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: fillPercent),
          duration: Duration(milliseconds: animDuration),
          curve: animCurve,
          builder: (context, animatedProgress, child) {
            final double currentBlur = 10.0 + (30.0 * animatedProgress);

            return GestureDetector(
              onPanUpdate: (details) {
                if (timerProvider.isRunning) return;
                _updateTimeFromDrag(
                  details.localPosition,
                  size,
                  timerProvider,
                  maxDuration,
                );
              },
              onPanStart: (details) {
                if (timerProvider.isRunning) return;
                final dist = (details.localPosition - center).distance;
                if (dist >= innerZoneRadius) {
                  isDragging.value = true;
                  HapticFeedback.selectionClick();
                  _updateTimeFromDrag(
                    details.localPosition,
                    size,
                    timerProvider,
                    maxDuration,
                  );
                }
              },
              onPanEnd: (_) => isDragging.value = false,
              onPanCancel: () => isDragging.value = false,

              onTapUp: (details) {
                if (timerProvider.isRunning) {
                  onCircleTap();
                  return;
                }

                final dist = (details.localPosition - center).distance;
                if (dist < innerZoneRadius) {
                  _showTimePicker(context, timerProvider, isDark);
                } else {
                  _updateTimeFromDrag(
                    details.localPosition,
                    size,
                    timerProvider,
                    maxDuration,
                  );
                }
              },

              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Shadow
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.grey.shade900 : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(isDark ? 0.2 : 0.3),
                          blurRadius: currentBlur,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),

                  // 2. INNER LIQUID
                  if (showInnerLiquid)
                    ClipOval(
                      child: Container(
                        width: size - 10,
                        height: size - 10,
                        child: AnimatedBuilder(
                          animation: waveController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: LiquidWavePainter(
                                waveValue: waveController.value,
                                fillPercent: animatedProgress,
                                color: color.withOpacity(contrast),
                                waveHeight: 12.0,
                                waveFrequency: 2.0,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // 3. Ring
                  SizedBox(
                    width: size,
                    height: size,
                    child: CustomPaint(
                      painter: TimerPainter(
                        progress: animatedProgress,
                        color: color,
                        trackColor: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        strokeWidth: 24.0,
                        knobRadius: 14.0,
                      ),
                    ),
                  ),

                  // 4. Text Content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timerProvider.formattedTime,
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Conditional Text Logic
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          key: ValueKey(
                            "${timerProvider.isRunning}-$controlsVisible",
                          ),
                          timerProvider.isRunning
                              ? (controlsVisible
                                    ? "Running"
                                    : "Tap for controls")
                              : "Tap to Edit",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- SETTINGS SHEET ---
  void _showSettingsSheet(
    BuildContext context,
    ValueNotifier<int> fixedScale,
    ValueNotifier<bool> useDynamic,
    ValueNotifier<double> contrast,
    ValueNotifier<bool> showInner,
    ValueNotifier<bool> showBg,
    ValueNotifier<bool> autoBreak,
    ValueNotifier<bool> autoFocus,
    ValueNotifier<int> loops,
    ValueNotifier<SoundType> sound,
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
                    _buildSettingsSectionHeader("Cycle Configuration"),
                    SwitchListTile(
                      title: const Text("Auto-start Break"),
                      subtitle: const Text("Start break when focus ends"),
                      value: autoBreak.value,
                      onChanged: (val) => setState(() => autoBreak.value = val),
                      activeColor: Colors.blue,
                    ),
                    SwitchListTile(
                      title: const Text("Auto-start Focus"),
                      subtitle: const Text("Start focus when break ends"),
                      value: autoFocus.value,
                      onChanged: (val) => setState(() => autoFocus.value = val),
                      activeColor: Colors.blue,
                    ),
                    ListTile(
                      title: const Text("Total Loops"),
                      subtitle: Text("${loops.value} Focus Sessions"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              if (loops.value > 1)
                                setState(() => loops.value--);
                            },
                          ),
                          Text(
                            "${loops.value}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setState(() => loops.value++),
                          ),
                        ],
                      ),
                    ),

                    const Divider(),
                    _buildSettingsSectionHeader("Sound"),
                    DropdownButtonFormField<SoundType>(
                      value: sound.value,
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
                        if (val != null) setState(() => sound.value = val);
                      },
                    ),

                    const Divider(),
                    _buildSettingsSectionHeader("Visuals"),
                    SwitchListTile(
                      title: const Text("Show Circle Liquid"),
                      value: showInner.value,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => showInner.value = val),
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
                        _buildScaleChip(900, "15m", fixedScale, setState),
                        _buildScaleChip(1500, "25m", fixedScale, setState),
                        _buildScaleChip(1800, "30m", fixedScale, setState),
                        _buildScaleChip(3600, "60m", fixedScale, setState),
                        ActionChip(
                          label: const Text("Custom Scale"),
                          onPressed: () {
                            Navigator.pop(context);
                            _showCustomScalePicker(context, fixedScale, isDark);
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

  Widget _buildSettingsSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 5),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  // --- TIME PICKER ---
  void _showTimePicker(
    BuildContext context,
    TimerProvider timerProvider,
    bool isDark,
  ) {
    if (timerProvider.isRunning) return;

    final totalSeconds = timerProvider.remainingSeconds;
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;

    Picker(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      headerColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
      textStyle: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 18,
      ),
      confirmText: "Set Time",
      confirmTextStyle: const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.bold,
      ),
      cancelTextStyle: TextStyle(color: isDark ? Colors.grey : Colors.black54),

      adapter: NumberPickerAdapter(
        data: [
          NumberPickerColumn(
            begin: 0,
            end: 23,
            initValue: h,
            suffix: const Text(" h"),
          ),
          NumberPickerColumn(
            begin: 0,
            end: 59,
            initValue: m,
            suffix: const Text(" m"),
            onFormatValue: (v) => v.toString().padLeft(2, '0'),
          ),
          NumberPickerColumn(
            begin: 0,
            end: 59,
            initValue: s,
            suffix: const Text(" s"),
            onFormatValue: (v) => v.toString().padLeft(2, '0'),
          ),
        ],
      ),
      delimiter: [
        PickerDelimiter(
          column: 1,
          child: Container(
            width: 30.0,
            alignment: Alignment.center,
            child: Text(
              ":",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
        PickerDelimiter(
          column: 3,
          child: Container(
            width: 30.0,
            alignment: Alignment.center,
            child: Text(
              ":",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ],
      title: const Text("Set Timer Duration"),
      onConfirm: (Picker picker, List<int> values) {
        final data = picker.getSelectedValues();
        final hours = data[0] as int;
        final mins = data[1] as int;
        final secs = data[2] as int;

        final newTotal = (hours * 3600) + (mins * 60) + secs;
        timerProvider.setCustomDuration(newTotal);
      },
    ).showModal(
      context,
      builder: (context, pickerWidget) => SafeArea(child: pickerWidget),
    );
  }

  void _showCustomScalePicker(
    BuildContext context,
    ValueNotifier<int> notifier,
    bool isDark,
  ) {
    final currentMins = (notifier.value / 60).round();
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
        notifier.value = mins * 60;
      },
    ).showModal(
      context,
      builder: (context, pickerWidget) => SafeArea(child: pickerWidget),
    );
  }

  void _updateTimeFromDrag(
    Offset localPosition,
    double size,
    TimerProvider provider,
    int maxDuration,
  ) {
    final center = Offset(size / 2, size / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    double angle = math.atan2(dy, dx);
    angle += math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    double percent = angle / (2 * math.pi);
    if (percent > 0.98) percent = 1.0;
    if (percent < 0.01) percent = 0.0;
    int newSeconds = (percent * maxDuration).round();
    provider.setCustomDuration(newSeconds);
  }

  Widget _buildScaleChip(
    int seconds,
    String label,
    ValueNotifier<int> notifier,
    StateSetter setState,
  ) {
    final isSelected = notifier.value == seconds;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() => notifier.value = seconds);
        }
      },
    );
  }

  Widget _buildModeToggle(
    BuildContext context,
    TimerProvider timerProvider,
    Color focusColor,
    Color breakColor,
    bool isDark,
  ) {
    final themeProvider = context.read<ThemeProvider>();
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BouncingButton(
            onTap: () {
              timerProvider.setTimerType(TimerType.focus);
              themeProvider.setModeAccentColor(
                context,
                TimerType.focus,
                focusColor,
              );
            },
            child: _buildModeButtonContent(
              'Focus',
              timerProvider.currentType == TimerType.focus,
              focusColor,
              isDark,
            ),
          ),
          BouncingButton(
            onTap: () {
              timerProvider.setTimerType(TimerType.breakTime);
              themeProvider.setModeAccentColor(
                context,
                TimerType.breakTime,
                breakColor,
              );
            },
            child: _buildModeButtonContent(
              'Break',
              timerProvider.currentType == TimerType.breakTime,
              breakColor,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButtonContent(
    String label,
    bool isSelected,
    Color activeColor,
    bool isDark,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? activeColor : Colors.transparent,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton(
    BuildContext context,
    TimerProvider timerProvider,
    Color color,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(
        timerProvider.isRunning ? Icons.pause : Icons.play_arrow_rounded,
        size: 45,
        color: Colors.white,
      ),
    );
  }
}

// --- BOUNCING BUTTON ANIMATION ---
class BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const BouncingButton({Key? key, required this.child, required this.onTap})
    : super(key: key);

  @override
  State<BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<BouncingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

// Painters
class LiquidWavePainter extends CustomPainter {
  final double waveValue;
  final double fillPercent;
  final Color color;
  final double waveHeight;
  final double waveFrequency;
  LiquidWavePainter({
    required this.waveValue,
    required this.fillPercent,
    required this.color,
    this.waveHeight = 15.0,
    this.waveFrequency = 1.5,
  });
  @override
  void paint(Canvas canvas, Size size) {
    if (fillPercent == 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    final baseHeight = size.height * (1 - fillPercent);
    path.moveTo(0, baseHeight);
    for (double i = 0.0; i <= size.width; i++) {
      path.lineTo(
        i,
        baseHeight +
            math.sin(
                  (i / size.width * 2 * math.pi * waveFrequency) +
                      (waveValue * 2 * math.pi),
                ) *
                waveHeight,
      );
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LiquidWavePainter oldDelegate) =>
      oldDelegate.waveValue != waveValue ||
      oldDelegate.fillPercent != fillPercent ||
      oldDelegate.color != color;
}

class TimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final double knobRadius;
  TimerPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    this.strokeWidth = 20.0,
    this.knobRadius = 15.0,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress;
      const startAngle = -math.pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      final knobAngle = startAngle + sweepAngle;
      final knobCenter = Offset(
        center.dx + radius * math.cos(knobAngle),
        center.dy + radius * math.sin(knobAngle),
      );
      canvas.drawCircle(
        knobCenter,
        knobRadius + 4,
        Paint()..color = Colors.black.withOpacity(0.15),
      );
      canvas.drawCircle(knobCenter, knobRadius, Paint()..color = Colors.white);
      canvas.drawCircle(knobCenter, knobRadius - 4, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant TimerPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}
