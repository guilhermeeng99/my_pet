import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/app_card.dart';
import 'package:my_pet/app/widgets/screen_scaffold.dart';
import 'package:my_pet/app/widgets/section_header.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/pets/domain/entities/species.dart';
import 'package:my_pet/features/pets/presentation/widgets/species_meta.dart';
import 'package:my_pet/features/stats/presentation/cubit/insights_cubit.dart';
import 'package:my_pet/features/stats/presentation/cubit/insights_state.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Replaces the Phase 1 stub. Shows the household's pet count + species
/// breakdown and reminder backlog. Health-spending and vaccine insights
/// land alongside a household-wide aggregation pass.
class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

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
            title: t.nav.stats,
            titleSize: ScreenTitleSize.large,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return BlocProvider<InsightsCubit>(
          create: (_) =>
              InsightsCubit(pets: sl(), reminders: sl())..start(householdId),
          child: const _InsightsView(),
        );
      },
    );
  }
}

class _InsightsView extends StatelessWidget {
  const _InsightsView();

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: t.nav.stats,
      titleSize: ScreenTitleSize.large,
      body: BlocBuilder<InsightsCubit, InsightsState>(
        builder: (context, state) {
          return switch (state) {
            InsightsInitial() || InsightsLoading() =>
              const Center(child: CircularProgressIndicator()),
            InsightsLoaded(:final snapshot) => _Body(snapshot: snapshot),
          };
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.snapshot});
  final InsightsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      children: [
        SectionHeader(title: t.stats.sections.household),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: PhosphorIconsBold.pawPrint,
                label: t.home.stats.pets,
                value: '${snapshot.totalPets}',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                icon: PhosphorIconsBold.tag,
                label: t.home.stats.species,
                value: '${snapshot.bySpecies.length}',
              ),
            ),
          ],
        ),
        if (snapshot.bySpecies.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              children: [
                for (final entry in snapshot.bySpecies.entries) ...[
                  _SpeciesRow(species: entry.key, count: entry.value),
                  if (entry.key != snapshot.bySpecies.keys.last)
                    const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(title: t.stats.sections.reminders),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: PhosphorIconsBold.bell,
                label: t.stats.totalActive,
                value: '${snapshot.activeReminders}',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                icon: PhosphorIconsBold.warning,
                label: t.stats.overdue,
                value: '${snapshot.overdueReminders}',
                tone: _StatTone.danger,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                icon: PhosphorIconsBold.clock,
                label: t.stats.dueThisWeek,
                value: '${snapshot.dueThisWeek}',
                tone: _StatTone.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _StatTone { neutral, warning, danger }

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.tone = _StatTone.neutral,
  });

  final IconData icon;
  final String label;
  final String value;
  final _StatTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final accent = switch (tone) {
      _StatTone.danger => palette.danger,
      _StatTone.warning => palette.warning,
      _StatTone.neutral => theme.colorScheme.primary,
    };
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

class _SpeciesRow extends StatelessWidget {
  const _SpeciesRow({required this.species, required this.count});

  final Species species;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            PhosphorIconsBold.pawPrint,
            color: palette.onSurfaceMuted,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              SpeciesMeta.label(species),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text('$count', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
