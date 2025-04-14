import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService with ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  static const String _languageKey = 'isEnglish';
  
  factory LanguageService() {
    return _instance;
  }
  
  LanguageService._internal() {
    _loadLanguagePreference();
  }
  
  bool _isEnglish = false;
  
  bool get isEnglish => _isEnglish;
  
  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnglish = prefs.getBool(_languageKey) ?? false;
      notifyListeners();
      print('Idioma cargado: ${_isEnglish ? 'Inglés' : 'Español'}');
    } catch (e) {
      print('Error al cargar preferencia de idioma: $e');
    }
  }
  
  Future<void> setLanguage(bool value) async {
    if (_isEnglish != value) {
      _isEnglish = value;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_languageKey, value);
        print('Idioma cambiado a: ${value ? 'Inglés' : 'Español'}');
        notifyListeners();
      } catch (e) {
        print('Error al guardar preferencia de idioma: $e');
      }
    }
  }
  
  Future<void> toggleLanguage() async {
    await setLanguage(!_isEnglish);
  }
} 