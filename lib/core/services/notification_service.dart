import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _instance = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _instance.initialize(settings);
  }

  static Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'erp_channel',
      'ERP Notifications',
      channelDescription: 'Sync and alert notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _instance.show(id, title, body, details, payload: payload);
  }
}
