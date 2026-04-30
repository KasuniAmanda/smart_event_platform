import 'package:flutter/foundation.dart' show kIsWeb; // ✅ Essential for Web check
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 🛑 If we are on Chrome, we stop here. Web doesn't support these mobile settings.
    if (kIsWeb) {
      debugPrint("Notifications: Initializing skipped (Web Target)");
      return;
    }

    tz_data.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // ✅ Use 'dynamic' to bypass the Chrome compiler's argument check
    await (_notifications as dynamic).initialize(settings);

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Member 4: Schedule a notification for an event
  Future<void> scheduleEventReminder(int id, String title, DateTime scheduledDate) async {
    // 🛑 Web browsers do not support scheduled native notifications
    if (kIsWeb) return;

    final notificationTime = scheduledDate.subtract(const Duration(hours: 1));
    final finalTime = notificationTime.isBefore(DateTime.now()) 
        ? DateTime.now().add(const Duration(seconds: 5)) 
        : notificationTime;

    try {
      // ✅ We cast to 'dynamic' so Chrome doesn't crash on 'zonedSchedule' or the interpretation enum
      final dynamic mobileNotifications = _notifications;
      
      await mobileNotifications.zonedSchedule(
        id,
        'Event Reminder: $title',
        'Your event is starting soon! Don\'t forget your QR code.',
        tz.TZDateTime.from(finalTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'event_channel', 
            'Event Reminders',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // We use dynamic access here to prevent the "getter not defined" error on Web
        uiLocalNotificationDateInterpretation: dynamic, 
      );
    } catch (e) {
      debugPrint("Notification Error: $e");
    }
  }
}

// Simple helper to avoid import errors on 'debugPrint'
void debugPrint(String message) => print(message);