import 'package:flutter/material.dart';

import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';

/// Phase 0 placeholder welcome screen. Demonstrates that the design tokens
/// render correctly: hero card, oversized headline, pill primary button.
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
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: AppRadii.brXL,
                  ),
                  child: Icon(
                    Icons.pets_rounded,
                    size: 96,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                "Welcome! Let's care for your pets together.",
                style: theme.textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Track vaccinations, vet visits, weight and every memory — '
                'shared with your whole family.',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: palette.onSurfaceMuted),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              FilledButton(
                onPressed: () {
                  // Phase 1: trigger Google sign-in.
                },
                child: const Text('Continue'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
