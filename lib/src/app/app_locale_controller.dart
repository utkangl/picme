import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global locale controller for the app.
///
/// `null` means "follow system language". Any concrete [Locale] overrides the
/// system locale until the user switches back.
class AppLocaleController {
  static const _prefsKey = 'picme_locale_code';

  static final ValueNotifier<Locale?> locale = ValueNotifier<Locale?>(null);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    locale.value = code == null || code.isEmpty ? null : Locale(code);
  }

  static Future<void> setLocale(Locale? nextLocale) async {
    final prefs = await SharedPreferences.getInstance();
    locale.value = nextLocale;
    if (nextLocale == null) {
      await prefs.remove(_prefsKey);
      return;
    }
    await prefs.setString(_prefsKey, nextLocale.languageCode);
  }
}
