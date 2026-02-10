import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _notifications.initialize(settings);
  }

  static Future<void> scheduleAthan({
    required int id,
    required String title,
    required DateTime scheduledTime,
    required String soundFile,
  }) async {
    await _notifications.zonedSchedule(
      id,
      'کاتی $title',
      'کاتی بانگ هاتووە',
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'athan_channel',
          'بانگ',
          channelDescription: 'ئاگادارکردنەوەی کاتی بانگ',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound(
              soundFile.replaceAll('.mp3', '')),
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelAthan(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
