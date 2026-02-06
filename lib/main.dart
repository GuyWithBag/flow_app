// Flow - A Beautiful Pomodoro Timer App
// Production-ready Flutter app with Supabase integration (mock), Provider + Hooks state management

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math' as math;

// ============================================================================
// MAIN APP ENTRY POINT
// ============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Initialize Supabase
  // await Supabase.initialize(
  //   url: 'YOUR_SUPABASE_URL',
  //   anonKey: 'YOUR_SUPABASE_ANON_KEY',
  // );

  // TODO: Initialize notifications
  // await NotificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimerProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => PresetProvider()),
      ],
      child: const FlowApp(),
    ),
  );
}

class FlowApp extends StatelessWidget {
  const FlowApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Flow',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          home: const MainScreen(),
        );
      },
    );
  }
}

// ============================================================================
// MODELS
// ============================================================================

enum TimerType { focus, breakTime }

class TimerMode {
  final TimerType type;
  final int duration; // in seconds
  final String label;
  final Color primaryColor;
  final Color accentColor;

  TimerMode({
    required this.type,
    required this.duration,
    required this.label,
    required this.primaryColor,
    required this.accentColor,
  });
}

class PomodoroPreset {
  final String id;
  final String name;
  final int focusDuration;
  final int breakDuration;
  final int longBreakDuration;
  final int cyclesBeforeLongBreak;

  PomodoroPreset({
    required this.id,
    required this.name,
    required this.focusDuration,
    required this.breakDuration,
    required this.longBreakDuration,
    this.cyclesBeforeLongBreak = 4,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'focus_duration': focusDuration,
    'break_duration': breakDuration,
    'long_break_duration': longBreakDuration,
    'cycles_before_long_break': cyclesBeforeLongBreak,
  };

  factory PomodoroPreset.fromJson(Map<String, dynamic> json) => PomodoroPreset(
    id: json['id'],
    name: json['name'],
    focusDuration: json['focus_duration'],
    breakDuration: json['break_duration'],
    longBreakDuration: json['long_break_duration'],
    cyclesBeforeLongBreak: json['cycles_before_long_break'] ?? 4,
  );
}

class Session {
  final String id;
  final String userId;
  final TimerType type;
  final int duration;
  final DateTime startTime;
  final DateTime? endTime;
  final String? presetName;
  final String? label;
  final String? progressNote;
  final bool completed;

  Session({
    required this.id,
    required this.userId,
    required this.type,
    required this.duration,
    required this.startTime,
    this.endTime,
    this.presetName,
    this.label,
    this.progressNote,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'type': type.toString(),
    'duration': duration,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime?.toIso8601String(),
    'preset_name': presetName,
    'label': label,
    'progress_note': progressNote,
    'completed': completed,
  };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    id: json['id'],
    userId: json['user_id'],
    type: json['type'].toString().contains('focus')
        ? TimerType.focus
        : TimerType.breakTime,
    duration: json['duration'],
    startTime: DateTime.parse(json['start_time']),
    endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
    presetName: json['preset_name'],
    label: json['label'],
    progressNote: json['progress_note'],
    completed: json['completed'] ?? false,
  );

  Session copyWith({
    String? label,
    String? progressNote,
    DateTime? endTime,
    bool? completed,
  }) {
    return Session(
      id: id,
      userId: userId,
      type: type,
      duration: duration,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      presetName: presetName,
      label: label ?? this.label,
      progressNote: progressNote ?? this.progressNote,
      completed: completed ?? this.completed,
    );
  }
}

class UserProfile {
  final String id;
  final String email;
  final String? name;
  final int dailyGoal; // in minutes
  final int streak;

  UserProfile({
    required this.id,
    required this.email,
    this.name,
    this.dailyGoal = 120,
    this.streak = 0,
  });
}

// ============================================================================
// PROVIDERS
// ============================================================================

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

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _backgroundTheme = 'default';
  Color _accentColor = const Color(0xFF66BB6A);

  bool get isDarkMode => _isDarkMode;
  String get backgroundTheme => _backgroundTheme;
  Color get accentColor => _accentColor;

  ThemeData get currentTheme {
    if (_isDarkMode) {
      return ThemeData.dark().copyWith(
        primaryColor: _accentColor,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        colorScheme: ColorScheme.dark(
          primary: _accentColor,
          secondary: _accentColor,
        ),
      );
    }

    return ThemeData.light().copyWith(
      primaryColor: _accentColor,
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      colorScheme: ColorScheme.light(
        primary: _accentColor,
        secondary: _accentColor,
      ),
    );
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    _savePreferences();
  }

