import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../main.dart';
import 'settings_service.dart';

class NotificationService {
  Future<void> showMonthlyReportReminder(int day, int hour, int minute) async {
    final settings = SettingsService();

    final sound = await settings.getNotificationSound();
    final vibration = await settings.getNotificationVibration();
    final channel = await settings.getNotificationChannel();

    await notificationsPlugin.zonedSchedule(
      id: 1,
      title: "Напомняне за отчет",
      body: "Не забравяй да изпратиш месечния отчет!",
      scheduledDate: _nextDate(day, hour, minute),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel, // ← вече използва избрания канал
          'Report Reminders',
          channelDescription: 'Напомняния за месечен отчет',
          icon: 'ic_notification',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(sound),
          enableVibration: vibration,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  tz.TZDateTime _nextDate(int day, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month + 1,
        day,
        hour,
        minute,
      );
    }

    return scheduled;
  }

  Future<void> cancelReportReminder() async {
    await notificationsPlugin.cancel(id: 1);
  }
}