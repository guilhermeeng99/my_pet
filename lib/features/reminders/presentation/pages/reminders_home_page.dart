import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/router/app_router.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/app_bottom_nav.dart';
import 'package:my_pet/app/widgets/app_card.dart';
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

/// Reminders tab. Matches the Home layout: ScreenScaffold + greeting/empty
/// card + sectioned list. The Phase 1 stub is gone; the FAB is replaced by
/// a primary button inside the card (empty state) or a trailing "Add
/// another" FeatureListCard (loaded), which mirrors how Pets handles its
/// add flow.
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
          key: ValueKey('reminders-$householdId'),
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
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
            RemindersListEmpty() => ListView(
                padding: EdgeInsets.only(
                  top: AppSpacing.sm,
                  bottom: AppBottomNav.reservedSpace(context) + AppSpacing.md,
                ),
                children: [
                  _QuickAddReminderCard(
                    onPressed: () => context.push(AppRoutes.reminderCreate),
                  ),
                ],
              ),
            RemindersListLoaded() => _LoadedList(state: state),
            RemindersListError() => ListView(
                padding: EdgeInsets.only(
                  top: AppSpacing.sm,
                  bottom: AppBottomNav.reservedSpace(context) + AppSpacing.md,
                ),
                children: [
                  FeatureListCard(
                    icon: PhosphorIconsRegular.warning,
                    title: t.common.retry,
                    subtitle: t.reminders.errors.loadFailed,
                    onTap: () =>
                        context.read<RemindersListCubit>().start(householdId),
                  ),
                ],
              ),
          };
        },
      ),
    );
  }
}

/// Empty-state hero card — same pattern as `_QuickAddCard` on Home so the
/// two tabs feel like sibling surfaces.
class _QuickAddReminderCard extends StatelessWidget {
  const _QuickAddReminderCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: AppRadii.brMd,
                ),
                child: Icon(
                  PhosphorIconsBold.bell,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  t.reminders.empty.title,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            t.reminders.empty.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.onSurfaceMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: t.reminders.addReminder,
            icon: PhosphorIconsBold.plus,
            onPressed: onPressed,
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
      padding: EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppBottomNav.reservedSpace(context) + AppSpacing.md,
      ),
      children: [
        _SummaryStrip(state: state),
        const SizedBox(height: AppSpacing.lg),
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
        const SizedBox(height: AppSpacing.sm),
        FeatureListCard(
          icon: PhosphorIconsBold.plus,
          title: t.reminders.addReminder,
          onTap: () => context.push(AppRoutes.reminderCreate),
        ),
      ],
    );
  }
}

/// At-a-glance numbers above the sections so the user immediately sees
/// what's pressing without scrolling.
class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.state});
  final RemindersListLoaded state;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: PhosphorIconsBold.bell,
            label: t.reminders.sections.today,
            value: '${state.today.length}',
            accent: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            icon: PhosphorIconsBold.warning,
            label: t.reminders.sections.overdue,
            value: '${state.overdue.length}',
            accent: palette.danger,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            icon: PhosphorIconsBold.clock,
            label: t.reminders.sections.thisWeek,
            value: '${state.thisWeek.length}',
            accent: palette.warning,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: palette.outline, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.onSurfaceMuted,
            ),
          ),
        ],
      ),
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
        SectionHeader(title: title),
        const SizedBox(height: AppSpacing.sm),
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
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
