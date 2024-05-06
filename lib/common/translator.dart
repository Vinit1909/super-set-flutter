import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Translator {
  static Map<String, String> _localizedStrings = {};

  static Future<void> loadLanguage(String locale) async {
    String jsonString = await rootBundle.loadString('i18n/$locale.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    _localizedStrings = jsonMap.map<String, String>(
      (key, value) => MapEntry(key, value.toString()),
    );
  }

  static String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  static Future<String> getCurrentLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedLanguage') ?? 'EN';  // Assuming 'en' as default
  }

  static Future<void> setCurrentLanguage(String languageCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', languageCode);
    await loadLanguage(languageCode);
  }
}
