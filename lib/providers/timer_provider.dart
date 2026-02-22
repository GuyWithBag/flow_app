import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/models.barrel.dart';
import '../services/notification_service.dart';
import '../shared/enums/enums.barrel.dart';

class TimerProvider extends ChangeNotifier {
  TimerProvider() {
    _loadFromStorage();
  }

  // --- TIMER STATE ---
  Timer? _timer;
  int _remainingSeconds = 1500;
  int _totalSeconds = 1500;
  bool _isRunning = false;
  TimerType _currentType = TimerType.focus;
  int _completedCycles = 0;
  bool _isLongDuration = false;

  final Map<TimerType, int> _defaultDurations = {
    TimerType.focus: 1500,
    TimerType.breakTime: 300,
  };

  // --- CONFIG STATE (persisted via Hive) ---
  bool _autoStartBreak = true;
  bool _autoStartFocus = false;
  int _targetLoops = 4;
  int _currentLoop = 1;
  SoundType _selectedSound = SoundType.bell;
  int _fixedScaleDuration = 3600;
  bool _useDynamicScale = false;
  double _waveContrast = 0.8;
  bool _showInnerLiquid = true;
  bool _showBackgroundLiquid = true;
  bool _autoHideControls = true;
  bool _autoNameSessions = true;
  String? _customSoundPath;
  bool _playDefaultSound = false;

  void _loadFromStorage() {
    final box = Hive.box('settings');

    // Timer durations
    _defaultDurations[TimerType.focus] = box.get(
      'timer_focus_duration',
      defaultValue: 1500,
    );
    _defaultDurations[TimerType.breakTime] = box.get(
      'timer_break_duration',
      defaultValue: 300,
    );
    _completedCycles = box.get('timer_completed_cycles', defaultValue: 0);
    _remainingSeconds = _defaultDurations[_currentType]!;
    _totalSeconds = _remainingSeconds;

    // Config
    _autoStartBreak = box.get('timer_auto_start_break', defaultValue: true);
    _autoStartFocus = box.get('timer_auto_start_focus', defaultValue: false);
    _targetLoops = box.get('timer_target_loops', defaultValue: 4);
    _selectedSound = box.get(
      'timer_selected_sound',
      defaultValue: SoundType.bell,
    );
    _fixedScaleDuration = box.get(
      'timer_fixed_scale_duration',
      defaultValue: 3600,
    );
    _useDynamicScale = box.get('timer_use_dynamic_scale', defaultValue: false);
    _waveContrast = box.get('timer_wave_contrast', defaultValue: 0.8);
    _showInnerLiquid = box.get('timer_show_inner_liquid', defaultValue: true);
    _showBackgroundLiquid = box.get(
      'timer_show_background_liquid',
      defaultValue: true,
    );
    _autoHideControls = box.get('timer_auto_hide_controls', defaultValue: true);
    _autoNameSessions = box.get('timer_auto_name_sessions', defaultValue: true);
    _customSoundPath = box.get('timer_custom_sound_path');
    _playDefaultSound = box.get(
      'timer_play_default_sound',
      defaultValue: false,
    );
  }

  void _saveToStorage() {
    final box = Hive.box('settings');

    // Timer durations
    box.put('timer_focus_duration', _defaultDurations[TimerType.focus]!);
    box.put('timer_break_duration', _defaultDurations[TimerType.breakTime]!);
    box.put('timer_completed_cycles', _completedCycles);

    // Config
    box.put('timer_auto_start_break', _autoStartBreak);
    box.put('timer_auto_start_focus', _autoStartFocus);
    box.put('timer_target_loops', _targetLoops);
    box.put('timer_selected_sound', _selectedSound);
    box.put('timer_fixed_scale_duration', _fixedScaleDuration);
    box.put('timer_use_dynamic_scale', _useDynamicScale);
    box.put('timer_wave_contrast', _waveContrast);
    box.put('timer_show_inner_liquid', _showInnerLiquid);
    box.put('timer_show_background_liquid', _showBackgroundLiquid);
    box.put('timer_auto_hide_controls', _autoHideControls);
    box.put('timer_auto_name_sessions', _autoNameSessions);
    if (_customSoundPath != null) {
      box.put('timer_custom_sound_path', _customSoundPath);
    }
    box.put('timer_play_default_sound', _playDefaultSound);
  }

  // --- TIMER GETTERS ---
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  bool get isRunning => _isRunning;
  TimerType get currentType => _currentType;
  int get completedCycles => _completedCycles;
  bool get isLongDuration => _isLongDuration;
  double get progress => _totalSeconds > 0
      ? (_totalSeconds - _remainingSeconds) / _totalSeconds
      : 0;

