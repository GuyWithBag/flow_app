// Flow - A Beautiful Pomodoro Timer App
// Production-ready Flutter app with Supabase integration (mock), Provider + Hooks state management

import 'package:barrel_annotation/barrel_annotation.dart';
import 'package:flutter/material.dart';
import 'package:hive_local_storage/hive_local_storage.dart';

import 'app.dart';
import 'providers/providers.dart';

// ============================================================================
// MAIN APP ENTRY POINT
// ============================================================================
@BarrelConfig(exclude: ['lib/lib.barrel.dart', 'lib/excluded/**'])
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local storage
  await LocalStorage.initialize();

  // TODO: Initialize Supabase
  // await Supabase.initialize(
  //   url: 'YOUR_SUPABASE_URL',
  //   anonKey: 'YOUR_SUPABASE_ANON_KEY',
  // );

  // TODO: Initialize notifications
  // await NotificationService.initialize();

  // Load persisted state from Hive
  final themeProvider = ThemeProvider();
  await themeProvider.loadPreferences();

  final presetProvider = PresetProvider();
  await presetProvider.loadPresets();

  final sessionProvider = SessionProvider();
  await sessionProvider.loadSessions();

  runApp(
    App(
      themeProvider: themeProvider,
      presetProvider: presetProvider,
      sessionProvider: sessionProvider,
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
