import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService with ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  static const String _themeKey = 'isDarkMode';
  
  factory ThemeService() {
    return _instance;
  }
  
  ThemeService._internal() {
    _loadThemePreference();
  }
  
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      notifyListeners();
    } catch (e) {
      print('Error loading theme preference: $e');
    }
  }
  
  Future<void> setTheme(bool value) async {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_themeKey, value);
      } catch (e) {
        print('Error saving theme preference: $e');
      }
      notifyListeners();
    }
  }
  
  Future<void> toggleTheme() async {
    await setTheme(!_isDarkMode);
  }
} 