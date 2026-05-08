import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:my_pet/app/router/app_router.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_spacing.dart';

/// First screen the user sees while the app finishes booting. In Phase 1
/// it will branch on AuthState to either send the user to Login or Home.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Phase 0: just route to Welcome. Phase 1 will branch on auth.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      context.go(AppRoutes.welcome);
    });
  }

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
            Text('my_pet', style: theme.textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Loading...',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: context.palette.onSurfaceMuted),
            ),
          ],
        ),
      ),
    );
  }
}
