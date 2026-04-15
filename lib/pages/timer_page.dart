import 'dart:async';

import 'package:flow_app/models/models.barrel.dart';
import 'package:flow_app/painters/painters.barrel.dart';
import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flow_app/shared/showcase_keys.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart' show ShowcaseView, Showcase;
import 'package:vibration/vibration.dart';

class TimerPage extends HookWidget {
  const TimerPage({super.key});

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

    // --- SHOWCASE REGISTRATION ---
    // Must be synchronous (useMemoized, not useEffect) so the scope exists
    // before Showcase.initState() calls getScope() during the widget mount.
    final showcaseView = useMemoized(ShowcaseView.register);

    // --- EFFECT: START SHOWCASE AFTER ONBOARDING + CLEANUP ---
    useEffect(() {
      final box = Hive.box('settings');
      if (box.get('shouldStartShowcase', defaultValue: false) == true) {
        box.put('shouldStartShowcase', false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controlsVisible.value = true;
          showcaseView.startShowCase(ShowcaseKeys.all);
        });
      }
      return showcaseView.unregister;
    }, const []);

    // --- LOGIC: HELPER FUNCTIONS ---

    void toggleControls() {
      if (controlsVisible.value) {
        controlsVisible.value = false;
        autoHideTimer.value?.cancel();
      } else {
        controlsVisible.value = true;
        autoHideTimer.value?.cancel();
        // Auto-hide again after 3 seconds if running and auto-hide is enabled
        if (timerProvider.autoHideControls) {
          autoHideTimer.value = Timer(const Duration(seconds: 3), () {
            if (timerProvider.isRunning) {
              controlsVisible.value = false;
            }
          });
        }
      }
    }

    void handleSessionComplete(BuildContext ctx) {
      // Vibrate on every loop/session completion
      Vibration.vibrate(duration: 200);

      // Complete the current loop
      sessionProvider.completeCurrentLoop(skipped: false);

      // Use lastCompletedType (not currentType) because the provider may have
      // already auto-switched the timer type in the background.
      final completedType = timerProvider.lastCompletedType;

      if (completedType == TimerType.focus) {
        // Focus Finished
        if (timerProvider.currentLoop >= timerProvider.targetLoops) {
          // All Loops Done — finish session
          sessionProvider.finishSession(ctx);

          Vibration.vibrate(duration: 500);
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
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Text("Great Flow!"),
              content: Text(
                "You completed ${timerProvider.targetLoops} focus sessions!",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    timerProvider.resetLoop();
                    timerProvider.resetTimerToPreset(
                      presetProvider.selectedPreset,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text("Finish"),
                ),
              ],
            ),
          );
        } else {
          // Start Break — update theme and session tracking.
          // If the provider already auto-started the break (timer running),
          // skip the timer calls; just do the session bookkeeping.
          themeProvider.updateTimerType(TimerType.breakTime);
          final preset = presetProvider.selectedPreset;
          sessionProvider.startLoop(
            type: TimerType.breakTime,
            duration: preset.breakDuration,
          );
          if (!timerProvider.isRunning) {
            timerProvider.setTimerType(TimerType.breakTime);
            if (timerProvider.autoStartBreak) {
              timerProvider.startTimer();
            } else {
              showDialog(
                context: ctx,
                barrierDismissible: false,
                builder: (_) => AlertDialog(
                  title: const Text('Focus Complete'),
                  content: const Text('Ready to start your break?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Not Yet'),
                    ),
                    FilledButton(
                      onPressed: () {
                        timerProvider.startTimer();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Start Break'),
                    ),
                  ],
                ),
              );
            }
          }
        }
      } else {
        // Break Finished
        timerProvider.incrementLoop();
        themeProvider.updateTimerType(TimerType.focus);
        final preset = presetProvider.selectedPreset;
        sessionProvider.startLoop(
          type: TimerType.focus,
          duration: preset.focusDuration,
        );
        if (!timerProvider.isRunning) {
          timerProvider.setTimerType(TimerType.focus);
          if (timerProvider.autoStartFocus) {
            timerProvider.startTimer();
          } else {
            showDialog(
              context: ctx,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                title: const Text('Break Complete'),
                content: const Text('Ready to start your focus session?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Not Yet'),
                  ),
                  FilledButton(
                    onPressed: () {
                      timerProvider.startTimer();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Start Focus'),
                  ),
                ],
              ),
            );
          }
        }
      }
    }

    // --- EFFECT: SYNC CONTROLS VISIBILITY TO PROVIDER (for MainPage navbar) ---
    useEffect(() {
      timerProvider.setUiControlsVisible(controlsVisible.value);
      return null;
    }, [controlsVisible.value]);

    // --- EFFECT: WATCH TIMER COMPLETION ---
    // Uses a one-shot event flag instead of checking remainingSeconds == 0,
    // because when autoStartBreak/autoStartFocus is ON the provider has already
    // switched type and restarted the timer before this widget rebuilds,
    // so remainingSeconds is never 0 at rebuild time.
    useEffect(() {
      if (timerProvider.sessionCompletedEvent) {
        timerProvider.consumeSessionCompletedEvent();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          handleSessionComplete(context);
        });
      }
      return null;
    }, [timerProvider.sessionCompletedEvent]);

    // --- EFFECT: AUTO-HIDE CONTROLS ---
    useEffect(() {
      if (timerProvider.isRunning) {
        playbackTotalDuration.value = timerProvider.remainingSeconds;
        if (timerProvider.autoHideControls) {
          controlsVisible.value = false;
        }
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
    final currentColor = Theme.of(context).colorScheme.primary;

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
      backgroundColor: Theme.of(context).cardColor,
      foregroundColor: Theme.of(context).colorScheme.inverseSurface,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. BACKGROUND LIQUID
          if (timerProvider.showBackgroundLiquid)
            Positioned.fill(
              child: RepaintBoundary(
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
            ),

          // 2. MAIN CONTENT
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // TOP CONTROLS
                  Showcase(
                    key: ShowcaseKeys.topControls,
                    title: 'Presets & Loops',
                    description:
                        'Select your Pomodoro preset and set how many focus loops you want to complete.',
                    child: AnimatedVisibility(
                      visible: controlsVisible.value,
                      child: TimerTopControls(
                        timerProvider: timerProvider,
                        showPresetSelector: true,
                      ),
                    ),
                  ),
                  Spacer(),
                  Showcase(
                    key: ShowcaseKeys.modeToggle,
                    title: 'Focus & Break',
                    description:
                        'Switch between focus and break modes. Flow handles transitions automatically when the timer ends.',
                    child: AnimatedVisibility(
                      visible: controlsVisible.value,
                      child: ModeToggle(),
                    ),
                  ),
                  // TIMER CIRCLE
                  Expanded(
                    flex: 6,
                    child: Center(
                      child: Showcase(
                        key: ShowcaseKeys.timerCircle,
                        title: 'Your Timer',
                        description:
                            'Tap the circle to show or hide controls. The liquid fills as your session progresses.',
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOutCubic,
                          scale: controlsVisible.value ? 0.85.w : 0.90.w,
                          child: LiquidTimerCircle(
                            color: currentColor,
                            maxDuration: currentMaxDuration,
                            fillPercent: fillPercent,
                            waveController: waveController,
                            isDragging: isDragging,
                            contrast: timerProvider.waveContrast,
                            animDuration: animDuration,
                            animCurve: animCurve,
                            showInnerLiquid: timerProvider.showInnerLiquid,
                            controlsVisible: controlsVisible.value,
                            hideCircleWithControls:
                                timerProvider.hideCircleWithControls,
                            onCircleTap: toggleControls,
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedVisibility(
                    visible: controlsVisible.value,
                    child: Column(
                      spacing: 8.h,
                      children: [
                        Row(
                          spacing: 10,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const LongDurationButton(),
                            Builder(
                              builder: (context) {
                                final preset = presetProvider.selectedPreset;
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
                                                    presetProvider.updatePreset(
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
                                  icon: const Icon(Icons.edit_note),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  // BOTTOM CONTROLS
                  Showcase(
                    key: ShowcaseKeys.bottomControls,
                    title: 'Timer Controls',
                    description:
                        'Play, pause, skip cycles, stop your session, or open timer settings.',
                    child: AnimatedVisibility(
                      visible: controlsVisible.value,
                      child: TimerBottomControls(
                        timerProvider: timerProvider,
                        presetProvider: presetProvider,
                        sessionProvider: sessionProvider,
                        currentColor: currentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
