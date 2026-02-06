import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/models.dart';

class TimerProvider extends ChangeNotifier {
  Timer? _timer;
  int _remainingSeconds = 1500; // 25 minutes default
  int _totalSeconds = 1500;
  bool _isRunning = false;
  TimerType _currentType = TimerType.focus;
  int _completedCycles = 0;
  Session? _currentSession;

  final Map<TimerType, int> _defaultDurations = {
    TimerType.focus: 1500, // 25 min
    TimerType.breakTime: 300, // 5 min
  };

  // Getters
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  bool get isRunning => _isRunning;
  TimerType get currentType => _currentType;
  int get completedCycles => _completedCycles;
  double get progress => _totalSeconds > 0
      ? (_totalSeconds - _remainingSeconds) / _totalSeconds
      : 0;
  Session? get currentSession => _currentSession;

  String get formattedTime {
    final hours = _remainingSeconds ~/ 3600;
    final minutes = (_remainingSeconds % 3600) ~/ 60;
    final seconds = _remainingSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void setTimerType(TimerType type) {
    if (_isRunning) return;
    _currentType = type;
    _remainingSeconds = _defaultDurations[type]!;
    _totalSeconds = _remainingSeconds;
    notifyListeners();
  }

  void setCustomDuration(int seconds) {
    if (_isRunning) return;
    _remainingSeconds = seconds;
    _totalSeconds = seconds;
    _defaultDurations[_currentType] = seconds;
    notifyListeners();
  }

  void startTimer() {
    if (_isRunning) return;

    _isRunning = true;

    // Create new session
    _currentSession = Session(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'current_user', // TODO: Replace with actual user ID
      type: _currentType,
      duration: _totalSeconds,
      startTime: DateTime.now(),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _completeTimer();
      }
    });

    notifyListeners();
    // TODO: Play start sound
  }

  void pauseTimer() {
    _isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  void resetTimer() {
    _isRunning = false;
    _timer?.cancel();
    _remainingSeconds = _defaultDurations[_currentType]!;
    _totalSeconds = _remainingSeconds;
    _currentSession = null;
    notifyListeners();
  }

  void _completeTimer() {
    _timer?.cancel();
    _isRunning = false;

    // Mark session as completed
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        endTime: DateTime.now(),
        completed: true,
      );
    }

    // TODO: Play completion sound
    // TODO: Show notification
    // TODO: Save session to Supabase

    if (_currentType == TimerType.focus) {
      _completedCycles++;
    }

    notifyListeners();

    // Auto-switch logic
    // if (_currentType == TimerType.focus && _completedCycles % 4 == 0) {
    //   // Long break after 4 cycles
    // } else if (_currentType == TimerType.focus) {
    //   setTimerType(TimerType.breakTime);
    // } else {
    //   setTimerType(TimerType.focus);
    // }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
