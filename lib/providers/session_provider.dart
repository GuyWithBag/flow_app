import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_local_storage/hive_local_storage.dart' hide Session;

import '../models/models.dart';

class SessionProvider extends ChangeNotifier {
  final List<Session> _sessions = [];
  bool _isLoading = false;
  Session? _currentSession;

  List<Session> get sessions => List.unmodifiable(_sessions);
  bool get isLoading => _isLoading;
  Session? get currentSession => _currentSession;

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

  Future<void> _saveSessions() async {
    final encoded = _sessions.map((s) => jsonEncode(s.toJson())).toList();
    await LocalStorage.i.put<String>(
      key: 'sessions',
      value: jsonEncode(encoded),
    );
  }

  // Load sessions from Hive storage
  Future<void> loadSessions() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final raw = LocalStorage.i.get<String>(key: 'sessions');
      _sessions.clear();
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        for (final item in decoded) {
          final json = item is String ? jsonDecode(item) : item;
          _sessions.add(Session.fromJson(json as Map<String, dynamic>));
        }
      }
    } catch (e) {
      debugPrint('Error loading sessions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSession(Session session) async {
    _sessions.insert(0, session);
    notifyListeners();
    await _saveSessions();
  }

  Future<void> updateSession(Session session) async {
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      _sessions[index] = session;
      notifyListeners();
      await _saveSessions();
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
      // Add to sessions list
      _sessions.insert(0, _currentSession!);
      // Clear current session
      _currentSession = null;
      notifyListeners();
      _saveSessions();
    }
  }

  // Clear the current session (e.g., on reset)
  void clearCurrentSession() {
    _currentSession = null;
    notifyListeners();
  }
}
