import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _kLocaleKey = 'app_locale';
  final SharedPreferences _prefs;
  Locale _locale;

  LocaleProvider(this._prefs)
      : _locale = Locale(_prefs.getString(_kLocaleKey) ?? 'en');

  Locale get locale => _locale;

  bool get isFirstRun => !_prefs.containsKey(_kLocaleKey);

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    _prefs.setString(_kLocaleKey, locale.languageCode);
    notifyListeners();
  }
}
