import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:my_pet/app/router/app_router.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/app_primary_button.dart';
import 'package:my_pet/app/widgets/pet_mascot.dart';
import 'package:my_pet/gen/strings.g.dart';

/// Onboarding entry point. Mascot at the top, oversized headline, supportive
/// subtitle, full-width pill CTA at the bottom. The mascot is a programmatic
/// placeholder — see specs/design.md "Illustrations".
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

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
              const Center(child: PetMascot(size: 200)),
              const SizedBox(height: AppSpacing.xl),
              Text(
                t.onboarding.welcomeTitle,
                style: theme.textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                t.onboarding.welcomeSubtitle,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: palette.onSurfaceMuted),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              AppPrimaryButton(
                label: t.common.kContinue,
                onPressed: () => context.go(AppRoutes.login),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
