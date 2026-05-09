import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/router/app_router.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/features/pets/domain/entities/species.dart';
import 'package:my_pet/features/vaccinations/domain/entities/vaccination.dart';
import 'package:my_pet/features/vaccinations/domain/entities/vaccination_status.dart';
import 'package:my_pet/features/vaccinations/presentation/cubit/vaccinations_list_cubit.dart';
import 'package:my_pet/features/vaccinations/presentation/widgets/vaccination_meta.dart';
import 'package:my_pet/gen/strings.g.dart';

/// Vaccinations list for a single pet, grouped by status.
class PetVaccinationsPage extends StatelessWidget {
  const PetVaccinationsPage({
    required this.householdId,
    required this.petId,
    required this.species,
    super.key,
  });

  final String householdId;
  final String petId;
  final Species species;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VaccinationsListCubit>(
      create: (_) =>
          sl<VaccinationsListCubit>()..start(householdId, petId),
      child: _View(
        householdId: householdId,
        petId: petId,
        species: species,
      ),
    );
  }
}

class _View extends StatelessWidget {
  const _View({
    required this.householdId,
    required this.petId,
    required this.species,
  });

  final String householdId;
  final String petId;
  final Species species;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.vaccinations.tabTitle)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: Text(t.vaccinations.addVaccine),
        onPressed: () => context.push(
          '${AppRoutes.petDetailBase}/$petId/vaccinations/new',
          extra: VaccinationFormArgs(
            householdId: householdId,
            petId: petId,
            species: species,
          ),
        ),
      ),
      body: BlocBuilder<VaccinationsListCubit, VaccinationsListState>(
        builder: (context, state) {
          return switch (state) {
            VaccinationsListLoading() || VaccinationsListInitial() =>
              const Center(child: CircularProgressIndicator()),
            VaccinationsListError(failure: final f) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    f.message ?? t.auth.errors.unknown,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            VaccinationsListLoaded(:final grouped) =>
              grouped.values.every((l) => l.isEmpty)
                  ? const _EmptyState()
                  : _Sections(
                      grouped: grouped,
                      householdId: householdId,
                      petId: petId,
                      species: species,
                    ),
          };
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.vaccines_rounded,
              size: 96,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              t.vaccinations.empty.title,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              t.vaccinations.empty.subtitle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Sections extends StatelessWidget {
  const _Sections({
    required this.grouped,
    required this.householdId,
    required this.petId,
    required this.species,
  });

  final Map<VaccinationStatus, List<Vaccination>> grouped;
  final String householdId;
  final String petId;
  final Species species;

  @override
  Widget build(BuildContext context) {
    final order = [
      VaccinationStatus.overdue,
      VaccinationStatus.dueSoon,
      VaccinationStatus.upToDate,
      VaccinationStatus.noNextDose,
    ];
    final theme = Theme.of(context);
    final sections = <Widget>[];
    for (final status in order) {
      final items = grouped[status] ?? const <Vaccination>[];
      if (items.isEmpty) continue;
      sections
        ..add(Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(
                VaccinationStatusMeta.iconFor(status),
                color: VaccinationStatusMeta.colorFor(status, theme.colorScheme),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                VaccinationStatusMeta.label(status),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ))
        ..addAll(items.map((v) => _VaccinationTile(
              vaccination: v,
              status: status,
              species: species,
            )));
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: sections,
    );
  }
}

class _VaccinationTile extends StatelessWidget {
  const _VaccinationTile({
    required this.vaccination,
    required this.status,
    required this.species,
  });

  final Vaccination vaccination;
  final VaccinationStatus status;
  final Species species;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat.yMMMd();
    final color = VaccinationStatusMeta.colorFor(status, theme.colorScheme);
    final subtitle = _subtitle(dateFmt);

    return ListTile(
      leading: Icon(VaccinationStatusMeta.iconFor(status), color: color),
      title: Text(vaccination.name),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: context.palette.onSurfaceMuted),
      ),
      onTap: () => context.push(
        '${AppRoutes.petDetailBase}/${vaccination.petId}/vaccinations/${vaccination.id}/edit',
        extra: VaccinationFormArgs(
          householdId: vaccination.householdId,
          petId: vaccination.petId,
          species: species,
          existing: vaccination,
        ),
      ),
    );
  }

  String _subtitle(DateFormat fmt) {
    final next = vaccination.nextDueDate;
    final applied = fmt.format(vaccination.appliedDate);
    if (next == null) return applied;
    final now = DateTime.now().toUtc();
    final diff = next.difference(now).inDays;
    if (diff < 0) {
      return '$applied · ${t.vaccinations.overdueBy(days: -diff)}';
    }
    return '$applied · ${t.vaccinations.dueIn(days: diff)}';
  }
}

/// Carried via `GoRouterState.extra` for the new/edit routes.
class VaccinationFormArgs {
  const VaccinationFormArgs({
    required this.householdId,
    required this.petId,
    required this.species,
    this.existing,
  });

  final String householdId;
  final String petId;
  final Species species;
  final Vaccination? existing;
}
