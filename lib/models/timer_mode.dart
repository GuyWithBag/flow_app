import 'package:flutter/material.dart';

import 'timer_type.dart';

class TimerMode {
  final TimerType type;
  final int duration; // in seconds
  final String label;
  final Color primaryColor;
  final Color accentColor;

  TimerMode({
    required this.type,
    required this.duration,
    required this.label,
    required this.primaryColor,
    required this.accentColor,
  });
}
