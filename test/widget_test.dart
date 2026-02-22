// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flow_app/app.dart';
import 'package:flow_app/hive/hive.barrel.dart';
import 'package:flow_app/models/models.barrel.dart';
import 'package:flow_app/providers/providers.barrel.dart';
import 'package:flow_app/services/services.barrel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hive_ce_flutter/adapters.dart';

void main() {
  testWidgets('FlowApp boots', (WidgetTester tester) async {
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
          sessionProvider.finishSession();
          timerProvider.resetLoop();
          timerProvider.resetTimer();
          break;
        case NotificationService.actionPlayPause:
          if (timerProvider.isRunning) {
            timerProvider.pauseTimer();
          } else {
            // Resume timer if session exists, otherwise notification shouldn't appear
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
    // This app doesn't use the default counter template; just verify it renders.
    await tester.pumpWidget(
      App(
        themeProvider: themeProvider,
        presetProvider: presetProvider,
        sessionProvider: sessionProvider,
        timerProvider: timerProvider,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flow'), findsWidgets);
  });
}
