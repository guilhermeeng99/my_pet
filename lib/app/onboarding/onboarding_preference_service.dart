import 'package:shared_preferences/shared_preferences.dart';

/// Tracks one-time onboarding checkpoints that should survive sign-out so
/// users aren't re-prompted on every fresh session. Currently only the
/// notification-permission prompt is gated here; future onboarding steps
/// (e.g. tips tour) plug in via additional keys.
class OnboardingPreferenceService {
  OnboardingPreferenceService({required SharedPreferences prefs})
      : _prefs = prefs;

  static const String _notificationsAskedKey =
      'onboarding.notificationsAsked';

  final SharedPreferences _prefs;

  bool get notificationsPromptShown =>
      _prefs.getBool(_notificationsAskedKey) ?? false;

  Future<void> markNotificationsPromptShown() =>
      _prefs.setBool(_notificationsAskedKey, true);

  Future<void> reset() => _prefs.remove(_notificationsAskedKey);
}
