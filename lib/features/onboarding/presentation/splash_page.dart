import 'package:flutter/material.dart';

import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/pet_mascot.dart';
import 'package:my_pet/core/constants/app_constants.dart';
import 'package:my_pet/gen/strings.g.dart';

/// First screen the user sees while the auth state resolves. Mirrors the
/// Welcome layout (mascot in a tinted square + headline + tagline) so the
/// hand-off into onboarding feels continuous rather than a hard cut. The
/// router flips to Login or Home as soon as `AuthBloc` emits — no manual
/// nav here.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

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
              const Spacer(flex: 3),
              Center(
                child: Container(
                  width: 168,
                  height: 168,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: AppRadii.brXL,
                  ),
                  alignment: Alignment.center,
                  child: const PetMascot(size: 132),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                AppConstants.appName,
                style: theme.textTheme.displayLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                t.app.tagline,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: palette.onSurfaceMuted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 4),
              Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
