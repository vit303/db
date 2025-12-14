import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  String _fontFamily = 'Roboto';
  double _fontSize = 16.0;
  Locale _locale = const Locale('ru', 'RU');
  bool _isDarkMode = false;
  bool _isLoaded = false; // Важно: изначально false

  SettingsProvider() {
    _loadFromPrefs();
  }

  String get fontFamily => _fontFamily;
  double get fontSize => _fontSize;
  Locale get locale => _locale;
  bool get isDarkMode => _isDarkMode;
  bool get isLoaded => _isLoaded;

  void setFontFamily(String family) {
    _fontFamily = family;
    _saveToPrefs();
    notifyListeners();
  }

  void setFontSize(double size) {
    _fontSize = size;
    _saveToPrefs();
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    _saveToPrefs();
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    _fontFamily = prefs.getString('fontFamily') ?? 'Roboto';

    // Безопасное чтение fontSize
    final rawSize = prefs.get('fontSize');
    if (rawSize is num) {
      _fontSize = rawSize.toDouble();
    } else {
      _fontSize = 16.0;
    }

    final langCode = prefs.getString('languageCode') ?? 'ru';
    final countryCode = prefs.getString('countryCode') ?? 'RU';
    _locale = Locale(langCode, countryCode);

    _isDarkMode = prefs.getBool('isDarkMode') ?? false;

    _isLoaded = true; // Только теперь говорим, что готовы
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontFamily', _fontFamily);
    await prefs.setDouble('fontSize', _fontSize);
    await prefs.setString('languageCode', _locale.languageCode);
    await prefs.setString('countryCode', _locale.countryCode ?? '');
    await prefs.setBool('isDarkMode', _isDarkMode);
  }
}