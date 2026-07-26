import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app's active UI language. Independent of auth state so the
/// language picker works even before login; synced to the user's
/// `preferredLanguage` profile field once signed in (see ProfileScreen).
class LocaleController extends ChangeNotifier {
  static const _prefsKey = 'car_nanny_locale';

  Locale locale = const Locale('en');

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored == 'ar') {
      locale = const Locale('ar');
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (locale == newLocale) return;
    locale = newLocale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, newLocale.languageCode);
  }
}
