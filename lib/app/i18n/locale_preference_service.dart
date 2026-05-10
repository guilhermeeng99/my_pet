import 'package:my_pet/gen/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's manually-chosen locale across launches. When no value
/// is stored, the app falls back to the OS locale via
/// [LocaleSettings.useDeviceLocale]. The DI registers this as a singleton so
/// the bootstrap and the settings UI talk to the same instance.
class LocalePreferenceService {
  LocalePreferenceService({required SharedPreferences prefs}) : _prefs = prefs;

  static const String _key = 'locale.override';

  final SharedPreferences _prefs;

  AppLocale? read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    for (final locale in AppLocale.values) {
      if (locale.languageTag == raw) return locale;
    }
    return null;
  }

  Future<void> write(AppLocale locale) =>
      _prefs.setString(_key, locale.languageTag);

  Future<void> clear() => _prefs.remove(_key);
}
