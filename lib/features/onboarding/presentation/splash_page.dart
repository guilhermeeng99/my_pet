import 'package:flutter/material.dart';

import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/pet_mascot.dart';
import 'package:my_pet/gen/strings.g.dart';

/// First screen the user sees while the auth state resolves. The router
/// redirects to Login or Home as soon as `AuthBloc` emits — no manual
/// navigation here.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PetMascot(size: 96),
            const SizedBox(height: AppSpacing.lg),
            Text(t.app.name, style: theme.textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.md),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
