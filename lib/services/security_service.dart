import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../settings_provider.dart';

class SecurityService {
  final SettingsProvider settings;
  Timer? _alertTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  SecurityService({required this.settings}) {
    _initializeNotifications();
    settings.addListener(_onSettingsChanged);
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(settings: initSettings);
  }

  void _onSettingsChanged() {
    stopMonitoring();
    if (settings.notificationsEnabled && settings.serverUrl.isNotEmpty) {
      startMonitoring();
    }
  }

  void startMonitoring() {
    if (settings.serverUrl.isEmpty) return;

    final interval = Duration(seconds: settings.checkIntervalSeconds.toInt());

    _alertTimer = Timer.periodic(interval, (timer) async {
      try {
        final baseUrl = settings.serverUrl.replaceAll(RegExp(r'/$'), '');
        final response = await http.get(Uri.parse('$baseUrl/api/alerts/poll'));

        if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
          final data = jsonDecode(response.body);

          // ✅ Safely get the list of alerts (or empty list if missing)
          final List alerts = data['alerts'] ?? [];

          for (var alert in alerts) {
            // ✅ Provide safe fallbacks if fields are missing
            final eventType = alert['event']?.toString() ?? 'Unknown Alert';
            final cameraId = alert['camera_id']?.toString() ?? 'Camera 01';

            triggerAlarmSequence(eventType, cameraId);
          }
        }
      } catch (e) {
        // Use debugPrint to avoid lint warnings (optional)
        debugPrint("Network error checking alerts: $e");
      }
    });
  }

  void triggerAlarmSequence(String eventType, String cameraId) async {
    if (!settings.notificationsEnabled) return;

    // Play alarm sound if not set to silent
    if (settings.alarmRingtone != 'Silent') {
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
    }

    // Show system notification
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'security_alerts_channel',
      'Critical Security Alerts',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: '🚨 SECURITY ALERT: $cameraId',
      body: 'Detected: $eventType. Open app immediately.',
      notificationDetails: platformDetails,
    );
  }

  void stopMonitoring() {
    _alertTimer?.cancel();
    _audioPlayer.stop();
  }
}