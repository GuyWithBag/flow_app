import 'package:flutter/foundation.dart';
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
