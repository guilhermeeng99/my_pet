import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/router/app_router.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/app_primary_button.dart';
import 'package:my_pet/app/widgets/feature_list_card.dart';
import 'package:my_pet/app/widgets/screen_scaffold.dart';
import 'package:my_pet/app/widgets/section_header.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/reminders/domain/entities/reminder.dart';
import 'package:my_pet/features/reminders/presentation/cubit/reminders_list_cubit.dart';
import 'package:my_pet/features/reminders/presentation/cubit/reminders_list_state.dart';
import 'package:my_pet/features/reminders/presentation/widgets/reminder_card.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Reminders tab. Replaces the Phase-1 stub: lists active reminders grouped
/// by Overdue / Today / This week / Later, with a FAB to create new ones.
class RemindersHomePage extends StatelessWidget {
  const RemindersHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final householdId = switch (authState) {
          AuthAuthenticated(:final user) => user.householdId,
          _ => null,
        };
        if (householdId == null) {
          return ScreenScaffold(
            title: t.nav.reminders,
            titleSize: ScreenTitleSize.large,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return BlocProvider<RemindersListCubit>(
          create: (_) =>
              RemindersListCubit(repository: sl())..start(householdId),
          child: _RemindersView(householdId: householdId),
        );
      },
    );
  }
}

class _RemindersView extends StatelessWidget {
  const _RemindersView({required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: t.nav.reminders,
      titleSize: ScreenTitleSize.large,
      body: BlocBuilder<RemindersListCubit, RemindersListState>(
        builder: (context, state) {
          return switch (state) {
            RemindersListInitial() || RemindersListLoading() =>
              const Center(child: CircularProgressIndicator()),
            RemindersListEmpty() => const _EmptyState(),
            RemindersListLoaded() => _LoadedList(state: state),
            RemindersListError() => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: FeatureListCard(
                  icon: PhosphorIconsRegular.warning,
                  title: t.common.retry,
                  subtitle: t.reminders.errors.loadFailed,
                  onTap: () =>
                      context.read<RemindersListCubit>().start(householdId),
                ),
              ),
          };
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.reminderCreate),
        icon: const Icon(PhosphorIconsBold.plus),
        label: Text(t.reminders.addReminder),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            PhosphorIconsBold.bell,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            t.reminders.empty.title,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            t.reminders.empty.subtitle,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: palette.onSurfaceMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: t.reminders.addReminder,
            icon: PhosphorIconsBold.plus,
            onPressed: () => context.push(AppRoutes.reminderCreate),
          ),
        ],
      ),
    );
  }
}

class _LoadedList extends StatelessWidget {
  const _LoadedList({required this.state});

  final RemindersListLoaded state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      children: [
        _Section(
          title: t.reminders.sections.overdue,
          reminders: state.overdue,
        ),
        _Section(
          title: t.reminders.sections.today,
          reminders: state.today,
        ),
        _Section(
          title: t.reminders.sections.thisWeek,
          reminders: state.thisWeek,
        ),
        _Section(
          title: t.reminders.sections.later,
          reminders: state.later,
        ),
        const SizedBox(height: 80), // FAB clearance
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.reminders});

  final String title;
  final List<Reminder> reminders;

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        SectionHeader(title: title),
        const SizedBox(height: AppSpacing.xs),
        for (final r in reminders)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ReminderCard(
              reminder: r,
              onTap: () => context.push(
                AppRoutes.reminderEditFor(r.id),
                extra: r,
              ),
              onMarkDone: () =>
                  context.read<RemindersListCubit>().markDone(r),
            ),
          ),
      ],
    );
  }
}
