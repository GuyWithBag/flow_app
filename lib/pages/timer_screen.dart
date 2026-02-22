import 'dart:async';
import 'dart:developer';
import 'package:flow_app/models/models.barrel.dart';
import 'package:flow_app/painters/painters.barrel.dart';
import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

class TimerScreen extends HookWidget {
  const TimerScreen({super.key});

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

    void resetLoop() {
      timerProvider.resetLoop();
      timerProvider.resetTimer();
      sessionProvider.clearCurrentSession();
    }

    void handleSessionComplete(BuildContext ctx) {
      // Play Sound (Placeholder for AudioPlayer logic)
      log("Playing Sound: ${timerProvider.selectedSound}");

      if (timerProvider.currentType == TimerType.focus) {
        // Focus Finished
        if (timerProvider.currentLoop >= timerProvider.targetLoops) {
          // All Loops Done — confetti + dialog
          Confetti.launch(
            ctx,
            options: const ConfettiOptions(
              particleCount: 100,
              spread: 70,
              y: 0.6,
            ),
          );
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
                    resetLoop();
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
          handleSessionComplete(context);
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
    final currentColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;

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

    final filledFlatButton = IconButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      foregroundColor: Theme.of(context).colorScheme.inverseSurface,
    );

    final screenHeight = MediaQuery.of(context).size.height;
    final isCompact = screenHeight < 700;

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
                          color: currentColor.withValues(
                            alpha: (timerProvider.waveContrast - 0.2 <= 0)
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
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isCompact ? 8.0 : 12.0),
                    child: Column(
                      spacing: isCompact ? 4 : 10,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // TOP CONTROLS
                        TimerTopControls(
                          controlsVisible: controlsVisible,
                          timerProvider: timerProvider,
                          isDark: isDark,
                        ),

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
                        if (presetProvider.selectedPreset != null)
                          Row(
                            spacing: 10,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const LongDurationButton(),
                              Builder(
                                builder: (context) {
                                  final preset = presetProvider.selectedPreset!;
                                  final isFocus =
                                      timerProvider.currentType ==
                                      TimerType.focus;
                                  final isLongActive =
                                      timerProvider.isLongDuration;
                                  final currentDuration =
                                      timerProvider.totalSeconds;

                                  // Determine which preset duration to compare against
                                  final presetDuration = isFocus
                                      ? (isLongActive
                                            ? preset.longFocusDuration
                                            : preset.focusDuration)
                                      : (isLongActive
                                            ? preset.longBreakDuration
                                            : preset.breakDuration);

                                  final hasChanged =
                                      currentDuration != presetDuration;

                                  if (!hasChanged) {
                                    return const SizedBox.shrink();
                                  }

                                  final durationLabel = isFocus
                                      ? (isLongActive ? 'long focus' : 'focus')
                                      : (isLongActive ? 'long break' : 'break');

                                  return IconButton.filled(
                                    style: filledFlatButton,
                                    onPressed: timerProvider.isRunning
                                        ? null
                                        : () {
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text(
                                                  'Update Preset',
                                                ),
                                                content: Text(
                                                  'Save the current duration as the $durationLabel duration for "${preset.name}"?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(ctx),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      final updated = isFocus
                                                          ? (isLongActive
                                                                ? preset.copyWith(
                                                                    longFocusDuration:
                                                                        currentDuration,
                                                                  )
                                                                : preset.copyWith(
                                                                    focusDuration:
                                                                        currentDuration,
                                                                  ))
                                                          : (isLongActive
                                                                ? preset.copyWith(
                                                                    longBreakDuration:
                                                                        currentDuration,
                                                                  )
                                                                : preset.copyWith(
                                                                    breakDuration:
                                                                        currentDuration,
                                                                  ));
                                                      presetProvider
                                                          .updatePreset(
                                                            updated,
                                                          );
                                                      Navigator.pop(ctx);
                                                    },
                                                    child: const Text('Save'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                    icon: const Icon(Icons.check_rounded),
                                  );
                                },
                              ),
                            ],
                          ),
                        PresetSelector(isDark: isDark),

                        // BOTTOM CONTROLS
                        TimerBottomControls(
                          controlsVisible: controlsVisible,
                          isDark: isDark,
                          timerProvider: timerProvider,
                          presetProvider: presetProvider,
                          sessionProvider: sessionProvider,
                          currentColor: currentColor,
                        ),

                        SizedBox(height: isCompact ? 4 : 10),
                      ],
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
}
