import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  Future<void> loadTheme() async {
    final mode = await SettingsService().getThemeMode();

    if (mode == "dark") {
      _themeMode = ThemeMode.dark;
    } else if (mode == "system") {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }

    notifyListeners();
  }

  Future<void> setTheme(String mode) async {
    await SettingsService().setThemeMode(mode);
    await loadTheme();
  }
}