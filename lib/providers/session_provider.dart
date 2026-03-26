import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/models.barrel.dart';

class SessionProvider extends ChangeNotifier {
  final List<Session> _sessions = [];
  final bool _isLoading = false;
  Session? _currentSession;

  List<Session> get sessions => List.unmodifiable(_sessions);
  bool get isLoading => _isLoading;
  Session? get currentSession => _currentSession;
  bool get isSessionActive => _currentSession != null;
  Loop? get currentLoop {
    if (_currentSession == null) return null;
    if (_currentSession!.loops.isEmpty) return null;
    if (_currentSession!.currentLoopIndex >= _currentSession!.loops.length) {
      return null;
    }
    return _currentSession!.loops[_currentSession!.currentLoopIndex];
  }

  int get completedLoopsCount {
    if (_currentSession == null) return 0;
    return _currentSession!.loops.where((loop) => loop.completed).length;
  }

  Box<Session> get _box => Hive.box<Session>('sessions');

  List<Session> get todaySessions {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _sessions
        .where((s) => s.startTime.isAfter(today) && s.completed)
        .toList();
  }

  int get todayFocusMinutes {
    return todaySessions.fold<int>(
      0,
      (sum, session) => sum + (session.focusDuration ~/ 60),
    );
  }

  int get todayFocusSeconds {
    return todaySessions.fold<int>(
      0,
      (sum, session) => sum + session.focusDuration,
    );
  }

  int get totalFocusMinutes {
    return _sessions
        .where((s) => s.completed)
        .fold<int>(0, (sum, session) => sum + (session.focusDuration ~/ 60));
  }

  int get totalFocusSeconds {
    return _sessions
        .where((s) => s.completed)
        .fold<int>(0, (sum, session) => sum + session.focusDuration);
  }

  int get todayBreakMinutes {
    return todaySessions.fold<int>(
      0,
      (sum, session) => sum + (session.breakDuration ~/ 60),
    );
  }

  int get totalBreakMinutes {
    return _sessions
        .where((s) => s.completed)
        .fold<int>(0, (sum, session) => sum + (session.breakDuration ~/ 60));
  }

  int get totalBreakSeconds {
    return _sessions
        .where((s) => s.completed)
        .fold<int>(0, (sum, session) => sum + session.breakDuration);
  }

  int get completedSessionCount {
    return _sessions.where((s) => s.completed).length;
  }

  double get averageSessionMinutes {
    final completedSessions = _sessions.where((s) => s.completed).toList();
    if (completedSessions.isEmpty) return 0;
    final totalMinutes = completedSessions.fold<int>(
      0,
      (sum, s) => sum + (s.totalDuration ~/ 60),
    );
    return totalMinutes / completedSessions.length;
  }

  double get averageSessionSeconds {
    final completedSessions = _sessions.where((s) => s.completed).toList();
    if (completedSessions.isEmpty) return 0;
    final totalSeconds = completedSessions.fold<int>(
      0,
      (sum, s) => sum + s.totalDuration,
    );
    return totalSeconds / completedSessions.length;
  }

