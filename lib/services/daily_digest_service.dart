import 'package:fintracker/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class DailyDigestService {
  static const int _digestId = 1000;

  static Future<void> schedule({int hour = 8, int minute = 0}) async {
    if (kIsWeb) return;
    try {
      final hasPermission = await NotificationService().requestPermission();
      if (!hasPermission) return;
      tz.initializeTimeZones();
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      final plugin = NotificationService().plugin;
      await plugin.zonedSchedule(
        _digestId,
        'Daily Financial Digest',
        'Tap to see your daily spending summary.',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_digest',
            'Daily Digest',
            channelDescription: 'Morning financial summary',
            importance: Importance.low,
            priority: Priority.low,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily_digest',
      );
    } catch (e) {
      debugPrint('Daily digest schedule failed: $e');
    }
  }

  static Future<void> cancel() async {
    try {
      await NotificationService().plugin.cancel(_digestId);
    } catch (e) {
      debugPrint('Daily digest cancel failed: $e');
    }
  }

}
