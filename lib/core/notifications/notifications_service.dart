import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationsService {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  /// Stable Android channel id used by the plugin.
  static const _channelId = 'pawvault_reminders';
  static const _channelName = 'Pet care reminders';

  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    tz_data.initializeTimeZones();

    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(iOS: ios, android: android));

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId, _channelName,
      description: 'Vaccine, medication and vet visit reminders for your pet.',
      importance: Importance.high,
    ));
  }

  /// Requests OS-level permission. Returns true if granted.
  Future<bool> requestPermission() async {
    await init();

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(alert: true, badge: true, sound: true);
      final ok = granted ?? false;
      await _persist(ok);
      return ok;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      final ok = status.isGranted;
      await _persist(ok);
      return ok;
    }

    return false;
  }

  Future<bool> isEnabled() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool('notifications_granted') ?? false;
  }

  Future<void> _persist(bool ok) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('notifications_granted', ok);
  }

  /// Schedules a one-off notification for a future date/time.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    await init();
    if (when.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id, title, body,
      tz.TZDateTime.from(when, tz.local),
      const NotificationDetails(
        iOS: DarwinNotificationDetails(),
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          channelDescription: 'Vaccine, medication and vet visit reminders for your pet.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelAll() => _plugin.cancelAll();

  /// Fires a one-shot test notification immediately.
  Future<void> sendTest() async {
    await init();
    await _plugin.show(
      99999,
      'Notifications on 🐾',
      "You'll get reminders for vaccines and doses.",
      const NotificationDetails(
        iOS: DarwinNotificationDetails(),
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          channelDescription: 'Vaccine, medication and vet visit reminders for your pet.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// Convenience: schedule a vaccine reminder 7 days before due date at 9 AM.
  Future<void> scheduleVaccineReminder({
    required String vaccineId,
    required String vaccineName,
    required String petName,
    required DateTime dueAt,
  }) async {
    final when = DateTime(dueAt.year, dueAt.month, dueAt.day, 9, 0)
        .subtract(const Duration(days: 7));
    await schedule(
      id: vaccineId.hashCode,
      title: "$petName's $vaccineName booster is due in a week",
      body: 'Book a vet appointment to stay on track.',
      when: when,
    );
  }

  /// Convenience: schedule a med dose reminder at the given dose time.
  Future<void> scheduleDoseReminder({
    required String medId,
    required String medName,
    required String petName,
    required DateTime doseAt,
  }) => schedule(
        id: medId.hashCode,
        title: 'Time for $medName',
        body: 'Give $petName their dose.',
        when: doseAt,
      );
}
