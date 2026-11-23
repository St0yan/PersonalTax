import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String keyReminderEnabled = "reminder_enabled";
  static const String keyReminderDay = "reminder_day";
  static const String keyReminderHour = "reminder_hour";
  static const String keyReminderMinute = "reminder_minute";

  static const String keyNotificationSound = "notification_sound";
  static const String keyNotificationVibration = "notification_vibration";
  static const String keyNotificationChannel = "notification_channel";

  static const String keyThemeMode = "theme_mode";

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyThemeMode) ?? "light";
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyThemeMode, mode);
  }

  Future<bool> getReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyReminderEnabled) ?? false;
  }

  Future<void> setReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyReminderEnabled, value);
  }

  Future<int> getReminderDay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keyReminderDay) ?? 1;
  }

  Future<void> setReminderDay(int day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyReminderDay, day);
  }

  Future<int> getReminderHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keyReminderHour) ?? 9;
  }

  Future<void> setReminderHour(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyReminderHour, hour);
  }

  Future<int> getReminderMinute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keyReminderMinute) ?? 0;
  }

  Future<void> setReminderMinute(int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyReminderMinute, minute);
  }

  // 🔊 SOUND
  Future<String> getNotificationSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyNotificationSound) ?? "train";
  }

  Future<void> setNotificationSound(String sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyNotificationSound, sound);
  }

  // 📳 VIBRATION
  Future<bool> getNotificationVibration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyNotificationVibration) ?? true;
  }

  Future<void> setNotificationVibration(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyNotificationVibration, value);
  }

  // 📡 CHANNEL
  Future<String> getNotificationChannel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyNotificationChannel) ?? "report_channel";
  }

  Future<void> setNotificationChannel(String channel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyNotificationChannel, channel);
  }
}