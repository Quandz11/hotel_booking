import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('vi', 'VN'); // Default to Vietnamese
  
  Locale get locale => _locale;
  
  /// Load saved locale from shared preferences
  Future<void> loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_code') ?? 'vi';
      final countryCode = prefs.getString('country_code') ?? 'VN';
      
      _locale = Locale(languageCode, countryCode);
      notifyListeners();
    } catch (e) {
      print('Error loading locale: $e');
    }
  }
  
  /// Change locale and save to shared preferences
  Future<void> setLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', locale.languageCode);
      await prefs.setString('country_code', locale.countryCode ?? '');
      
      _locale = locale;
      notifyListeners();
    } catch (e) {
      print('Error saving locale: $e');
    }
  }
  
  /// Switch to English
  Future<void> setEnglish() async {
    await setLocale(const Locale('en', 'US'));
  }
  
  /// Switch to Vietnamese
  Future<void> setVietnamese() async {
    await setLocale(const Locale('vi', 'VN'));
  }
  
  /// Check if current locale is English
  bool get isEnglish => _locale.languageCode == 'en';
  
  /// Check if current locale is Vietnamese
  bool get isVietnamese => _locale.languageCode == 'vi';
  
  /// Get display name for current locale
  String get currentLanguageName {
    switch (_locale.languageCode) {
      case 'en':
        return 'English';
      case 'vi':
        return 'Tiếng Việt';
      default:
        return 'Unknown';
    }
  }
}
