import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../shared/enums/enums.barrel.dart';

/// Callback type for notification action buttons.
typedef NotificationActionCallback = void Function(String actionId);

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Set this from the widget layer so notification actions can control the timer.
  NotificationActionCallback? onActionReceived;

  static const int _timerNotificationId = 1;
  static const int _completionNotificationId = 2;

  static const String _timerChannelId = 'timer_controls';
  static const String _timerChannelName = 'Timer Controls';
  static const String _timerChannelDesc =
      'Ongoing notification with timer controls';

  static const String _alertChannelId = 'timer_alerts';
  static const String _alertChannelName = 'Timer Alerts';
  static const String _alertChannelDesc = 'Notifications for timer completion';

  // Action IDs
  static const String actionStop = 'stop';
  static const String actionPlayPause = 'play_pause';
  static const String actionSkip = 'skip';
  static const String actionReset = 'reset';

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      linux: linuxSettings,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
  }

  Future<bool> requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? false;
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final actionId = response.actionId;
    if (actionId != null && onActionReceived != null) {
      onActionReceived!(actionId);
    }
  }

  // ---------------------------------------------------------------------------
  // Audio
  // ---------------------------------------------------------------------------

  Future<void> playCompletionSound(
    SoundType sound, {
    String? customSoundPath,
  }) async {
    if (sound == SoundType.none) return;

    try {
      if (sound == SoundType.custom && customSoundPath != null) {
        await _audioPlayer.play(DeviceFileSource(customSoundPath));
      } else {
        final assetPath = _assetForSound(sound);
        if (assetPath != null) {
          await _audioPlayer.play(AssetSource(assetPath));
        }
      }
    } catch (e) {
      log('Error playing sound: $e');
    }
  }

  String? _assetForSound(SoundType sound) {
    switch (sound) {
      case SoundType.bell:
        return 'sounds/bell.mp3';
      case SoundType.digital:
        return 'sounds/digital.mp3';
      case SoundType.bird:
        return 'sounds/bird.mp3';
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Persistent timer notification (ongoing with action buttons)
  // ---------------------------------------------------------------------------

  Future<void> showTimerNotification({
    required String title,
    required String body,
    required bool isRunning,
  }) async {
    final details = AndroidNotificationDetails(
      _timerChannelId,
      _timerChannelName,
      channelDescription: _timerChannelDesc,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(actionStop, 'Stop'),
        AndroidNotificationAction(
          actionPlayPause,
          isRunning ? 'Pause' : 'Play',
        ),
        const AndroidNotificationAction(actionSkip, 'Skip'),
        const AndroidNotificationAction(actionReset, 'Reset'),
      ],
    );

    await _notifications.show(
      id: _timerNotificationId,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: details),
    );
  }

  Future<void> cancelTimerNotification() async {
    await _notifications.cancel(id: _timerNotificationId);
  }

  // ---------------------------------------------------------------------------
  // Completion notification (with sound & vibration)
  // ---------------------------------------------------------------------------

  Future<void> showCompletionNotification({
    required String title,
    required String body,
    bool playDefaultSound = false,
  }) async {
    final details = AndroidNotificationDetails(
      _alertChannelId,
      _alertChannelName,
      channelDescription: _alertChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: playDefaultSound,
      enableVibration: true,
    );

    await _notifications.show(
      id: _completionNotificationId,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: details),
    );
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
