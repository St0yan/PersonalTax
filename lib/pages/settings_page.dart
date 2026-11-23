import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool reminderEnabled = false;
  int selectedDay = 1;
  TimeOfDay selectedTime = TimeOfDay(hour: 9, minute: 0);

  String selectedSound = "train";
  bool vibrationEnabled = true;
  String selectedChannel = "report_channel";


  @override
    void initState() {
      super.initState();
      _loadSettings();
    }

    Future<void> _loadSettings() async {
    final settings = SettingsService();

    reminderEnabled = await settings.getReminderEnabled();
    selectedDay = await settings.getReminderDay();
    final hour = await settings.getReminderHour();
    final minute = await settings.getReminderMinute();
    selectedSound = await settings.getNotificationSound();
    vibrationEnabled = await settings.getNotificationVibration();
    selectedChannel = await settings.getNotificationChannel();


    selectedTime = TimeOfDay(hour: hour, minute: minute);

    setState(() {});
  }


  Future<void> _pickDay() async {
    final controller = TextEditingController(text: selectedDay.toString());

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Избери ден от месеца"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: "1 - 28/29/30/31"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value >= 1 && value <= 31) {
                setState(() => selectedDay = value);
              }
              Navigator.pop(context);
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
    await SettingsService().setReminderDay(selectedDay);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (time != null) {
      setState(() => selectedTime = time);
    }

    await SettingsService().setReminderHour(selectedTime.hour);
    await SettingsService().setReminderMinute(selectedTime.minute);
  }

  Future<void> _toggleReminder(bool value) async {
    setState(() => reminderEnabled = value);

    if (value) {
      await NotificationService().showMonthlyReportReminder(
        selectedDay,
        selectedTime.hour,
        selectedTime.minute,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Месечното напомняне е активирано")),
      );
    } else {
      await NotificationService().cancelReportReminder();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Напомнянето е изключено")),
      );
    }
    await SettingsService().setReminderEnabled(value);
  }

  Future<String?> _pickSound() async {
    return showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text("Избери звук"),
        children: [
          SimpleDialogOption(
            child: Text("train"),
            onPressed: () => Navigator.pop(context, "train"),
          ),
          SimpleDialogOption(
            child: Text("soft"),
            onPressed: () => Navigator.pop(context, "soft"),
          ),
          SimpleDialogOption(
            child: Text("alarm"),
            onPressed: () => Navigator.pop(context, "alarm"),
          ),
          SimpleDialogOption(
            child: Text("bell"),
            onPressed: () => Navigator.pop(context, "bell"),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickChannel() async {
    return showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text("Избери канал"),
        children: [
          SimpleDialogOption(
            child: Text("report_channel"),
            onPressed: () => Navigator.pop(context, "report_channel"),
          ),
          SimpleDialogOption(
            child: Text("important_channel"),
            onPressed: () => Navigator.pop(context, "important_channel"),
          ),
          SimpleDialogOption(
            child: Text("silent_channel"),
            onPressed: () => Navigator.pop(context, "silent_channel"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTheme() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    final result = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text("Избери тема"),
        children: [
          SimpleDialogOption(
            child: Text("Светла"),
            onPressed: () => Navigator.pop(context, "light"),
          ),
          SimpleDialogOption(
            child: Text("Тъмна"),
            onPressed: () => Navigator.pop(context, "dark"),
          ),
          SimpleDialogOption(
            child: Text("Системна"),
            onPressed: () => Navigator.pop(context, "system"),
          ),
        ],
      ),
    );

    if (result != null) {
      await themeProvider.setTheme(result);
      setState(() {});
    }
  }

  String _themeLabel(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).themeMode;

    switch (theme) {
      case ThemeMode.dark:
        return "Тъмна";
      case ThemeMode.system:
        return "Системна";
      default:
        return "Светла";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Настройки")),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: Text("Месечно напомняне за отчет"),
            value: reminderEnabled,
            onChanged: _toggleReminder,
          ),

          ListTile(
            title: Text("Ден от месеца"),
            subtitle: Text("$selectedDay"),
            trailing: Icon(Icons.edit),
            onTap: reminderEnabled ? _pickDay : null,
          ),

          ListTile(
            title: Text("Час на известието"),
            subtitle: Text(selectedTime.format(context)),
            trailing: Icon(Icons.access_time),
            onTap: reminderEnabled ? _pickTime : null,
          ),

          Divider(height: 40),

          ListTile(
            title: Text("Звук на известието"),
            subtitle: Text(selectedSound),
            trailing: Icon(Icons.music_note),
            onTap: () async {
              final sound = await _pickSound();
              if (sound != null) {
                setState(() => selectedSound = sound);
                await SettingsService().setNotificationSound(sound);
              }
            },
          ),

          SwitchListTile(
            title: Text("Вибрация"),
            value: vibrationEnabled,
            onChanged: (value) async {
              setState(() => vibrationEnabled = value);
              await SettingsService().setNotificationVibration(value);
            },
          ),

          ListTile(
            title: Text("Канал за известия"),
            subtitle: Text(selectedChannel),
            trailing: Icon(Icons.waves),
            onTap: () async {
              final channel = await _pickChannel();
              if (channel != null) {
                setState(() => selectedChannel = channel);
                await SettingsService().setNotificationChannel(channel);
              }
            },
          ),
          ListTile(
            title: Text("Тема"),
            subtitle: Text(_themeLabel(context)),
            trailing: Icon(Icons.color_lens),
            onTap: _pickTheme,
          ),
        ],
      ),
    );
  }
}