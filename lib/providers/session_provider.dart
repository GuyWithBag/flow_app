import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/models.barrel.dart';

class SessionProvider extends ChangeNotifier {
  final List<Session> _sessions = [];
  bool _isLoading = false;
  Session? _currentSession;

  List<Session> get sessions => List.unmodifiable(_sessions);
  bool get isLoading => _isLoading;
  Session? get currentSession => _currentSession;

  Box<Session> get _box => Hive.box<Session>('sessions');

  List<Session> get todaySessions {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _sessions
        .where((s) => s.startTime.isAfter(today) && s.completed)
        .toList();
  }

  int get todayFocusMinutes {
    return todaySessions
        .where((s) => s.type == TimerType.focus)
        .fold<int>(0, (sum, s) => sum + (s.duration ~/ 60));
  }

  int get totalFocusMinutes {
    return _sessions
        .where((s) => s.type == TimerType.focus && s.completed)
        .fold<int>(0, (sum, s) => sum + (s.duration ~/ 60));
  }

  int get todayBreakMinutes {
    return todaySessions
        .where((s) => s.type == TimerType.breakTime)
        .fold<int>(0, (sum, s) => sum + (s.duration ~/ 60));
  }

  int get completedSessionCount {
    return _sessions
        .where((s) => s.type == TimerType.focus && s.completed)
        .length;
  }

  double get averageSessionMinutes {
    final focusSessions = _sessions
        .where((s) => s.type == TimerType.focus && s.completed)
        .toList();
    if (focusSessions.isEmpty) return 0;
    final totalMinutes = focusSessions.fold<int>(
      0,
      (sum, s) => sum + (s.duration ~/ 60),
    );
    return totalMinutes / focusSessions.length;
  }

  Map<DateTime, int> get weeklyFocusMinutes {
    final now = DateTime.now();
    final result = <DateTime, int>{};
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      result[day] = _focusMinutesForDate(day);
    }
    return result;
  }

  Map<DateTime, int> get monthlyFocusMinutes {
    final now = DateTime.now();
    final result = <DateTime, int>{};
    for (int i = 29; i >= 0; i--) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      result[day] = _focusMinutesForDate(day);
    }
    return result;
  }

  Map<String, int> get presetBreakdown {
    final result = <String, int>{};
    for (final s in _sessions.where(
      (s) => s.type == TimerType.focus && s.completed,
    )) {
      final name = s.presetName ?? 'Unknown';
      result[name] = (result[name] ?? 0) + (s.duration ~/ 60);
    }
    return result;
  }

  int currentStreak(int dailyGoalMinutes) {
    final now = DateTime.now();
    int streak = 0;
    // Start from yesterday (today is still in progress)
    for (int i = 1; i <= 365; i++) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      if (_focusMinutesForDate(day) >= dailyGoalMinutes) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int _focusMinutesForDate(DateTime date) {
    final nextDay = date.add(const Duration(days: 1));
    return _sessions
        .where(
          (s) =>
              s.type == TimerType.focus &&
              s.completed &&
              s.startTime.isAfter(date) &&
              s.startTime.isBefore(nextDay),
        )
        .fold<int>(0, (sum, s) => sum + (s.duration ~/ 60));
  }

  void loadSessions() {
    _sessions.clear();
    _sessions.addAll(_box.values);
    notifyListeners();
  }

  Future<void> addSession(Session session) async {
    await _box.put(session.id, session);
    _sessions.insert(0, session);
    notifyListeners();
  }

  Future<void> updateSession(Session session) async {
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      await _box.put(session.id, session);
      _sessions[index] = session;
      notifyListeners();
    }
  }

  // Start a new session (for timer_screen)
  void startSession({
    required String userId,
    required TimerType type,
    required int duration,
    String? presetName,
  }) {
    _currentSession = Session(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: type,
      duration: duration,
      startTime: DateTime.now(),
      presetName: presetName,
    );
    notifyListeners();
  }

  // Complete the current session
  void completeCurrentSession() {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        endTime: DateTime.now(),
        completed: true,
      );
      // Add to sessions list and persist
      _sessions.insert(0, _currentSession!);
      _box.put(_currentSession!.id, _currentSession!);
      // Clear current session
      _currentSession = null;
      notifyListeners();
    }
  }

  // Clear the current session (e.g., on reset)
  void clearCurrentSession() {
    _currentSession = null;
    notifyListeners();
  }
}
