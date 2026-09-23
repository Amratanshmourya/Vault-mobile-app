import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeType _themeType = ThemeType.system;

  ThemeType get themeType => _themeType;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(AppConstants.keyThemeMode);
      if (saved != null) {
        _themeType = ThemeType.values.firstWhere(
          (e) => e.name == saved,
          orElse: () => ThemeType.system,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setTheme(ThemeType type) async {
    _themeType = type;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyThemeMode, type.name);
    } catch (_) {}
  }

  ThemeMode get themeMode {
    switch (_themeType) {
      case ThemeType.system:
        return ThemeMode.system;
      case ThemeType.light:
        return ThemeMode.light;
      case ThemeType.dark:
      case ThemeType.amoled:
        return ThemeMode.dark;
    }
  }

  ThemeData getLightTheme() => AppTheme.lightTheme();

  ThemeData getDarkTheme() =>
      AppTheme.darkTheme(isAmoled: _themeType == ThemeType.amoled);
}
