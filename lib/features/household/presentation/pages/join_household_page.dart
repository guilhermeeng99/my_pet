import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/app_card.dart';
import 'package:my_pet/app/widgets/app_primary_button.dart';
import 'package:my_pet/app/widgets/screen_scaffold.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/household/presentation/cubit/join_household_cubit.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class JoinHouseholdPage extends StatelessWidget {
  const JoinHouseholdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => JoinHouseholdCubit(repository: sl()),
      child: const _JoinHouseholdView(),
    );
  }
}

class _JoinHouseholdView extends StatefulWidget {
  const _JoinHouseholdView();

  @override
  State<_JoinHouseholdView> createState() => _JoinHouseholdViewState();
}

class _JoinHouseholdViewState extends State<_JoinHouseholdView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return ScreenScaffold(
      title: t.household.join.title,
      body: BlocConsumer<JoinHouseholdCubit, JoinHouseholdState>(
        listener: (context, state) {
          if (state is JoinHouseholdJoined) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t.household.join.successSubtitle)),
            );
            context.go('/home');
          }
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              Text(
                t.household.join.subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: palette.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                    TextInputFormatter.withFunction(
                      (old, n) =>
                          n.copyWith(text: n.text.toUpperCase()),
                    ),
                  ],
                  style: theme.textTheme.headlineMedium?.copyWith(
                    letterSpacing: 4,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: t.household.join.codePlaceholder,
                    hintStyle: theme.textTheme.headlineMedium?.copyWith(
                      letterSpacing: 4,
                      color: palette.onSurfaceFaint,
                    ),
                  ),
                  onChanged: (_) {
                    final cubit = context.read<JoinHouseholdCubit>();
                    if (cubit.state is! JoinHouseholdIdle) cubit.reset();
                  },
                ),
              ),
              if (state is JoinHouseholdError ||
                  state is JoinHouseholdInvalidLength) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _errorMessage(state),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.danger,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                icon: PhosphorIconsBold.signIn,
                label: t.household.join.submit,
                loading: state is JoinHouseholdSubmitting,
                onPressed: state is JoinHouseholdSubmitting
                    ? null
                    : () => _onSubmit(context),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onSubmit(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    final user = switch (auth) {
      AuthAuthenticated(:final user) => user,
      AuthNeedsHousehold(:final user) => user,
      _ => null,
    };
    if (user == null) return;
    unawaited(
      context.read<JoinHouseholdCubit>().submit(
            code: _controller.text,
            userId: user.uid,
          ),
    );
  }

  String _errorMessage(JoinHouseholdState state) {
    if (state is JoinHouseholdInvalidLength) {
      return t.household.errors.invalidLength;
    }
    if (state is JoinHouseholdError) {
      return _failureMessage(state.failure);
    }
    return '';
  }

  String _failureMessage(Failure failure) {
    return switch (failure) {
      InviteNotFoundFailure() => t.household.errors.inviteNotFound,
      InviteExpiredFailure() => t.household.errors.inviteExpired,
      InviteAlreadyUsedFailure() => t.household.errors.inviteAlreadyUsed,
      HouseholdFullFailure() => t.household.errors.householdFull,
      AlreadyInHouseholdFailure() => t.household.errors.alreadyInHousehold,
      _ => t.household.errors.generic,
    };
  }
}
