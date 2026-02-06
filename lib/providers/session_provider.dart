import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';

class SessionProvider extends ChangeNotifier {
  final List<Session> _sessions = [];
  bool _isLoading = false;

  List<Session> get sessions => List.unmodifiable(_sessions);
  bool get isLoading => _isLoading;

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
        .fold(0, (sum, s) => sum + (s.duration ~/ 60));
  }

  int get totalFocusMinutes {
    return _sessions
        .where((s) => s.type == TimerType.focus && s.completed)
        .fold(0, (sum, s) => sum + (s.duration ~/ 60));
  }

  // Mock: Load sessions from Supabase
  Future<void> loadSessions() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock data
      _sessions
        ..clear()
        ..addAll([
          Session(
            id: '1',
            userId: 'mock_user_123',
            type: TimerType.focus,
            duration: 1500,
            startTime: DateTime.now().subtract(const Duration(hours: 2)),
            endTime: DateTime.now().subtract(
              const Duration(hours: 1, minutes: 35),
            ),
            completed: true,
            label: 'Studied Math',
            progressNote: 'Completed 15 pages',
          ),
          Session(
            id: '2',
            userId: 'mock_user_123',
            type: TimerType.focus,
            duration: 1500,
            startTime: DateTime.now().subtract(const Duration(hours: 4)),
            endTime: DateTime.now().subtract(
              const Duration(hours: 3, minutes: 35),
            ),
            completed: true,
            label: 'Coding',
            progressNote: 'Built login screen',
          ),
        ]);
    } catch (e) {
      debugPrint('Error loading sessions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mock: Add session to Supabase
  Future<void> addSession(Session session) async {
    _sessions.insert(0, session);
    notifyListeners();
  }

  // Mock: Update session
  Future<void> updateSession(Session session) async {
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      _sessions[index] = session;
      notifyListeners();
    }
  }
}
