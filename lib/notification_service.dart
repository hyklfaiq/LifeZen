import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'lifezen_reminders',
      'LifeZen Reminders',
      channelDescription: 'Task and schedule reminders',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  static Future<void> init() async {
    tz.initializeTimeZones();

    tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(settings: settings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.requestNotificationsPermission();
  }

  // ==========================================================
  // TEST NOTIFICATION
  // ==========================================================

  static Future<void> testNotification() async {
    await _plugin.show(
      id: 999,
      title: 'LifeZen Test',
      body: 'Notifications are working!',
      notificationDetails: _notificationDetails,
    );
  }

  // ==========================================================
  // TASK NOTIFICATION
  // ==========================================================

  static Future<void> scheduleTask({
    required int id,
    required String title,
    required DateTime dateTime,
  }) async {
    // Remind user 10 minutes before the task.
    final reminder = dateTime.subtract(const Duration(minutes: 10));

    if (!reminder.isAfter(DateTime.now())) {
      return;
    }

    await _plugin.zonedSchedule(
      id: id,
      title: 'Upcoming task',
      body: title,
      scheduledDate: tz.TZDateTime.from(reminder, tz.local),
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  // ==========================================================
  // WEEKLY SCHEDULE NOTIFICATION
  // ==========================================================

  static Future<void> scheduleWeekly({
    required int id,
    required String title,
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    int daysUntil = weekday - now.weekday;

    if (daysUntil < 0) {
      daysUntil += 7;
    }

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    ).add(Duration(days: daysUntil));

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    final reminder = scheduled.subtract(const Duration(minutes: 10));

    // If the reminder has already passed, move it to next week.
    if (!reminder.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: 'Upcoming schedule',
      body: title,
      scheduledDate: tz.TZDateTime(
        tz.local,
        scheduled.year,
        scheduled.month,
        scheduled.day,
        scheduled.hour,
        scheduled.minute,
      ).subtract(const Duration(minutes: 10)),
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // ==========================================================
  // CANCEL
  // ==========================================================

  static Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
