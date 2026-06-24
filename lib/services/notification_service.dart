import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static final _supabase = Supabase.instance.client;
  static RealtimeChannel? _notificationChannel;

  static Future<void> init(BuildContext context) async {
    // Initialize Local Notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _notificationsPlugin.initialize(initSettings);

    // Request permissions for Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Setup Realtime Listener for new notifications
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      _notificationChannel?.unsubscribe();
      _notificationChannel = _supabase.channel('public:notifications').onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final newNotification = payload.newRecord;
            final title = newNotification['title'] ?? 'Notifikasi Baru';
            final message = newNotification['message'] ?? 'Anda memiliki pemberitahuan baru.';
            showLocalNotification(DateTime.now().millisecond, title, message);
          }).subscribe();
    }
  }

  static Future<void> scheduleDeadlineNotification(int id, String title, String body, DateTime deadline) async {
    // 5 minutes before deadline
    final scheduleTime = deadline.subtract(const Duration(minutes: 5));
    
    // If the schedule time is in the past, don't schedule
    if (scheduleTime.isBefore(DateTime.now())) return;

    // We can't use full timezone scheduling easily without timezone package, 
    // so we will use a simple delayed schedule using Future.delayed for prototype
    // Or we can just use the scheduled notification if we setup timezone package.
    // For simplicity without timezone setup:
    final delay = scheduleTime.difference(DateTime.now());
    
    Future.delayed(delay, () {
      showLocalNotification(id, title, body);
    });
  }

  static Future<void> showLocalNotification(int id, String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'deadline_channel',
      'Tugas Deadline',
      channelDescription: 'Pengingat batas waktu tugas',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(id, title, body, details);
  }

  static void dispose() {
    _notificationChannel?.unsubscribe();
  }
}
