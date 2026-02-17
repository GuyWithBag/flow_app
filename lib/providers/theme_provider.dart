import 'package:flow_app/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:hive_local_storage/hive_local_storage.dart';
import 'package:provider/provider.dart';

import 'package:flow_app/models/timer_models.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  int _dailyGoalMinutes = 120;

  // Legacy single-mode fields (kept for backwards compatibility / defaulting)
  String _backgroundTheme = 'default';
  String? _backgroundImageUrl;
  Color _accentColor = const Color(0xFF66BB6A);

  // Per-mode theming for Focus / Break
  final Map<TimerType, String> _modeBackgroundThemes = {
    TimerType.focus: 'default',
    TimerType.breakTime: 'default',
  };

  final Map<TimerType, String?> _modeBackgroundImageUrls = {
    TimerType.focus: null,
    TimerType.breakTime: null,
  };

  final Map<TimerType, Color> _modeAccentColors = {
    TimerType.focus: const Color(0xFF66BB6A),
    TimerType.breakTime: const Color(0xFFFFB74D),
  };

  bool get isDarkMode => _isDarkMode;
  int get dailyGoalMinutes => _dailyGoalMinutes;

  // Legacy getters (map to Focus mode for backwards compatibility)
  String get backgroundTheme => getBackgroundThemeFor(TimerType.focus);
  String? get backgroundImageUrl => getBackgroundImageUrlFor(TimerType.focus);
  Color get accentColor => getAccentColorFor(TimerType.focus);

  // Per-mode getters
  String getBackgroundThemeFor(TimerType type) =>
      _modeBackgroundThemes[type] ?? _backgroundTheme;

  String? getBackgroundImageUrlFor(TimerType type) =>
      _modeBackgroundImageUrls[type] ?? _backgroundImageUrl;

  Color getAccentColorFor(TimerType type) =>
      _modeAccentColors[type] ?? _accentColor;

  ThemeData get currentTheme {
    // Use the legacy accent color as the base app theme accent.
    final baseAccent = _accentColor;

    if (_isDarkMode) {
      return ThemeData.dark().copyWith(
        primaryColor: baseAccent,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        colorScheme: ColorScheme.dark(
          primary: baseAccent,
          secondary: baseAccent,
        ),
      );
    }

    return ThemeData.light().copyWith(
      primaryColor: baseAccent,
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      colorScheme: ColorScheme.light(
        primary: baseAccent,
        secondary: baseAccent,
      ),
    );
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    _savePreferences();
  }

  void setDailyGoalMinutes(int minutes) {
    _dailyGoalMinutes = minutes.clamp(15, 600);
    notifyListeners();
    _savePreferences();
  }

  // Legacy setters (apply to Focus mode by default)
  void setBackgroundTheme(String theme) {
    setModeBackgroundTheme(TimerType.focus, theme);
  }

  void setBackgroundImageUrl(String? url) {
    setModeBackgroundImageUrl(TimerType.focus, url);
  }

  void setAccentColor(Color color) {
    _accentColor = color;
  }

  // Per-mode setters
  void setModeBackgroundTheme(TimerType type, String theme) {
    _modeBackgroundThemes[type] = theme;
    if (type == TimerType.focus) {
      _backgroundTheme = theme;
    }
    notifyListeners();
    _savePreferences();
  }

  void setModeBackgroundImageUrl(TimerType type, String? url) {
    final normalized = (url ?? '').trim();
    final value = normalized.isEmpty ? null : normalized;
    _modeBackgroundImageUrls[type] = value;
    if (type == TimerType.focus) {
      _backgroundImageUrl = value;
    }
    notifyListeners();
    _savePreferences();
  }

  void setModeAccentColor(BuildContext context, TimerType type, Color color) {
    final timerProvider = context.read<TimerProvider>();
    _modeAccentColors[type] = color;
    if (timerProvider.currentType == type) {
      _accentColor = color;
    }
    notifyListeners();
    _savePreferences();
  }

  Future<void> _savePreferences() async {
    final storage = LocalStorage.i;

    await storage.put<bool>(key: 'dark_mode', value: _isDarkMode);
    await storage.put<int>(key: 'daily_goal_minutes', value: _dailyGoalMinutes);

    // Legacy single-mode values (mapped from Focus mode)
    await storage.put<String>(key: 'background_theme', value: _backgroundTheme);
    await storage.put<String>(
      key: 'background_image_url',
      value: _backgroundImageUrl ?? '',
    );
    await storage.put<int>(key: 'accent_color', value: _accentColor.value);

    // Per-mode values
    await storage.put<String>(
      key: 'focus_background_theme',
      value: _modeBackgroundThemes[TimerType.focus] ?? 'default',
    );
    await storage.put<String>(
      key: 'break_background_theme',
      value: _modeBackgroundThemes[TimerType.breakTime] ?? 'default',
    );

    await storage.put<String>(
      key: 'focus_background_image_url',
      value: _modeBackgroundImageUrls[TimerType.focus] ?? '',
    );
    await storage.put<String>(
      key: 'break_background_image_url',
      value: _modeBackgroundImageUrls[TimerType.breakTime] ?? '',
    );

    await storage.put<int>(
      key: 'focus_accent_color',
      value: _modeAccentColors[TimerType.focus]?.value ?? _accentColor.value,
    );
    await storage.put<int>(
      key: 'break_accent_color',
      value:
          _modeAccentColors[TimerType.breakTime]?.value ??
          const Color(0xFFFFB74D).value,
    );
  }

  Future<void> loadPreferences() async {
    final storage = LocalStorage.i;

    _isDarkMode = storage.get<bool>(key: 'dark_mode') ?? false;
    _dailyGoalMinutes = storage.get<int>(key: 'daily_goal_minutes') ?? 120;

    // Legacy single-mode values
    _backgroundTheme =
        storage.get<String>(key: 'background_theme') ?? 'default';
    final url = storage.get<String>(key: 'background_image_url') ?? '';
    _backgroundImageUrl = url.trim().isEmpty ? null : url.trim();
    _accentColor = Color(storage.get<int>(key: 'accent_color') ?? 0xFF66BB6A);

    // Per-mode values with fallback to legacy
    _modeBackgroundThemes[TimerType.focus] =
        storage.get<String>(key: 'focus_background_theme') ?? _backgroundTheme;
    _modeBackgroundThemes[TimerType.breakTime] =
        storage.get<String>(key: 'break_background_theme') ?? _backgroundTheme;

    final focusUrl =
        storage.get<String>(key: 'focus_background_image_url') ?? '';
    final breakUrl =
        storage.get<String>(key: 'break_background_image_url') ?? '';
    _modeBackgroundImageUrls[TimerType.focus] = focusUrl.trim().isEmpty
        ? _backgroundImageUrl
        : focusUrl.trim();
    _modeBackgroundImageUrls[TimerType.breakTime] = breakUrl.trim().isEmpty
        ? _backgroundImageUrl
        : breakUrl.trim();

    _modeAccentColors[TimerType.focus] = Color(
      storage.get<int>(key: 'focus_accent_color') ?? _accentColor.value,
    );
    _modeAccentColors[TimerType.breakTime] = Color(
      storage.get<int>(key: 'break_accent_color') ??
          const Color(0xFFFFB74D).value,
    );

    notifyListeners();
  }
}
