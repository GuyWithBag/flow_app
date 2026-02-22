import 'package:flow_app/shared/theme.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'package:flow_app/models/models.barrel.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _themeBrightness = 'system'; // 'light', 'dark', 'system'
  int _dailyGoalMinutes = 120;
  TimerType _currentTimerType = TimerType.focus;
  bool _showBackgroundOnMenuScreens = false;

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

  // Theme caching to prevent unnecessary rebuilds
  ThemeData? _cachedTheme;
  Color? _cachedAccentColor;
  bool? _cachedDarkMode;

  bool get isDarkMode => _isDarkMode;
  String get themeBrightness => _themeBrightness;
  int get dailyGoalMinutes => _dailyGoalMinutes;
  TimerType get currentTimerType => _currentTimerType;
  bool get showBackgroundOnMenuScreens => _showBackgroundOnMenuScreens;

  // Current-mode convenience getters (resolve based on active timer type)
  Color get accentColor => _modeAccentColors[_currentTimerType]!;
  String get backgroundTheme => _modeBackgroundThemes[_currentTimerType]!;
  String? get backgroundImageUrl => _modeBackgroundImageUrls[_currentTimerType];

  // Per-mode getters (for when you need a specific mode's value)
  String getBackgroundThemeFor(TimerType type) =>
      _modeBackgroundThemes[type] ?? 'default';

  String? getBackgroundImageUrlFor(TimerType type) =>
      _modeBackgroundImageUrls[type];

  Color getAccentColorFor(TimerType type) =>
      _modeAccentColors[type] ?? const Color(0xFF66BB6A);

  ThemeData get currentTheme {
    final accent = accentColor;

    // Return cached theme if nothing changed
    if (_cachedTheme != null &&
        _cachedAccentColor == accent &&
        _cachedDarkMode == _isDarkMode) {
      return _cachedTheme!;
    }

    // Rebuild and cache
    final newTheme = _isDarkMode
        ? darkTheme.copyWith(
            colorScheme: ColorScheme.dark(
              primary: accent,
              secondary: Colors.grey.shade800,
            ),
          )
        : lightTheme.copyWith(
            colorScheme: ColorScheme.light(
              primary: accent,
              secondary: Colors.grey.shade200,
            ),
          );

    _cachedTheme = newTheme;
    _cachedAccentColor = accent;
    _cachedDarkMode = _isDarkMode;

    return newTheme;
  }

  void updateTimerType(TimerType type) {
    if (_currentTimerType == type) return;

    // Check if theme actually changes
    final oldColor = _modeAccentColors[_currentTimerType];
    final newColor = _modeAccentColors[type];
    final oldTheme = _modeBackgroundThemes[_currentTimerType];
    final newTheme = _modeBackgroundThemes[type];

    _currentTimerType = type;

    // Only notify if visual theme is different
    if (oldColor != newColor || oldTheme != newTheme) {
      _cachedTheme = null; // Invalidate cache
      notifyListeners();
    }
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _cachedTheme = null; // Invalidate cache
    notifyListeners();
    _savePreferences();
  }

  void setThemeBrightness(String brightness) {
    _themeBrightness = brightness;
    // Update _isDarkMode based on the brightness and system setting
    if (brightness == 'light') {
      _isDarkMode = false;
    } else if (brightness == 'dark') {
      _isDarkMode = true;
    }
    // For 'system', _isDarkMode will be updated by updateSystemBrightness
    _cachedTheme = null; // Invalidate cache
    notifyListeners();
    _savePreferences();
  }

  void updateSystemBrightness(Brightness brightness) {
    if (_themeBrightness == 'system') {
      final newDarkMode = brightness == Brightness.dark;
      if (_isDarkMode != newDarkMode) {
        _isDarkMode = newDarkMode;
        _cachedTheme = null; // Invalidate cache
        notifyListeners();
      }
    }
  }

  void setDailyGoalMinutes(int minutes) {
    _dailyGoalMinutes = minutes.clamp(15, 600);
    notifyListeners();
    _savePreferences();
  }

  void setShowBackgroundOnMenuScreens(bool value) {
    _showBackgroundOnMenuScreens = value;
    notifyListeners();
    _savePreferences();
  }

  // Per-mode setters
  void setModeBackgroundTheme(TimerType type, String theme) {
    _modeBackgroundThemes[type] = theme;
    notifyListeners();
    _savePreferences();
  }

  void setModeBackgroundImageUrl(TimerType type, String? url) {
    final normalized = (url ?? '').trim();
    final value = normalized.isEmpty ? null : normalized;
    _modeBackgroundImageUrls[type] = value;
    notifyListeners();
    _savePreferences();
  }

  void setModeAccentColor(TimerType type, Color color) {
    _modeAccentColors[type] = color;
    _cachedTheme = null; // Invalidate cache
    notifyListeners();
    _savePreferences();
  }

  void _savePreferences() {
    final box = Hive.box('settings');

    box.put('dark_mode', _isDarkMode);
    box.put('theme_brightness', _themeBrightness);
    box.put('daily_goal_minutes', _dailyGoalMinutes);
    box.put('show_background_on_menu_screens', _showBackgroundOnMenuScreens);

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
      _modeAccentColors[TimerType.focus]?.value ??
          const Color(0xFF66BB6A).value,
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
    _themeBrightness = box.get('theme_brightness', defaultValue: 'system');
    _dailyGoalMinutes = box.get('daily_goal_minutes', defaultValue: 120);
    _showBackgroundOnMenuScreens = box.get(
      'show_background_on_menu_screens',
      defaultValue: false,
    );

    _modeBackgroundThemes[TimerType.focus] = box.get(
      'focus_background_theme',
      defaultValue: 'default',
    );
    _modeBackgroundThemes[TimerType.breakTime] = box.get(
      'break_background_theme',
      defaultValue: 'default',
    );

    final focusUrl =
        box.get('focus_background_image_url', defaultValue: '') as String;
    final breakUrl =
        box.get('break_background_image_url', defaultValue: '') as String;
    _modeBackgroundImageUrls[TimerType.focus] = focusUrl.trim().isEmpty
        ? null
        : focusUrl.trim();
    _modeBackgroundImageUrls[TimerType.breakTime] = breakUrl.trim().isEmpty
        ? null
        : breakUrl.trim();

    _modeAccentColors[TimerType.focus] = Color(
      box.get(
        'focus_accent_color',
        defaultValue: const Color(0xFF66BB6A).value,
      ),
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
