import 'loop.dart';

class Session {
  final String id;
  final String userId;
  final String name;
  final int targetLoops;
  final List<Loop> loops;
  final int currentLoopIndex;
  final DateTime startTime;
  final DateTime? endTime;
  final String? presetName;
  final String? label;
  final String? progressNote;
  final bool completed;

  Session({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetLoops,
    required this.startTime,
    this.loops = const [],
    this.currentLoopIndex = 0,
    this.endTime,
    this.presetName,
    this.label,
    this.progressNote,
    this.completed = false,
  });

  // Calculate total duration from all completed loops
  int get totalDuration {
    return loops
        .where((loop) => loop.completed)
        .fold<int>(0, (sum, loop) => sum + loop.duration);
  }

  // Calculate focus duration from completed focus loops
  int get focusDuration {
    return loops
        .where(
          (loop) => loop.completed && loop.type.toString().contains('focus'),
        )
        .fold<int>(0, (sum, loop) => sum + loop.duration);
  }

  // Calculate break duration from completed break loops
  int get breakDuration {
    return loops
        .where(
          (loop) => loop.completed && loop.type.toString().contains('break'),
        )
        .fold<int>(0, (sum, loop) => sum + loop.duration);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'target_loops': targetLoops,
    'loops': loops.map((loop) => loop.toJson()).toList(),
    'current_loop_index': currentLoopIndex,
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
    name: json['name'],
    targetLoops: json['target_loops'],
    loops:
        (json['loops'] as List<dynamic>?)
            ?.map((loopJson) => Loop.fromJson(loopJson))
            .toList() ??
        [],
    currentLoopIndex: json['current_loop_index'] ?? 0,
    startTime: DateTime.parse(json['start_time']),
    endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
    presetName: json['preset_name'],
    label: json['label'],
    progressNote: json['progress_note'],
    completed: json['completed'] ?? false,
  );

  Session copyWith({
    String? name,
    List<Loop>? loops,
    int? currentLoopIndex,
    String? label,
    String? progressNote,
    DateTime? endTime,
    bool? completed,
  }) {
    return Session(
      id: id,
      userId: userId,
      name: name ?? this.name,
      targetLoops: targetLoops,
      loops: loops ?? this.loops,
      currentLoopIndex: currentLoopIndex ?? this.currentLoopIndex,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      presetName: presetName,
      label: label ?? this.label,
      progressNote: progressNote ?? this.progressNote,
      completed: completed ?? this.completed,
    );
  }
}
