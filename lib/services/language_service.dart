import 'package:flutter/foundation.dart';

class LanguageService with ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  
  factory LanguageService() {
    return _instance;
  }
  
  LanguageService._internal();
  
  bool _isEnglish = false;
  
  bool get isEnglish => _isEnglish;
  
  void setLanguage(bool value) {
    _isEnglish = value;
    notifyListeners();
  }
  
  void toggleLanguage() {
    _isEnglish = !_isEnglish;
    notifyListeners();
  }
} 