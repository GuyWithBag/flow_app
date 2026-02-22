import 'dart:math' as math;

import 'package:flow_app/painters/painters.barrel.dart';
import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flow_app/widgets/widgets.barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_picker_plus/flutter_picker_plus.dart';
import 'package:provider/provider.dart';

class LiquidTimerCircle extends HookWidget {
  final Color color;
  final int maxDuration;
  final double fillPercent;
  final AnimationController waveController;
  final ValueNotifier<bool> isDragging;
  final bool isDark;
  final double contrast;
  final int animDuration;
  final Curve animCurve;
  final bool showInnerLiquid;
  final bool controlsVisible;
  final VoidCallback onCircleTap;

  const LiquidTimerCircle({
    super.key,
    required this.color,
    required this.maxDuration,
    required this.fillPercent,
    required this.waveController,
    required this.isDragging,
    required this.isDark,
    required this.contrast,
    required this.animDuration,
    required this.animCurve,
    required this.showInnerLiquid,
    required this.controlsVisible,
    required this.onCircleTap,
  });

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = math.min(constraints.maxWidth, constraints.maxHeight);
        final size = available.clamp(180.0, 360.0);
        final center = Offset(size / 2, size / 2);
        final innerZoneRadius = (size / 2) - (size * 0.16);

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
                  _showTimePicker(context, timerProvider);
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
                          color: color.withValues(alpha: isDark ? 0.2 : 0.3),
                          blurRadius: currentBlur,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),

                  // 2. INNER LIQUID
                  if (showInnerLiquid)
                    ClipOval(
                      child: SizedBox(
                        width: size - 10,
                        height: size - 10,
                        child: AnimatedBuilder(
                          animation: waveController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: LiquidWavePainter(
                                waveValue: waveController.value,
                                fillPercent: animatedProgress,
                                color: color.withValues(alpha: contrast),
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
                        strokeWidth: size * 0.086,
                        knobRadius: size * 0.05,
                      ),
                    ),
                  ),

                  // 4. Text Content
                  TimerCircleContent(
                    formattedTime: timerProvider.formattedTime,
                    isRunning: timerProvider.isRunning,
                    controlsVisible: controlsVisible,
                    isDark: isDark,
                  ),
                ],
              ),
            );
          },
        );
      },
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

  void _showTimePicker(BuildContext context, TimerProvider timerProvider) {
    if (timerProvider.isRunning) return;

    final totalSeconds = timerProvider.remainingSeconds;
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;

    final theme = Theme.of(context);

    final picker = Picker(
      headerDecoration: BoxDecoration(),
      textStyle: theme.textTheme.bodyMedium!.copyWith(
        fontWeight: FontWeight.bold,
      ),
      confirmText: "Set Time",
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
      title: const Text("Timer Duration"),
      onConfirm: (Picker picker, List<int> values) {
        final data = picker.getSelectedValues();
        final hours = data[0] as int;
        final mins = data[1] as int;
        final secs = data[2] as int;

        final newTotal = (hours * 3600) + (mins * 60) + secs;
        timerProvider.setCustomDuration(newTotal);
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
