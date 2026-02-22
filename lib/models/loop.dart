import 'timer_type.dart';

class Loop {
  final String id;
  final TimerType type;
  final int duration;
  final DateTime startTime;
  final DateTime? endTime;
  final bool completed;
  final bool skipped;

  Loop({
    required this.id,
    required this.type,
    required this.duration,
    required this.startTime,
    this.endTime,
    this.completed = false,
    this.skipped = false,
  });

  Loop copyWith({DateTime? endTime, bool? completed, bool? skipped}) {
    return Loop(
      id: id,
      type: type,
      duration: duration,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      completed: completed ?? this.completed,
      skipped: skipped ?? this.skipped,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'duration': duration,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime?.toIso8601String(),
    'completed': completed,
    'skipped': skipped,
  };

  factory Loop.fromJson(Map<String, dynamic> json) => Loop(
    id: json['id'],
    type: json['type'].toString().contains('focus')
        ? TimerType.focus
        : TimerType.breakTime,
    duration: json['duration'],
    startTime: DateTime.parse(json['start_time']),
    endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
    completed: json['completed'] ?? false,
    skipped: json['skipped'] ?? false,
  );
}
