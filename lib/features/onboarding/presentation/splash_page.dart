import 'package:flutter/material.dart';

import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
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
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pets_rounded,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(t.app.name, style: theme.textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              t.common.loading,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: context.palette.onSurfaceMuted),
            ),
          ],
        ),
      ),
    );
  }
}
