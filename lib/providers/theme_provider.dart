import 'package:flutter/material.dart';
import '../models/app_theme.dart';
import '../services/theme_service.dart';

class ThemeProvider extends ChangeNotifier {
  AppTheme _currentTheme = AppTheme.standard;
  final ThemeService _themeService = ThemeService();

  AppTheme get currentTheme => _currentTheme;

  // Load theme on app start
  Future<void> loadTheme() async {
    _currentTheme = await _themeService.getCurrentTheme();
    notifyListeners();
  }

  // Change theme
  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    await _themeService.setTheme(theme.id);
    notifyListeners();
  }
}