import 'package:flutter/material.dart';

enum TimerType { focus, breakTime }

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

class PomodoroPreset {
  final String id;
  final String name;
  final int focusDuration;
  final int breakDuration;
  final int longFocusDuration;
  final int longBreakDuration;
  final int cyclesBeforeLongBreak;

  PomodoroPreset({
    required this.id,
    required this.name,
    required this.focusDuration,
    required this.breakDuration,
    required this.longFocusDuration,
    required this.longBreakDuration,
    this.cyclesBeforeLongBreak = 4,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'focus_duration': focusDuration,
    'break_duration': breakDuration,
    'long_focus_duration': longFocusDuration,
    'long_break_duration': longBreakDuration,
    'cycles_before_long_break': cyclesBeforeLongBreak,
  };

  factory PomodoroPreset.fromJson(Map<String, dynamic> json) => PomodoroPreset(
    id: json['id'],
    name: json['name'],
    focusDuration: json['focus_duration'],
    breakDuration: json['break_duration'],
    longFocusDuration: json['long_focus_duration'],
    longBreakDuration: json['long_break_duration'],
    cyclesBeforeLongBreak: json['cycles_before_long_break'] ?? 4,
  );
}

class Session {
  final String id;
  final String userId;
  final TimerType type;
  final int duration;
  final DateTime startTime;
  final DateTime? endTime;
  final String? presetName;
  final String? label;
  final String? progressNote;
  final bool completed;

  Session({
    required this.id,
    required this.userId,
    required this.type,
    required this.duration,
    required this.startTime,
    this.endTime,
    this.presetName,
    this.label,
    this.progressNote,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'type': type.toString(),
    'duration': duration,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime?.toIso8601String(),
    'preset_name': presetName,
    'label': label,
    'progress_note': progressNote,
    'completed': completed,
  };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    id: json['id'],
    userId: json['user_id'],
    type: json['type'].toString().contains('focus')
        ? TimerType.focus
        : TimerType.breakTime,
    duration: json['duration'],
    startTime: DateTime.parse(json['start_time']),
    endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
    presetName: json['preset_name'],
    label: json['label'],
    progressNote: json['progress_note'],
    completed: json['completed'] ?? false,
  );

  Session copyWith({
    String? label,
    String? progressNote,
    DateTime? endTime,
    bool? completed,
  }) {
    return Session(
      id: id,
      userId: userId,
      type: type,
      duration: duration,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      presetName: presetName,
      label: label ?? this.label,
      progressNote: progressNote ?? this.progressNote,
      completed: completed ?? this.completed,
    );
  }
}

class UserProfile {
  final String id;
  final String email;
  final String? name;
  final int dailyGoal; // in minutes
  final int streak;

  UserProfile({
    required this.id,
    required this.email,
    this.name,
    this.dailyGoal = 120,
    this.streak = 0,
  });
}
