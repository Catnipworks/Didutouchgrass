import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_theme.dart';

class ThemeService {
  static const String _themeKey = 'selected_theme';

  // Get current theme
  Future<AppTheme> getCurrentTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeId = prefs.getString(_themeKey) ?? 'brutalist';
    return AppTheme.getThemeById(themeId);
  }

  // Set theme
  Future<void> setTheme(String themeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeId);
  }
}