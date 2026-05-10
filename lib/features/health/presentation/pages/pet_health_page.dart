import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/app_card.dart';
import 'package:my_pet/app/widgets/app_primary_button.dart';
import 'package:my_pet/app/widgets/circle_icon_button.dart';
import 'package:my_pet/features/health/domain/entities/health_event.dart';
import 'package:my_pet/features/health/domain/entities/health_event_type.dart';
import 'package:my_pet/features/health/presentation/cubit/health_timeline_cubit.dart';
import 'package:my_pet/features/health/presentation/cubit/health_timeline_state.dart';
import 'package:my_pet/features/health/presentation/pages/health_event_form_page.dart';
import 'package:my_pet/features/health/presentation/widgets/health_event_card.dart';
import 'package:my_pet/features/health/presentation/widgets/health_event_type_meta.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PetHealthArgs {
  const PetHealthArgs({
    required this.householdId,
    required this.petId,
    required this.petName,
  });

  final String householdId;
  final String petId;
  final String petName;
}

class PetHealthPage extends StatelessWidget {
  const PetHealthPage({
    required this.householdId,
    required this.petId,
    required this.petName,
    super.key,
  });

  final String householdId;
  final String petId;
  final String petName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HealthTimelineCubit>(
      create: (_) => HealthTimelineCubit(repository: sl())
        ..start(householdId, petId),
      child: _HealthView(
        householdId: householdId,
        petId: petId,
        petName: petName,
      ),
    );
  }
}

class _HealthView extends StatelessWidget {
  const _HealthView({
    required this.householdId,
    required this.petId,
    required this.petName,
  });

  final String householdId;
  final String petId;
  final String petName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  CircleIconButton(
                    icon: PhosphorIconsBold.arrowLeft,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      t.health.tabTitle,
                      style: theme.textTheme.headlineLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const _TypeFilter(),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: BlocBuilder<HealthTimelineCubit, HealthTimelineState>(
                  builder: (context, state) {
                    return switch (state) {
                      HealthTimelineInitial() || HealthTimelineLoading() =>
                        const Center(child: CircularProgressIndicator()),
                      HealthTimelineEmpty() => _Empty(
                          filter: state.filter,
                          onAdd: () => _openForm(context),
                        ),
                      HealthTimelineLoaded() => _Loaded(state: state),
                      HealthTimelineError() => Center(
                          child: Text(t.health.errors.loadFailed),
                        ),
                    };
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(PhosphorIconsBold.plus),
        label: Text(t.health.addEvent),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {HealthEvent? existing}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HealthEventFormPage(
          householdId: householdId,
          petId: petId,
          petName: petName,
          existing: existing,
        ),
      ),
    );
  }
}

class _TypeFilter extends StatelessWidget {
  const _TypeFilter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HealthTimelineCubit, HealthTimelineState>(
      buildWhen: (a, b) => _filterOf(a) != _filterOf(b),
      builder: (context, state) {
        final current = _filterOf(state);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: t.health.filters.all,
                selected: current == null,
                onTap: () =>
                    context.read<HealthTimelineCubit>().setFilter(null),
              ),
              const SizedBox(width: AppSpacing.xs),
              for (final type in HealthEventType.values) ...[
                _FilterChip(
                  label: HealthEventTypeMeta.label(type),
                  icon: HealthEventTypeMeta.icon(type),
                  selected: current == type,
                  onTap: () =>
                      context.read<HealthTimelineCubit>().setFilter(type),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        );
      },
    );
  }

  HealthEventType? _filterOf(HealthTimelineState s) => switch (s) {
        HealthTimelineLoaded(:final filter) => filter,
        HealthTimelineEmpty(:final filter) => filter,
        _ => null,
      };
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Material(
      color: selected
          ? theme.colorScheme.primary
          : palette.surfaceMuted,
      borderRadius: AppRadii.brPill,
      child: InkWell(
        borderRadius: AppRadii.brPill,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : palette.onSurfaceMuted,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : palette.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd, required this.filter});
  final VoidCallback onAdd;
  final HealthEventType? filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      children: [
        Icon(
          PhosphorIconsBold.heart,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          filter == null
              ? t.health.empty.title
              : t.health.empty.filteredTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          t.health.empty.subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: palette.onSurfaceMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppPrimaryButton(
          label: t.health.addEvent,
          icon: PhosphorIconsBold.plus,
          onPressed: onAdd,
        ),
      ],
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state});
  final HealthTimelineLoaded state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final fmt = NumberFormat.decimalPattern();
    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        if (state.totalCost > 0)
          AppCard(
            child: Row(
              children: [
                Icon(
                  PhosphorIconsBold.coins,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  t.health.totalCost,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: palette.onSurfaceMuted),
                ),
                const Spacer(),
                Text(
                  fmt.format(state.totalCost),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        for (final e in state.events) ...[
          HealthEventCard(
            event: e,
            onTap: () => _openEdit(context, e),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Future<void> _openEdit(BuildContext context, HealthEvent event) async {
    // We surface the args through the existing route from PetDetail; here
    // we can synthesize them from the loaded event.
    final args = PetHealthArgs(
      householdId: event.householdId,
      petId: event.petId,
      petName: '',
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HealthEventFormPage(
          householdId: args.householdId,
          petId: args.petId,
          petName: args.petName,
          existing: event,
        ),
      ),
    );
  }
}
