import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_local_storage/hive_local_storage.dart';

import '../models/models.dart';

class TimerProvider extends ChangeNotifier {
  TimerProvider() {
    _loadFromStorage();
  }

  Timer? _timer;
  int _remainingSeconds = 1500; // 25 minutes default
  int _totalSeconds = 1500;
  bool _isRunning = false;
  TimerType _currentType = TimerType.focus;
  int _completedCycles = 0;

  final Map<TimerType, int> _defaultDurations = {
    TimerType.focus: 1500, // 25 min
    TimerType.breakTime: 300, // 5 min
  };

  void _loadFromStorage() {
    final storage = LocalStorage.i;
    _defaultDurations[TimerType.focus] =
        storage.get<int>(key: 'timer_focus_duration') ?? 1500;
    _defaultDurations[TimerType.breakTime] =
        storage.get<int>(key: 'timer_break_duration') ?? 300;
    _completedCycles = storage.get<int>(key: 'timer_completed_cycles') ?? 0;
    _remainingSeconds = _defaultDurations[_currentType]!;
    _totalSeconds = _remainingSeconds;
  }

  Future<void> _saveToStorage() async {
    final storage = LocalStorage.i;
    await storage.put<int>(
      key: 'timer_focus_duration',
      value: _defaultDurations[TimerType.focus]!,
    );
    await storage.put<int>(
      key: 'timer_break_duration',
      value: _defaultDurations[TimerType.breakTime]!,
    );
    await storage.put<int>(
      key: 'timer_completed_cycles',
      value: _completedCycles,
    );
  }

  // Getters
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  bool get isRunning => _isRunning;
  TimerType get currentType => _currentType;
  int get completedCycles => _completedCycles;
  double get progress => _totalSeconds > 0
      ? (_totalSeconds - _remainingSeconds) / _totalSeconds
      : 0;

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
    _saveToStorage();
  }

  void startTimer() {
    if (_isRunning) return;

    _isRunning = true;

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
    notifyListeners();
  }

  void _completeTimer() {
    _timer?.cancel();
    _isRunning = false;

    // TODO: Play completion sound
    // TODO: Show notification
    // Session completion is handled by SessionProvider

    if (_currentType == TimerType.focus) {
      _completedCycles++;
      _saveToStorage();
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
