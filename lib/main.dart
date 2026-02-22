// Flow - A Beautiful Pomodoro Timer App
// Production-ready Flutter app with Supabase integration (mock), Provider + Hooks state management

import 'package:barrel_annotation/barrel_annotation.dart';
import 'package:flow_app/models/models.barrel.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app.dart';
import 'hive/hive_registrar.g.dart';
import 'providers/providers.barrel.dart';
import 'services/notification_service.dart';

// ============================================================================
// MAIN APP ENTRY POINT
// ============================================================================
@BarrelConfig(exclude: ['lib/lib.barrel.dart', 'lib/excluded/**'])
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapters();

  // Open Hive boxes
  await Hive.openBox('settings');
  await Hive.openBox<Session>('sessions');
  await Hive.openBox<PomodoroPreset>('presets');
  await Hive.openBox('auth');

  // TODO: Initialize Supabase
  // await Supabase.initialize(
  //   url: 'YOUR_SUPABASE_URL',
  //   anonKey: 'YOUR_SUPABASE_ANON_KEY',
  // );

  // Initialize notifications
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();

  // Load persisted state from Hive
  final themeProvider = ThemeProvider();
  themeProvider.loadPreferences();

  final presetProvider = PresetProvider();
  presetProvider.loadPresets();

  final sessionProvider = SessionProvider();
  sessionProvider.loadSessions();

  final timerProvider = TimerProvider();

  // Wire notification action buttons to timer controls
  NotificationService.instance.onActionReceived = (actionId) {
    switch (actionId) {
      case NotificationService.actionStop:
        sessionProvider.completeCurrentSession();
        timerProvider.resetLoop();
        timerProvider.resetTimer();
        sessionProvider.clearCurrentSession();
        break;
      case NotificationService.actionPlayPause:
        if (timerProvider.isRunning) {
          timerProvider.pauseTimer();
        } else {
          final preset = presetProvider.selectedPreset;
          sessionProvider.startSession(
            userId: 'current_user',
            type: timerProvider.currentType,
            duration: timerProvider.totalSeconds,
            presetName: preset.name,
          );
          timerProvider.startTimer();
        }
        break;
      case NotificationService.actionSkip:
        sessionProvider.clearCurrentSession();
        timerProvider.resetTimer();
        if (timerProvider.currentType == TimerType.focus) {
          timerProvider.setTimerType(TimerType.breakTime);
        } else {
          timerProvider.incrementLoop();
          timerProvider.setTimerType(TimerType.focus);
        }
        break;
      case NotificationService.actionReset:
        timerProvider.resetTimer();
        break;
    }
  };

  runApp(
    App(
      themeProvider: themeProvider,
      presetProvider: presetProvider,
      sessionProvider: sessionProvider,
      timerProvider: timerProvider,
    ),
  );
}



// ============================================================================
// MAIN SCREEN WITH BOTTOM NAVIGATION
// ============================================================================



// ============================================================================
// TIMER SCREEN (MAIN)
// ============================================================================

// ============================================================================
// CIRCULAR PROGRESS PAINTER
// ============================================================================


// ============================================================================
// TIME PICKER SHEET
// ============================================================================


// ============================================================================
// HISTORY SCREEN
// ============================================================================

// ============================================================================
// DASHBOARD SCREEN
// ============================================================================


// ============================================================================
// ACCOUNT SCREEN
// ============================================================================

// ============================================================================
// LOGIN SCREEN
// ============================================================================


// ============================================================================
// SETTINGS SCREEN
// ============================================================================

// ============================================================================
// PRESETS SCREEN
// ============================================================================
