import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Local, privacy-first notification service.
/// No server, no analytics — notifications are generated on-device.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );
    await _notifications.initialize(settings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      if (status.isDenied) {
        final result = await Permission.notification.request();
        return result.isGranted;
      }
      return status.isGranted;
    }
    return true;
  }

  Future<void> showDueBill({required String title, String? body}) async {
    try {
      if (!_initialized) await init();
      final hasPermission = await requestPermission();
      if (!hasPermission) return;

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'due_bill_channel',
        'Due Bill Alerts',
        channelDescription: 'Notifications for recurring bills that are due',
        importance: Importance.high,
        priority: Priority.high,
      );
      const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch % 2147483647,
        title,
        body ?? 'A recurring payment is due today',
        details,
      );
    } catch (_) {
      // Notifications are best-effort; never break transaction processing
    }
  }
}
