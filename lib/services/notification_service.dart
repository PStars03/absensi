import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static final _supabase = Supabase.instance.client;
  static StreamSubscription? _notificationSubscription;
  static BuildContext? _context;

  static Future<void> init(BuildContext context) async {
    _context = context;
    
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
      // Use a simple polling or just rely on the dashboard stream to avoid multi-stream deadlocks
      // For now, we removed the background stream here to prevent ANR.
    }
  }

  static void _showInAppNotification(String title, String message) {
    if (_context == null || !_context!.mounted) return;
    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(message),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Future<void> scheduleDeadlineNotification(int id, String title, String body, DateTime deadline) async {
    // 15 minutes before deadline
    final scheduleTime = deadline.subtract(const Duration(minutes: 15));
    
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
    _notificationSubscription?.cancel();
  }
}
