import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    setModeAccentColor(TimerType.focus, color);
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

  void setModeAccentColor(TimerType type, Color color) {
    _modeAccentColors[type] = color;
    if (type == TimerType.focus) {
      _accentColor = color;
    }
    notifyListeners();
    _savePreferences();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('dark_mode', _isDarkMode);
    await prefs.setInt('daily_goal_minutes', _dailyGoalMinutes);

    // Legacy single-mode values (mapped from Focus mode)
    await prefs.setString('background_theme', _backgroundTheme);
    await prefs.setString('background_image_url', _backgroundImageUrl ?? '');
    await prefs.setInt('accent_color', _accentColor.value);

    // Per-mode values
    await prefs.setString(
      'focus_background_theme',
      _modeBackgroundThemes[TimerType.focus] ?? 'default',
    );
    await prefs.setString(
      'break_background_theme',
      _modeBackgroundThemes[TimerType.breakTime] ?? 'default',
    );

    await prefs.setString(
      'focus_background_image_url',
      _modeBackgroundImageUrls[TimerType.focus] ?? '',
    );
    await prefs.setString(
      'break_background_image_url',
      _modeBackgroundImageUrls[TimerType.breakTime] ?? '',
    );

    await prefs.setInt(
      'focus_accent_color',
      _modeAccentColors[TimerType.focus]?.value ?? _accentColor.value,
    );
    await prefs.setInt(
      'break_accent_color',
      _modeAccentColors[TimerType.breakTime]?.value ??
          const Color(0xFFFFB74D).value,
    );
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    _isDarkMode = prefs.getBool('dark_mode') ?? false;
    _dailyGoalMinutes = prefs.getInt('daily_goal_minutes') ?? 120;

    // Legacy single-mode values
    _backgroundTheme = prefs.getString('background_theme') ?? 'default';
    final url = prefs.getString('background_image_url') ?? '';
    _backgroundImageUrl = url.trim().isEmpty ? null : url.trim();
    _accentColor = Color(prefs.getInt('accent_color') ?? 0xFF66BB6A);

    // Per-mode values with fallback to legacy
    _modeBackgroundThemes[TimerType.focus] =
        prefs.getString('focus_background_theme') ?? _backgroundTheme;
    _modeBackgroundThemes[TimerType.breakTime] =
        prefs.getString('break_background_theme') ?? _backgroundTheme;

    final focusUrl = prefs.getString('focus_background_image_url') ?? '';
    final breakUrl = prefs.getString('break_background_image_url') ?? '';
    _modeBackgroundImageUrls[TimerType.focus] = focusUrl.trim().isEmpty
        ? _backgroundImageUrl
        : focusUrl.trim();
    _modeBackgroundImageUrls[TimerType.breakTime] = breakUrl.trim().isEmpty
        ? _backgroundImageUrl
        : breakUrl.trim();

    _modeAccentColors[TimerType.focus] = Color(
      prefs.getInt('focus_accent_color') ?? _accentColor.value,
    );
    _modeAccentColors[TimerType.breakTime] = Color(
      prefs.getInt('break_accent_color') ?? const Color(0xFFFFB74D).value,
    );

    notifyListeners();
  }
}
