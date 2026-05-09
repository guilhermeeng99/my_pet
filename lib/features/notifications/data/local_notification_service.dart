import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_pet/features/notifications/domain/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Wraps `flutter_local_notifications` so the rest of the app talks to a
/// project-owned interface (CLAUDE.md / Dependencies).
class LocalNotificationService implements NotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _androidChannelId = 'mypet_default';
  static const _androidChannelName = 'my_pet reminders';
  static const _androidChannelDescription =
      'Vaccine and care reminders for your pets.';

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? true;
    }
    return true;
  }

  @override
  Future<bool> hasPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return (await android.areNotificationsEnabled()) ?? false;
    }
    return true;
  }

  @override
  Future<void> scheduleAll({
    required String groupKey,
    required String title,
    required String body,
    required List<DateTime> firings,
  }) async {
    await initialize();
    await cancelGroup(groupKey);

    final now = DateTime.now();
    for (var i = 0; i < firings.length; i++) {
      final fireAt = firings[i];
      if (!fireAt.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        id: _idFor(groupKey, i),
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannelId,
            _androidChannelName,
            channelDescription: _androidChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: groupKey,
      );
    }
  }

  @override
  Future<void> cancelGroup(String groupKey) async {
    // Notification IDs are derived from `groupKey + index`; we conservatively
    // cancel the first 8 slots — plenty for the vaccine 2-firing case and
    // future per-day reminders.
    for (var i = 0; i < 8; i++) {
      await _plugin.cancel(id: _idFor(groupKey, i));
    }
  }

  /// Maps `(groupKey, index)` to a stable 32-bit int that
  /// flutter_local_notifications accepts as an ID.
  int _idFor(String groupKey, int index) {
    final base = groupKey.hashCode & 0x7FFFFFFE;
    return base ^ (index & 0xF);
  }
}
