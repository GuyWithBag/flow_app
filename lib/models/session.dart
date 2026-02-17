import 'timer_type.dart';

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
