import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/onboarding/onboarding_preference_service.dart';
import 'package:my_pet/app/router/app_router.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/app_primary_button.dart';
import 'package:my_pet/app/widgets/app_secondary_button.dart';
import 'package:my_pet/features/notifications/domain/notification_service.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Permission-priming step shown once after a user lands on a real household.
/// Tapping "Enable" triggers the OS prompt; both actions mark the prompt as
/// shown so the router lets the user through to /home.
class NotificationPermissionPage extends StatefulWidget {
  const NotificationPermissionPage({super.key});

  @override
  State<NotificationPermissionPage> createState() =>
      _NotificationPermissionPageState();
}

class _NotificationPermissionPageState
    extends State<NotificationPermissionPage> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Users who already granted notifications in a previous install (or out
    // of band via OS settings) should not be re-prompted; just record the
    // flag and let the router send them home.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final granted = await sl<NotificationService>().hasPermission();
      if (granted && mounted) {
        await _finish();
      }
    });
  }

  Future<void> _enable() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await sl<NotificationService>().requestPermission();
    } on Object {
      // Permission failures are non-fatal — we still advance past the prompt
      // so the user isn't trapped. Re-prompting lives under Settings.
    }
    await _finish();
  }

  Future<void> _skip() async {
    if (_busy) return;
    setState(() => _busy = true);
    await _finish();
  }

  Future<void> _finish() async {
    await sl<OnboardingPreferenceService>().markNotificationsPromptShown();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: AppRadii.brXL,
                  ),
                  child: Icon(
                    PhosphorIconsBold.bellRinging,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                t.onboarding.notifications.title,
                style: theme.textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                t.onboarding.notifications.subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: palette.onSurfaceMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              AppPrimaryButton(
                label: t.onboarding.notifications.enable,
                loading: _busy,
                onPressed: _enable,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppSecondaryButton(
                label: t.onboarding.notifications.skip,
                onPressed: _busy ? null : _skip,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