  // Returns total focus seconds per day for the last 7 days.
  Map<DateTime, int> get weeklyFocusSeconds {
    final now = DateTime.now();
    final result = <DateTime, int>{};
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      result[day] = _focusSecondsForDate(day);
    }
    return result;
  }

  // Returns total focus seconds per day for the last 30 days.
  Map<DateTime, int> get monthlyFocusSeconds {
    final now = DateTime.now();
    final result = <DateTime, int>{};
    for (int i = 29; i >= 0; i--) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      result[day] = _focusSecondsForDate(day);
    }
    return result;
  }

  // Returns total focus seconds per preset name.
  Map<String, int> get presetBreakdown {
    final result = <String, int>{};
    for (final s in _sessions.where((s) => s.completed)) {
      final name = s.presetName ?? 'Unknown';
      result[name] = (result[name] ?? 0) + s.focusDuration;
    }
    return result;
  }

  int currentStreak(int dailyGoalMinutes) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final goalSeconds = dailyGoalMinutes * 60;
    int streak = 0;
    // If today's goal is already met, count from today; otherwise from yesterday
    final startOffset = _focusSecondsForDate(today) >= goalSeconds ? 0 : 1;
    for (int i = startOffset; i <= 365; i++) {
      final day = today.subtract(Duration(days: i));
      if (_focusSecondsForDate(day) >= goalSeconds) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int _focusSecondsForDate(DateTime date) {
    final nextDay = date.add(const Duration(days: 1));
    return _sessions
        .where(
          (s) =>
              s.completed &&
              s.startTime.isAfter(date) &&
              s.startTime.isBefore(nextDay),
        )
        .fold<int>(0, (sum, s) => sum + s.focusDuration);
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

  // Start a new session with a name and target loops
  void startSession({
    required String userId,
    required String name,
    required int targetLoops,
    required String presetName,
  }) {
    _currentSession = Session(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      name: name,
      targetLoops: targetLoops,
      startTime: DateTime.now(),
      presetName: presetName,
      loops: [],
      currentLoopIndex: 0,
    );
    notifyListeners();
  }

  // Start a new loop within the current session
  void startLoop({required TimerType type, required int duration}) {
    if (_currentSession == null) return;

    final newLoop = Loop(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      duration: duration,
      startTime: DateTime.now(),
    );

    final updatedLoops = List<Loop>.from(_currentSession!.loops)..add(newLoop);
    _currentSession = _currentSession!.copyWith(
      loops: updatedLoops,
      currentLoopIndex: updatedLoops.length - 1,
    );
    notifyListeners();
  }

  // Complete the current loop
  void completeCurrentLoop({bool skipped = false}) {
    if (_currentSession == null) return;
    if (_currentSession!.loops.isEmpty) return;

    final currentIndex = _currentSession!.currentLoopIndex;
    if (currentIndex >= _currentSession!.loops.length) return;

    final now = DateTime.now();
    final loop = _currentSession!.loops[currentIndex];
    final elapsed = now.difference(loop.startTime).inSeconds;

    final updatedLoops = List<Loop>.from(_currentSession!.loops);
    updatedLoops[currentIndex] = loop.copyWith(
      endTime: now,
      completed: true,
      skipped: skipped,
      duration: elapsed.clamp(0, loop.duration),
    );

    _currentSession = _currentSession!.copyWith(loops: updatedLoops);
    notifyListeners();
  }

  // Finish the entire session (mark as complete and save)
  void finishSession([BuildContext? context]) {
    if (_currentSession != null) {
      final now = DateTime.now();

      // Complete any loops that are still active, recording actual elapsed time
      final updatedLoops = _currentSession!.loops.map((loop) {
        if (!loop.completed) {
          final elapsed = now.difference(loop.startTime).inSeconds;
          return loop.copyWith(
            endTime: now,
            completed: true,
            duration: elapsed.clamp(0, loop.duration),
          );
        }
        return loop;
      }).toList();

      _currentSession = _currentSession!.copyWith(
        loops: updatedLoops,
        endTime: now,
        completed: true,
      );
      // Add to sessions list and persist
      _sessions.insert(0, _currentSession!);
      _box.put(_currentSession!.id, _currentSession!);
      // Clear current session
      _currentSession = null;

      if (context != null) {
        // Show confetti celebration
        Confetti.launch(
          context,
          options: const ConfettiOptions(particleCount: 100, spread: 70, y: 0.6),
        );
      }
      notifyListeners();
    }
  }

  Future<void> clearAllSessions() async {
    await _box.clear();
    _sessions.clear();
    notifyListeners();
  }

  // Cancel the session without saving
  void cancelSession() {
    _currentSession = null;
    notifyListeners();
  }

  // Clear the current session (alias for cancelSession)
  void clearCurrentSession() {
    cancelSession();
  }
}
