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