  void setBackgroundTheme(String theme) {
    _backgroundTheme = theme;
    notifyListeners();
    _savePreferences();
  }

  void setAccentColor(Color color) {
    _accentColor = color;
    notifyListeners();
    _savePreferences();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
    await prefs.setString('background_theme', _backgroundTheme);
    await prefs.setInt('accent_color', _accentColor.value);
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('dark_mode') ?? false;
    _backgroundTheme = prefs.getString('background_theme') ?? 'default';
    _accentColor = Color(prefs.getInt('accent_color') ?? 0xFF66BB6A);
    notifyListeners();
  }
}

class AuthProvider extends ChangeNotifier {
  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Mock login
  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Replace with real Supabase authentication
      // final response = await Supabase.instance.client.auth.signInWithPassword(
      //   email: email,
      //   password: password,
      // );

      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate network delay

      _currentUser = UserProfile(
        id: 'mock_user_123',
        email: email,
        name: email.split('@')[0],
        dailyGoal: 120,
        streak: 5,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mock signup
  Future<void> signup(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Replace with real Supabase authentication
      // final response = await Supabase.instance.client.auth.signUp(
      //   email: email,
      //   password: password,
      // );

      await Future.delayed(const Duration(seconds: 1));

      _currentUser = UserProfile(
        id: 'mock_user_new',
        email: email,
        name: email.split('@')[0],
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Anonymous login
  Future<void> loginAnonymously() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Replace with Supabase anonymous auth
      await Future.delayed(const Duration(milliseconds: 500));

      _currentUser = UserProfile(
        id: 'anonymous_${DateTime.now().millisecondsSinceEpoch}',
        email: 'anonymous@flow.app',
        name: 'Guest User',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    // TODO: await Supabase.instance.client.auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}

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
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Replace with real Supabase query
      // final response = await Supabase.instance.client
      //     .from('sessions')
      //     .select()
      //     .eq('user_id', currentUserId)
      //     .order('start_time', ascending: false);

      await Future.delayed(const Duration(milliseconds: 500));

      // Mock data
      _sessions.clear();
      _sessions.addAll([
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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mock: Add session to Supabase
  Future<void> addSession(Session session) async {
    // TODO: Replace with real Supabase insert
    // await Supabase.instance.client.from('sessions').insert(session.toJson());

    _sessions.insert(0, session);
    notifyListeners();
  }

  // Mock: Update session
  Future<void> updateSession(Session session) async {
    // TODO: Replace with real Supabase update
    // await Supabase.instance.client
    //     .from('sessions')
    //     .update(session.toJson())
    //     .eq('id', session.id);

    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      _sessions[index] = session;
      notifyListeners();
    }
  }
}

class PresetProvider extends ChangeNotifier {
  final List<PomodoroPreset> _presets = [
    PomodoroPreset(
      id: 'classic',
      name: 'Classic',
      focusDuration: 1500,
      breakDuration: 300,
      longBreakDuration: 900,
    ),
    PomodoroPreset(
      id: 'light_study',
      name: 'Light Study',
      focusDuration: 900,
      breakDuration: 180,
      longBreakDuration: 600,
    ),
    PomodoroPreset(
      id: 'heavy_study',
      name: 'Heavy Study',
      focusDuration: 2700,
      breakDuration: 600,
      longBreakDuration: 1200,
    ),
  ];

  PomodoroPreset? _selectedPreset;

  List<PomodoroPreset> get presets => List.unmodifiable(_presets);
  PomodoroPreset? get selectedPreset => _selectedPreset;

  void selectPreset(PomodoroPreset preset) {
    _selectedPreset = preset;
    notifyListeners();
  }

  Future<void> addPreset(PomodoroPreset preset) async {
    // TODO: Save to Supabase
    _presets.add(preset);
    notifyListeners();
  }

  Future<void> deletePreset(String id) async {
    // TODO: Delete from Supabase
    _presets.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}

// ============================================================================
// MAIN SCREEN WITH BOTTOM NAVIGATION
// ============================================================================

class MainScreen extends HookWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentIndex = useState(1); // Start on Timer screen

    final screens = [
      const HistoryScreen(),
      const TimerScreen(),
      const AccountScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex.value, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex.value,
          onTap: (index) => currentIndex.value = index,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.timer_outlined),
              label: 'Timer',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TIMER SCREEN (MAIN)
// ============================================================================

class TimerScreen extends HookWidget {
  const TimerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final focusColor = const Color(0xFF66BB6A);
    final breakColor = const Color(0xFFFFB74D);

    final currentColor = timerProvider.currentType == TimerType.focus
        ? focusColor
        : breakColor;

    return Scaffold(
      body: Container(
        decoration: _buildBackground(themeProvider),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Flow',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.settings_outlined,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Mode Toggle
              _buildModeToggle(context, timerProvider, focusColor, breakColor),

              const SizedBox(height: 40),

              // Circular Timer
              Expanded(
                child: Center(
                  child: _buildCircularTimer(
                    context,
                    timerProvider,
                    currentColor,
                  ),
                ),
              ),

              // Control Buttons
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 30,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildResetButton(context, timerProvider),
                    const SizedBox(width: 20),
                    _buildPlayPauseButton(context, timerProvider, currentColor),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBackground(ThemeProvider themeProvider) {
    if (themeProvider.backgroundTheme == 'gradient') {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: themeProvider.isDarkMode
              ? [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)]
              : [const Color(0xFFFAFAFA), const Color(0xFFE8E8E8)],
        ),
      );
    }
    return BoxDecoration(
      color: themeProvider.isDarkMode
          ? const Color(0xFF1A1A1A)
          : const Color(0xFFFAFAFA),
    );
  }

  Widget _buildModeToggle(
    BuildContext context,
    TimerProvider timerProvider,
    Color focusColor,
    Color breakColor,
  ) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModeButton(
              'Focus',
              timerProvider.currentType == TimerType.focus,
              focusColor,
              () => timerProvider.setTimerType(TimerType.focus),
            ),
            _buildModeButton(
              'Break',
              timerProvider.currentType == TimerType.breakTime,
              breakColor,
              () => timerProvider.setTimerType(TimerType.breakTime),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(
    String label,
    bool isSelected,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCircularTimer(
    BuildContext context,
    TimerProvider timerProvider,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => _showTimePicker(context, timerProvider),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade100,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),

          // Animated progress circle
          SizedBox(
            width: 280,
            height: 280,
            child: CustomPaint(
              painter: CircularProgressPainter(
                progress: timerProvider.progress,
                color: color,
              ),
            ),
          ),

          // Time and label
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timerProvider.formattedTime,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set Time',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(BuildContext context, TimerProvider timerProvider) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: timerProvider.resetTimer,
        customBorder: const CircleBorder(),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.refresh, size: 30, color: Colors.black54),
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton(
    BuildContext context,
    TimerProvider timerProvider,
    Color color,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (timerProvider.isRunning) {
            timerProvider.pauseTimer();
          } else {
            timerProvider.startTimer();
          }
        },
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            timerProvider.isRunning ? Icons.pause : Icons.play_arrow,
            size: 40,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showTimePicker(BuildContext context, TimerProvider timerProvider) {
    if (timerProvider.isRunning) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => TimePickerSheet(
        initialSeconds: timerProvider.remainingSeconds,
        onTimeSelected: (seconds) {
          timerProvider.setCustomDuration(seconds);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ============================================================================
// CIRCULAR PROGRESS PAINTER
// ============================================================================

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  CircularProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw progress arc
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      startAngle,
      sweepAngle,
      false,
      paint,
    );

    // Draw dot at progress position
    if (progress > 0) {
      final dotAngle = startAngle + sweepAngle;
      final dotX = center.dx + (radius - 4) * math.cos(dotAngle);
      final dotY = center.dy + (radius - 4) * math.sin(dotAngle);

      canvas.drawCircle(Offset(dotX, dotY), 6, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// ============================================================================
// TIME PICKER SHEET
// ============================================================================

class TimePickerSheet extends HookWidget {
  final int initialSeconds;
  final Function(int) onTimeSelected;

  const TimePickerSheet({
    Key? key,
    required this.initialSeconds,
    required this.onTimeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hours = useState(initialSeconds ~/ 3600);
    final minutes = useState((initialSeconds % 3600) ~/ 60);
    final seconds = useState(initialSeconds % 60);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Set Custom Time',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimePicker(
                'Hours',
                hours.value,
                (v) => hours.value = v,
                24,
              ),
              const SizedBox(width: 10),
              const Text(
                ':',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              _buildTimePicker(
                'Minutes',
                minutes.value,
                (v) => minutes.value = v,
                60,
              ),
              const SizedBox(width: 10),
              const Text(
                ':',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              _buildTimePicker(
                'Seconds',
                seconds.value,
                (v) => seconds.value = v,
                60,
              ),
            ],
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              final totalSeconds =
                  hours.value * 3600 + minutes.value * 60 + seconds.value;
              if (totalSeconds > 0) {
                onTimeSelected(totalSeconds);
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Set Time', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildTimePicker(
    String label,
    int value,
    Function(int) onChanged,
    int maxValue,
  ) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 5),
        Container(
          width: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<int>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: List.generate(maxValue, (i) => i).map((i) {
              return DropdownMenuItem(
                value: i,
                child: Text(
                  i.toString().padLeft(2, '0'),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
            onChanged: (v) => onChanged(v ?? 0),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// HISTORY SCREEN
// ============================================================================

class HistoryScreen extends HookWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context);

    useEffect(() {
      sessionProvider.loadSessions();
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            },
          ),
        ],
      ),
      body: sessionProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : sessionProvider.sessions.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessionProvider.sessions.length,
              itemBuilder: (context, index) {
                final session = sessionProvider.sessions[index];
                return _buildSessionCard(context, session, sessionProvider);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            'No sessions yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete a timer to see your history',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    Session session,
    SessionProvider provider,
  ) {
    final isBreak = session.type == TimerType.breakTime;
    final color = isBreak ? const Color(0xFFFFB74D) : const Color(0xFF66BB6A);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showEditDialog(context, session, provider),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isBreak ? 'Break' : 'Focus',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM d, h:mm a').format(session.startTime),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.timer, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    '${session.duration ~/ 60} minutes',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (session.label != null) ...[
                const SizedBox(height: 8),
                Text(
                  session.label!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (session.progressNote != null) ...[
                const SizedBox(height: 4),
                Text(
                  session.progressNote!,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    Session session,
    SessionProvider provider,
  ) {
    final labelController = TextEditingController(text: session.label);
    final progressController = TextEditingController(
      text: session.progressNote,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'What did you do?',
                hintText: 'e.g., Studied Math',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: progressController,
              decoration: const InputDecoration(
                labelText: 'How much did you complete?',
                hintText: 'e.g., Completed 15 pages',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedSession = session.copyWith(
                label: labelController.text.isEmpty
                    ? null
                    : labelController.text,
                progressNote: progressController.text.isEmpty
                    ? null
                    : progressController.text,
              );
              provider.updateSession(updatedSession);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DASHBOARD SCREEN
// ============================================================================

class DashboardScreen extends HookWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsCards(sessionProvider),
            const SizedBox(height: 24),
            _buildStreakCard(context),
            const SizedBox(height: 24),
            _buildRecentActivity(sessionProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(SessionProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Today',
            '${provider.todayFocusMinutes} min',
            Icons.today,
            const Color(0xFF66BB6A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total',
            '${provider.totalFocusMinutes} min',
            Icons.timer,
            const Color(0xFF42A5F5),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFFB74D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 12),
          const Text(
            '5 Day Streak',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Keep going! You\'re on fire 🔥',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(SessionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...provider.sessions.take(3).map((session) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: session.type == TimerType.focus
                  ? const Color(0xFF66BB6A)
                  : const Color(0xFFFFB74D),
              child: Icon(
                session.type == TimerType.focus ? Icons.work : Icons.coffee,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(session.label ?? 'Session'),
            subtitle: Text(
              DateFormat('MMM d, h:mm a').format(session.startTime),
            ),
            trailing: Text('${session.duration ~/ 60}m'),
          );
        }).toList(),
      ],
    );
  }
}

// ============================================================================
// ACCOUNT SCREEN
// ============================================================================

class AccountScreen extends HookWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Account'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(authProvider.currentUser!),
          const SizedBox(height: 24),
          _buildGoalsCard(),
          const SizedBox(height: 16),
          _buildSettingsTile(
            context,
            'Settings',
            Icons.settings,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          _buildSettingsTile(
            context,
            'Presets',
            Icons.bookmark,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PresetsScreen()),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => authProvider.logout(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: const Color(0xFF66BB6A),
              child: Text(
                user.name?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name ?? 'User',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Goal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: 0.65, // TODO: Calculate from actual sessions
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF66BB6A)),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '78 / 120 minutes',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// ============================================================================
// LOGIN SCREEN
// ============================================================================

class LoginScreen extends HookWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isSignup = useState(false);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Flow',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Stay focused, stay productive',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              if (authProvider.isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: () async {
                    if (isSignup.value) {
                      await authProvider.signup(
                        emailController.text,
                        passwordController.text,
                      );
                    } else {
                      await authProvider.login(
                        emailController.text,
                        passwordController.text,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(isSignup.value ? 'Sign Up' : 'Login'),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => isSignup.value = !isSignup.value,
                child: Text(
                  isSignup.value
                      ? 'Already have an account? Login'
                      : 'Don\'t have an account? Sign Up',
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => authProvider.loginAnonymously(),
                child: const Text('Continue as Guest'),
              ),
              if (authProvider.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  authProvider.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SETTINGS SCREEN
// ============================================================================

class SettingsScreen extends HookWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: themeProvider.isDarkMode,
            onChanged: (_) => themeProvider.toggleDarkMode(),
          ),
          ListTile(
            title: const Text('Background Theme'),
            subtitle: Text(themeProvider.backgroundTheme),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBackgroundThemeDialog(context, themeProvider),
          ),
          ListTile(
            title: const Text('Accent Color'),
            trailing: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: themeProvider.accentColor,
                shape: BoxShape.circle,
              ),
            ),
            onTap: () => _showColorPicker(context, themeProvider),
          ),
          const SizedBox(height: 24),
          const Text(
            'Notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Get notified when timer ends'),
            value: true, // TODO: Implement
            onChanged: (v) {}, // TODO: Implement
          ),
          SwitchListTile(
            title: const Text('Sound Alerts'),
            subtitle: const Text('Play sound on timer completion'),
            value: true, // TODO: Implement
            onChanged: (v) {}, // TODO: Implement
          ),
        ],
      ),
    );
  }

  void _showBackgroundThemeDialog(
    BuildContext context,
    ThemeProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Background Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Default'),
              value: 'default',
              groupValue: provider.backgroundTheme,
              onChanged: (v) {
                provider.setBackgroundTheme(v!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Gradient'),
              value: 'gradient',
              groupValue: provider.backgroundTheme,
              onChanged: (v) {
                provider.setBackgroundTheme(v!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, ThemeProvider provider) {
    final colors = [
      const Color(0xFF66BB6A),
      const Color(0xFF42A5F5),
      const Color(0xFFFF6B6B),
      const Color(0xFFFFB74D),
      const Color(0xFF9C27B0),
      const Color(0xFF26A69A),
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Accent Color'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) {
            return GestureDetector(
              onTap: () {
                provider.setAccentColor(color);
                Navigator.pop(context);
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color == provider.accentColor
                        ? Colors.white
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ============================================================================
// PRESETS SCREEN
// ============================================================================

class PresetsScreen extends HookWidget {
  const PresetsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final presetProvider = Provider.of<PresetProvider>(context);
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Presets'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPresetDialog(context, presetProvider),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: presetProvider.presets.length,
        itemBuilder: (context, index) {
          final preset = presetProvider.presets[index];
          final isSelected = presetProvider.selectedPreset?.id == preset.id;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: isSelected ? 4 : 1,
            color: isSelected ? const Color(0xFF66BB6A).withOpacity(0.1) : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isSelected
                  ? const BorderSide(color: Color(0xFF66BB6A), width: 2)
                  : BorderSide.none,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                preset.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Focus: ${preset.focusDuration ~/ 60}m  •  Break: ${preset.breakDuration ~/ 60}m  •  Long: ${preset.longBreakDuration ~/ 60}m',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Color(0xFF66BB6A))
                  : null,
              onTap: () {
                presetProvider.selectPreset(preset);
                timerProvider.setCustomDuration(preset.focusDuration);
                Navigator.pop(context);
              },
            ),
          );
        },
      ),
    );
  }

  void _showAddPresetDialog(BuildContext context, PresetProvider provider) {
    final nameController = TextEditingController();
    final focusMinutes = ValueNotifier(25);
    final breakMinutes = ValueNotifier(5);
    final longBreakMinutes = ValueNotifier(15);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Preset'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Preset Name'),
              ),
              const SizedBox(height: 16),
              _buildMinuteSlider('Focus Duration', focusMinutes),
              _buildMinuteSlider('Break Duration', breakMinutes),
              _buildMinuteSlider('Long Break Duration', longBreakMinutes),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final preset = PomodoroPreset(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  focusDuration: focusMinutes.value * 60,
                  breakDuration: breakMinutes.value * 60,
                  longBreakDuration: longBreakMinutes.value * 60,
                );
                provider.addPreset(preset);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildMinuteSlider(String label, ValueNotifier<int> value) {
    return ValueListenableBuilder<int>(
      valueListenable: value,
      builder: (context, val, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label: $val minutes'),
            Slider(
              value: val.toDouble(),
              min: 1,
              max: 60,
              divisions: 59,
              onChanged: (v) => value.value = v.toInt(),
            ),
          ],
        );
      },
    );
  }
}
