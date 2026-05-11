import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/pet_mascot.dart';
import 'package:my_pet/core/constants/app_constants.dart';
import 'package:my_pet/features/startup/presentation/cubit/startup_cubit.dart';
import 'package:my_pet/gen/strings.g.dart';

/// First screen the user sees on cold start. Owns the splash layout (mascot
/// in a tinted square + app wordmark + tagline) and a determinate progress
/// bar driven by [StartupCubit]. The router redirect keeps the user here
/// until startup emits a terminal state; once that happens it forwards to
/// welcome (no session) or home/setup (session present).
class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  @override
  void initState() {
    super.initState();
    // Defer to the first frame so the splash paints before we await the auth
    // stream — otherwise a cached Firebase session resolves synchronously and
    // we'd skip the splash entirely (jarring on warm starts).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(sl<StartupCubit>().initialize());
    });
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
              BlocBuilder<StartupCubit, StartupState>(
                builder: (context, state) {
                  final progress =
                      state is StartupLoading ? state.progress : null;
                  return ClipRRect(
                    borderRadius: AppRadii.brSm,
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      color: theme.colorScheme.primary,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
