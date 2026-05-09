import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/gen/strings.g.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: BlocConsumer<AuthBloc, AuthState>(
            listenWhen: (prev, curr) => curr is AuthErrorState,
            listener: (context, state) {
              if (state is AuthErrorState) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text(_messageFor(state.failure))),
                  );
              }
            },
            builder: (context, state) {
              final loading = state is AuthLoading;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  Center(
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: AppRadii.brXL,
                      ),
                      child: Icon(
                        Icons.pets_rounded,
                        size: 80,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    t.auth.signInTitle,
                    style: theme.textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    t.auth.signInSubtitle,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: palette.onSurfaceMuted),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(flex: 3),
                  FilledButton.icon(
                    onPressed: loading
                        ? null
                        : () => context
                            .read<AuthBloc>()
                            .add(const GoogleSignInRequested()),
                    icon: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login_rounded),
                    label: Text(t.auth.signInWithGoogle),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _messageFor(Failure failure) {
    return switch (failure) {
      AuthNetworkFailure() => t.auth.errors.network,
      AuthCancelledFailure() => t.auth.errors.cancelled,
      _ => t.auth.errors.unknown,
    };
  }
}
