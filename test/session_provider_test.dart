import 'dart:io';

import 'package:flow_app/hive/hive_registrar.g.dart';
import 'package:flow_app/models/models.barrel.dart';
import 'package:flow_app/providers/session_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/adapters.dart';

/// Helper to create a completed session with focus and break loops.
Session _makeSession({
  required DateTime startTime,
  required int focusSeconds,
  int breakSeconds = 0,
  String presetName = 'Classic',
}) {
  final loops = <Loop>[
    Loop(
      id: '${startTime.millisecondsSinceEpoch}_focus',
      type: TimerType.focus,
      duration: focusSeconds,
      startTime: startTime,
      endTime: startTime.add(Duration(seconds: focusSeconds)),
      completed: true,
    ),
    if (breakSeconds > 0)
      Loop(
        id: '${startTime.millisecondsSinceEpoch}_break',
        type: TimerType.breakTime,
        duration: breakSeconds,
        startTime: startTime.add(Duration(seconds: focusSeconds)),
        endTime: startTime.add(Duration(seconds: focusSeconds + breakSeconds)),
        completed: true,
      ),
  ];

  return Session(
    id: startTime.millisecondsSinceEpoch.toString(),
    userId: 'test',
    name: 'Test Session',
    targetLoops: 1,
    startTime: startTime,
    endTime: startTime.add(Duration(seconds: focusSeconds + breakSeconds)),
    presetName: presetName,
    loops: loops,
    completed: true,
  );
}

