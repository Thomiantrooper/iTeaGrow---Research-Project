import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key for storing language preference in SharedPreferences
const String _languagePreferenceKey = 'app_language_preference';

/// Loads the saved language preference from local storage
Future<String> _loadLanguagePreference() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_languagePreferenceKey) ?? 'en';
}

/// Saves the language preference to local storage
Future<void> _saveLanguagePreference(String languageCode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_languagePreferenceKey, languageCode);
}

/// Provider for managing language persistence
/// Reads from SharedPreferences on initialization and saves on changes
final persistentLocaleProvider = StateNotifierProvider<_LocaleNotifier, Locale>((ref) {
  return _LocaleNotifier();
});

/// Notifier for managing locale state with persistence
class _LocaleNotifier extends StateNotifier<Locale> {
  _LocaleNotifier() : super(const Locale('en')) {
    _loadSavedLanguage();
  }

  /// Load the saved language preference from disk
  Future<void> _loadSavedLanguage() async {
    final languageCode = await _loadLanguagePreference();
    state = Locale(languageCode);
  }

  /// Update the locale and save to disk
  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _saveLanguagePreference(locale.languageCode);
  }
}
