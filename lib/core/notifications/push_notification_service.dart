import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Minimal push / local-notification service.
/// Wraps [FlutterLocalNotificationsPlugin] for basic in-app alerts.
/// Real FCM integration is intentionally excluded per project scope.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const _androidChannel = AndroidNotificationChannel(
    'betooth_general',
    'Betooth',
    description: 'Notificações gerais do Betooth',
    importance: Importance.defaultImportance,
  );

  static const _androidDetails = AndroidNotificationDetails(
    'betooth_general',
    'Betooth',
    channelDescription: 'Notificações gerais do Betooth',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: '@mipmap/ic_launcher',
  );

  static const _notificationDetails = NotificationDetails(
    android: _androidDetails,
  );

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_androidChannel);

    _initialized = true;
  }

  Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    if (!_initialized) await initialize();
    await _plugin.show(id, title, body, _notificationDetails);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