  // --- CONFIG GETTERS ---
  bool get autoStartBreak => _autoStartBreak;
  bool get autoStartFocus => _autoStartFocus;
  int get targetLoops => _targetLoops;
  int get currentLoop => _currentLoop;
  SoundType get selectedSound => _selectedSound;
  int get fixedScaleDuration => _fixedScaleDuration;
  bool get useDynamicScale => _useDynamicScale;
  double get waveContrast => _waveContrast;
  bool get showInnerLiquid => _showInnerLiquid;
  bool get showBackgroundLiquid => _showBackgroundLiquid;
  bool get autoHideControls => _autoHideControls;
  bool get autoNameSessions => _autoNameSessions;
  String? get customSoundPath => _customSoundPath;
  bool get playDefaultSound => _playDefaultSound;

  // --- CONFIG SETTERS ---
  void setAutoStartBreak(bool value) {
    _autoStartBreak = value;
    notifyListeners();
    _saveToStorage();
  }

  void setAutoStartFocus(bool value) {
    _autoStartFocus = value;
    notifyListeners();
    _saveToStorage();
  }

  void setTargetLoops(int value) {
    _targetLoops = value;
    notifyListeners();
    _saveToStorage();
  }

  void setCurrentLoop(int value) {
    _currentLoop = value;
    notifyListeners();
  }

  void resetLoop() {
    _currentLoop = 1;
    notifyListeners();
  }

  void incrementLoop() {
    _currentLoop++;
    notifyListeners();
  }

  void setSelectedSound(SoundType value) {
    _selectedSound = value;
    notifyListeners();
    _saveToStorage();
  }

  void setFixedScaleDuration(int value) {
    _fixedScaleDuration = value;
    notifyListeners();
    _saveToStorage();
  }

  void setUseDynamicScale(bool value) {
    _useDynamicScale = value;
    notifyListeners();
    _saveToStorage();
  }

  void setWaveContrast(double value) {
    _waveContrast = value;
    notifyListeners();
    _saveToStorage();
  }

  void setShowInnerLiquid(bool value) {
    _showInnerLiquid = value;
    notifyListeners();
    _saveToStorage();
  }

  void setShowBackgroundLiquid(bool value) {
    _showBackgroundLiquid = value;
    notifyListeners();
    _saveToStorage();
  }

  void setAutoHideControls(bool value) {
    _autoHideControls = value;
    notifyListeners();
    _saveToStorage();
  }

  void setAutoNameSessions(bool value) {
    _autoNameSessions = value;
    notifyListeners();
    _saveToStorage();
  }

  void setCustomSoundPath(String? path) {
    _customSoundPath = path;
    notifyListeners();
    _saveToStorage();
  }

  void setPlayDefaultSound(bool value) {
    _playDefaultSound = value;
    notifyListeners();
    _saveToStorage();
  }

  void setLongDuration(bool value) {
    _isLongDuration = value;
    notifyListeners();
  }

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
    _isLongDuration = false;
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
        _updateTimerNotification();
        notifyListeners();
      } else {
        _completeTimer();
      }
    });

    notifyListeners();
    _showTimerNotification();
  }

  void pauseTimer() {
    _isRunning = false;
    _timer?.cancel();
    notifyListeners();
    _updateTimerNotification();
  }

  void resetTimer() {
    _isRunning = false;
    _timer?.cancel();
    _remainingSeconds = _defaultDurations[_currentType]!;
    _totalSeconds = _remainingSeconds;
    notifyListeners();
    NotificationService.instance.cancelTimerNotification();
  }

  void resetTimerToPreset(PomodoroPreset preset) {
    resetTimer();
    final isFocus = _currentType == TimerType.focus;
    final duration = _isLongDuration
        ? (isFocus ? preset.longFocusDuration : preset.longBreakDuration)
        : (isFocus ? preset.focusDuration : preset.breakDuration);
    setCustomDuration(duration);
  }

  void _completeTimer() {
    _timer?.cancel();
    _isRunning = false;

    // Play completion sound
    NotificationService.instance.playCompletionSound(
      _selectedSound,
      customSoundPath: _customSoundPath,
    );

    // Show completion notification
    final label = _currentType == TimerType.focus ? 'Focus' : 'Break';
    NotificationService.instance.showCompletionNotification(
      title: '$label Complete!',
      body: _currentType == TimerType.focus
          ? 'Great work! Time for a break.'
          : 'Break is over. Ready to focus?',
      playDefaultSound: _playDefaultSound,
    );

    // Cancel the ongoing timer notification
    NotificationService.instance.cancelTimerNotification();

    if (_currentType == TimerType.focus) {
      _completedCycles++;
      _saveToStorage();
    }

    notifyListeners();
  }

  // --- NOTIFICATION HELPERS ---

  String get _notificationTitle =>
      'Flow — ${_currentType == TimerType.focus ? 'Focus' : 'Break'}';

  void _showTimerNotification() {
    NotificationService.instance.showTimerNotification(
      title: _notificationTitle,
      body: formattedTime,
      isRunning: _isRunning,
    );
  }

  void _updateTimerNotification() {
    final status = _isRunning ? formattedTime : '$formattedTime (Paused)';
    NotificationService.instance.showTimerNotification(
      title: _notificationTitle,
      body: status,
      isRunning: _isRunning,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
