import 'package:flow_app/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:provider/provider.dart';

import 'package:flow_app/models/models.barrel.dart';

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

  void _savePreferences() {
    final box = Hive.box('settings');

    box.put('dark_mode', _isDarkMode);
    box.put('daily_goal_minutes', _dailyGoalMinutes);

    // Legacy single-mode values (mapped from Focus mode)
    box.put('background_theme', _backgroundTheme);
    box.put('background_image_url', _backgroundImageUrl ?? '');
    box.put('accent_color', _accentColor.value);

    // Per-mode values
    box.put(
      'focus_background_theme',
      _modeBackgroundThemes[TimerType.focus] ?? 'default',
    );
    box.put(
      'break_background_theme',
      _modeBackgroundThemes[TimerType.breakTime] ?? 'default',
    );
    box.put(
      'focus_background_image_url',
      _modeBackgroundImageUrls[TimerType.focus] ?? '',
    );
    box.put(
      'break_background_image_url',
      _modeBackgroundImageUrls[TimerType.breakTime] ?? '',
    );
    box.put(
      'focus_accent_color',
      _modeAccentColors[TimerType.focus]?.value ?? _accentColor.value,
    );
    box.put(
      'break_accent_color',
      _modeAccentColors[TimerType.breakTime]?.value ??
          const Color(0xFFFFB74D).value,
    );
  }

  void loadPreferences() {
    final box = Hive.box('settings');

    _isDarkMode = box.get('dark_mode', defaultValue: false);
    _dailyGoalMinutes = box.get('daily_goal_minutes', defaultValue: 120);

    // Legacy single-mode values
    _backgroundTheme = box.get('background_theme', defaultValue: 'default');
    final url = box.get('background_image_url', defaultValue: '') as String;
    _backgroundImageUrl = url.trim().isEmpty ? null : url.trim();
    _accentColor = Color(box.get('accent_color', defaultValue: 0xFF66BB6A));

    // Per-mode values with fallback to legacy
    _modeBackgroundThemes[TimerType.focus] = box.get(
      'focus_background_theme',
      defaultValue: _backgroundTheme,
    );
    _modeBackgroundThemes[TimerType.breakTime] = box.get(
      'break_background_theme',
      defaultValue: _backgroundTheme,
    );

    final focusUrl =
        box.get('focus_background_image_url', defaultValue: '') as String;
    final breakUrl =
        box.get('break_background_image_url', defaultValue: '') as String;
    _modeBackgroundImageUrls[TimerType.focus] = focusUrl.trim().isEmpty
        ? _backgroundImageUrl
        : focusUrl.trim();
    _modeBackgroundImageUrls[TimerType.breakTime] = breakUrl.trim().isEmpty
        ? _backgroundImageUrl
        : breakUrl.trim();

    _modeAccentColors[TimerType.focus] = Color(
      box.get('focus_accent_color', defaultValue: _accentColor.value),
    );
    _modeAccentColors[TimerType.breakTime] = Color(
      box.get(
        'break_accent_color',
        defaultValue: const Color(0xFFFFB74D).value,
      ),
    );

    notifyListeners();
  }
}
