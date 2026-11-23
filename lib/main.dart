import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/add_shift_page.dart';
import 'pages/statistics_page.dart';
import 'pages/about_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'pages/settings_page.dart';
import 'services/settings_service.dart';
import 'services/notification_service.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/sync_service.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fetpntthxgpqkvglacyx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZldHBudHRoeGdwcWt2Z2xhY3l4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTU0NDg3NzcsImV4cCI6MjExMTAyNDc3N30.4-zeZYxvTtrV7a2DcHqqBAF2_s2fJnPbat6cMapL-DM',
  );

  await SyncService.autoRestoreIfNeeded();
  
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/Sofia'));

  final androidImplementation = notificationsPlugin
    .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

  await androidImplementation?.requestNotificationsPermission();
  await androidImplementation?.requestExactAlarmsPermission();

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('ic_notification');

  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);

  await notificationsPlugin.initialize(settings: initSettings);

  final settings = SettingsService();
  final enabled = await settings.getReminderEnabled();

  if (enabled) {
    final day = await settings.getReminderDay();
    final hour = await settings.getReminderHour();
    final minute = await settings.getReminderMinute();

    await NotificationService().showMonthlyReportReminder(day, hour, minute);
  }

  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    ChangeNotifierProvider(
      create: (_) => themeProvider,
      child: ShiftApp(),
    ),
  );
}

class ShiftApp extends StatelessWidget {
  const ShiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: "Shift Manager",
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('bg', 'BG'),
      ],
      home: HomePage(),
      routes: {
        '/add': (_) => AddShiftPage(),
        '/stats': (_) => StatisticsPage(),
        '/about': (_) => AboutPage(),
        '/settings': (context) => SettingsPage(),
      },
    );
  }
}