void main() {
  late SessionProvider provider;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    Hive.registerAdapters();
    await Hive.openBox<Session>('sessions');
    await Hive.openBox('settings');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    final box = Hive.box<Session>('sessions');
    await box.clear();
    provider = SessionProvider();
    provider.loadSessions();
  });

  group('empty state', () {
    test('returns zero for all stats when no sessions', () {
      expect(provider.totalFocusMinutes, 0);
      expect(provider.totalFocusSeconds, 0);
      expect(provider.totalBreakMinutes, 0);
      expect(provider.totalBreakSeconds, 0);
      expect(provider.todayFocusMinutes, 0);
      expect(provider.todayFocusSeconds, 0);
      expect(provider.todayBreakMinutes, 0);
      expect(provider.completedSessionCount, 0);
      expect(provider.averageSessionMinutes, 0);
      expect(provider.averageSessionSeconds, 0);
    });

    test('weeklyFocusMinutes returns 7 entries all zero', () {
      final weekly = provider.weeklyFocusMinutes;
      expect(weekly.length, 7);
      expect(weekly.values.every((v) => v == 0), true);
    });

    test('monthlyFocusMinutes returns 30 entries all zero', () {
      final monthly = provider.monthlyFocusMinutes;
      expect(monthly.length, 30);
      expect(monthly.values.every((v) => v == 0), true);
    });

    test('presetBreakdown is empty', () {
      expect(provider.presetBreakdown, isEmpty);
    });

    test('currentStreak is zero', () {
      expect(provider.currentStreak(120), 0);
    });

    test('sessions list is empty', () {
      expect(provider.sessions, isEmpty);
    });
  });

  group('adding sessions via Hive + loadSessions', () {
    test('todayFocusSeconds reflects sessions added today', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 10, 0);
      final session = _makeSession(startTime: today, focusSeconds: 1500);

      final box = Hive.box<Session>('sessions');
      await box.put(session.id, session);
      provider.loadSessions();

      expect(provider.todayFocusSeconds, 1500);
      expect(provider.todayFocusMinutes, 25);
    });

    test('totalFocusSeconds sums all completed sessions', () async {
      final box = Hive.box<Session>('sessions');
      final now = DateTime.now();

      final s1 = _makeSession(
        startTime: now.subtract(const Duration(days: 2)),
        focusSeconds: 600,
      );
      final s2 = _makeSession(
        startTime: now.subtract(const Duration(days: 1)),
        focusSeconds: 900,
      );

      await box.put(s1.id, s1);
      await box.put(s2.id, s2);
      provider.loadSessions();

      expect(provider.totalFocusSeconds, 1500);
      expect(provider.totalFocusMinutes, 25);
      expect(provider.completedSessionCount, 2);
    });

    test('totalBreakSeconds sums break durations', () async {
      final box = Hive.box<Session>('sessions');
      final now = DateTime.now();

      final s1 = _makeSession(
        startTime: now.subtract(const Duration(days: 1)),
        focusSeconds: 600,
        breakSeconds: 300,
      );

      await box.put(s1.id, s1);
      provider.loadSessions();

      expect(provider.totalBreakSeconds, 300);
      expect(provider.totalBreakMinutes, 5);
    });

    test('averageSessionSeconds computes correctly', () async {
      final box = Hive.box<Session>('sessions');
      final now = DateTime.now();

      final s1 = _makeSession(
        startTime: now.subtract(const Duration(days: 2)),
        focusSeconds: 600,
        breakSeconds: 300,
      );
      final s2 = _makeSession(
        startTime: now.subtract(const Duration(days: 1)),
        focusSeconds: 900,
        breakSeconds: 300,
      );

      await box.put(s1.id, s1);
      await box.put(s2.id, s2);
      provider.loadSessions();

      // totalDuration s1 = 900, s2 = 1200, avg = 1050
      expect(provider.averageSessionSeconds, 1050.0);
      // averageMinutes = (15 + 20) / 2 = 17.5
      expect(provider.averageSessionMinutes, 17.5);
    });
  });

  group('weeklyFocusMinutes', () {
    test('counts focus minutes per day for the last 7 days', () async {
      final box = Hive.box<Session>('sessions');
      final now = DateTime.now();
      final twoDaysAgo = DateTime(now.year, now.month, now.day, 14, 0)
          .subtract(const Duration(days: 2));

      // 1500s = 25 min
      final session = _makeSession(
        startTime: twoDaysAgo,
        focusSeconds: 1500,
      );

      await box.put(session.id, session);
      provider.loadSessions();

      final weekly = provider.weeklyFocusMinutes;
      final entries = weekly.entries.toList();

      // The entry 2 days ago (index 4, since 0=6 days ago .. 6=today) should be 25
      expect(entries[4].value, 25);
      // Today should be 0
      expect(entries[6].value, 0);
    });
  });

  group('presetBreakdown', () {
    test('groups focus minutes by preset name', () async {
      final box = Hive.box<Session>('sessions');
      final now = DateTime.now();

      final s1 = _makeSession(
        startTime: now.subtract(const Duration(days: 3)),
        focusSeconds: 1500,
        presetName: 'Classic',
      );
      final s2 = _makeSession(
        startTime: now.subtract(const Duration(days: 2)),
        focusSeconds: 900,
        presetName: 'Light',
      );
      final s3 = _makeSession(
        startTime: now.subtract(const Duration(days: 1)),
        focusSeconds: 1500,
        presetName: 'Classic',
      );

      await box.put(s1.id, s1);
      await box.put(s2.id, s2);
      await box.put(s3.id, s3);
      provider.loadSessions();

      final breakdown = provider.presetBreakdown;
      expect(breakdown['Classic'], 3000); // 1500s + 1500s
      expect(breakdown['Light'], 900);
    });
  });

  group('currentStreak', () {
    test('counts consecutive past days meeting the goal', () async {
      final box = Hive.box<Session>('sessions');
      final now = DateTime.now();

      // Create sessions for yesterday, 2 days ago, 3 days ago meeting 25-min goal
      for (int i = 1; i <= 3; i++) {
        final day = DateTime(now.year, now.month, now.day, 14, 0)
            .subtract(Duration(days: i));
        final session = _makeSession(startTime: day, focusSeconds: 1500);
        await box.put(session.id, session);
      }

      provider.loadSessions();

      // Today not met → starts from yesterday → 3 consecutive days
      expect(provider.currentStreak(25), 3);
    });

    test("today's completed goal counts toward streak", () async {
      final box = Hive.box<Session>('sessions');
      final now = DateTime.now();

      // Today: meets goal
      final today = DateTime(now.year, now.month, now.day, 10, 0);
      final todaySession = _makeSession(startTime: today, focusSeconds: 1500);
      await box.put(todaySession.id, todaySession);

      // Yesterday: meets goal
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdaySession = _makeSession(
        startTime: yesterday,
        focusSeconds: 1500,
      );
      await box.put(yesterdaySession.id, yesterdaySession);

      provider.loadSessions();

      // Today met → count from today → 2 consecutive days
      expect(provider.currentStreak(25), 2);
    });

    test('streak is 1 when only today meets the goal', () async {
      final box = Hive.box<Session>('sessions');
      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day, 10, 0);
      final session = _makeSession(startTime: today, focusSeconds: 1500);
      await box.put(session.id, session);

      provider.loadSessions();

      expect(provider.currentStreak(25), 1);
    });

    test('streak breaks when a day is missed', () async {
      final box = Hive.box<Session>('sessions');
      final now = DateTime.now();

      // Yesterday: meets goal
      final yesterday = DateTime(now.year, now.month, now.day, 14, 0)
          .subtract(const Duration(days: 1));
      final s1 = _makeSession(startTime: yesterday, focusSeconds: 1500);
      await box.put(s1.id, s1);

      // Skip 2 days ago

      // 3 days ago: meets goal
      final threeDaysAgo = DateTime(now.year, now.month, now.day, 14, 0)
          .subtract(const Duration(days: 3));
      final s2 = _makeSession(startTime: threeDaysAgo, focusSeconds: 1500);
      await box.put(s2.id, s2);

      provider.loadSessions();

      expect(provider.currentStreak(25), 1);
    });

    test('streak is zero if yesterday did not meet goal', () async {
      final box = Hive.box<Session>('sessions');
      final now = DateTime.now();

      // Yesterday: below goal (5 min focus, goal is 25)
      final yesterday = DateTime(now.year, now.month, now.day, 14, 0)
          .subtract(const Duration(days: 1));
      final s1 = _makeSession(startTime: yesterday, focusSeconds: 300);
      await box.put(s1.id, s1);

      provider.loadSessions();

      expect(provider.currentStreak(25), 0);
    });
  });

  group('session lifecycle', () {
    test('startSession creates a current session', () {
      provider.startSession(
        userId: 'user1',
        name: 'Work',
        targetLoops: 4,
        presetName: 'Classic',
      );

      expect(provider.isSessionActive, true);
      expect(provider.currentSession, isNotNull);
      expect(provider.currentSession!.name, 'Work');
    });

    test('startLoop adds a loop to the current session', () {
      provider.startSession(
        userId: 'user1',
        name: 'Work',
        targetLoops: 4,
        presetName: 'Classic',
      );
      provider.startLoop(type: TimerType.focus, duration: 1500);

      expect(provider.currentSession!.loops.length, 1);
      expect(provider.currentLoop, isNotNull);
      expect(provider.currentLoop!.type, TimerType.focus);
    });

    test('completeCurrentLoop marks the loop as completed with actual elapsed time', () {
      provider.startSession(
        userId: 'user1',
        name: 'Work',
        targetLoops: 4,
        presetName: 'Classic',
      );
      provider.startLoop(type: TimerType.focus, duration: 1500);
      provider.completeCurrentLoop();

      final loop = provider.currentSession!.loops.first;
      expect(loop.completed, true);
      expect(provider.completedLoopsCount, 1);
      // duration is capped at actual elapsed time (≥ 0, ≤ preset)
      expect(loop.duration, lessThanOrEqualTo(1500));
      expect(loop.duration, greaterThanOrEqualTo(0));
    });

    test('completeCurrentLoop skipped records only elapsed time, not full preset', () {
      provider.startSession(
        userId: 'user1',
        name: 'Work',
        targetLoops: 4,
        presetName: 'Classic',
      );
      provider.startLoop(type: TimerType.focus, duration: 1500);
      // Skip immediately — elapsed should be well under 1500s
      provider.completeCurrentLoop(skipped: true);

      final loop = provider.currentSession!.loops.first;
      expect(loop.completed, true);
      expect(loop.skipped, true);
      // Should NOT record the full 25-minute preset duration
      expect(loop.duration, lessThan(1500));
    });

    test('finishSession moves current session to history', () {
      provider.startSession(
        userId: 'user1',
        name: 'Work',
        targetLoops: 1,
        presetName: 'Classic',
      );
      provider.startLoop(type: TimerType.focus, duration: 1500);
      provider.completeCurrentLoop();
      provider.finishSession();

      expect(provider.isSessionActive, false);
      expect(provider.sessions.length, 1);
      expect(provider.sessions.first.completed, true);
    });

    test('cancelSession clears current session without saving', () {
      provider.startSession(
        userId: 'user1',
        name: 'Work',
        targetLoops: 1,
        presetName: 'Classic',
      );
      provider.cancelSession();

      expect(provider.isSessionActive, false);
      expect(provider.sessions, isEmpty);
    });

    test('finishSession without completeCurrentLoop still records focus time', () {
      // Simulates user pressing "Finish Session" mid-timer
      provider.startSession(
        userId: 'user1',
        name: 'Work',
        targetLoops: 1,
        presetName: 'Classic',
      );
      provider.startLoop(type: TimerType.focus, duration: 1500);
      // Do NOT call completeCurrentLoop — user manually ended early
      provider.finishSession();

      expect(provider.isSessionActive, false);
      expect(provider.sessions.length, 1);
      final session = provider.sessions.first;
      expect(session.completed, true);
      // Loop should be auto-completed with actual elapsed time (≥ 0)
      expect(session.loops.first.completed, true);
      expect(session.focusDuration, greaterThanOrEqualTo(0));
    });
  });

  group('incomplete sessions excluded from stats', () {
    test('incomplete sessions are not counted in stats', () async {
      final box = Hive.box<Session>('sessions');
      final now = DateTime.now();

      // Add an incomplete session
      final incomplete = Session(
        id: 'incomplete',
        userId: 'test',
        name: 'Unfinished',
        targetLoops: 1,
        startTime: DateTime(now.year, now.month, now.day, 10, 0),
        loops: [
          Loop(
            id: 'loop1',
            type: TimerType.focus,
            duration: 1500,
            startTime: DateTime(now.year, now.month, now.day, 10, 0),
            completed: true,
          ),
        ],
        completed: false,
      );

      await box.put(incomplete.id, incomplete);
      provider.loadSessions();

      expect(provider.totalFocusSeconds, 0);
      expect(provider.completedSessionCount, 0);
    });
  });
}
