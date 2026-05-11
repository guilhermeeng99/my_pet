import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/router/app_router.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/app_card.dart';
import 'package:my_pet/app/widgets/circle_icon_button.dart';
import 'package:my_pet/app/widgets/feature_list_card.dart';
import 'package:my_pet/app/widgets/section_header.dart';
import 'package:my_pet/app/widgets/status_badge.dart';
import 'package:my_pet/features/pets/domain/entities/species.dart';
import 'package:my_pet/features/vaccinations/domain/entities/vaccination.dart';
import 'package:my_pet/features/vaccinations/domain/entities/vaccination_status.dart';
import 'package:my_pet/features/vaccinations/presentation/cubit/vaccinations_list_cubit.dart';
import 'package:my_pet/features/vaccinations/presentation/widgets/vaccination_meta.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
      body: SafeArea(
        child: BlocBuilder<VaccinationsListCubit, VaccinationsListState>(
          builder: (context, state) {
            final isEmpty = state is VaccinationsListLoaded &&
                state.grouped.values.every((l) => l.isEmpty);
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              children: [
                _PageHeader(
                  // Hide the top-right + when there are no vaccines yet —
                  // the inline "Add vaccine" card in the empty state takes
                  // over as the primary CTA.
                  onAdd: isEmpty ? null : () => _goToCreate(context),
                ),
                const SizedBox(height: AppSpacing.xs),
                _Subtitle(),
                const SizedBox(height: AppSpacing.lg),
                ..._bodyFor(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  void _goToCreate(BuildContext context) {
    context
        .push(
          '${AppRoutes.petDetailBase}/$petId/vaccinations/new',
          extra: VaccinationFormArgs(
            householdId: householdId,
            petId: petId,
            species: species,
          ),
        )
        .ignore();
  }

  List<Widget> _bodyFor(BuildContext context, VaccinationsListState state) {
    return switch (state) {
      VaccinationsListLoading() || VaccinationsListInitial() => [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      VaccinationsListError(failure: final f) => [
          AppCard(
            child: Text(
              f.message ?? t.auth.errors.unknown,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      VaccinationsListLoaded(:final grouped) =>
        grouped.values.every((l) => l.isEmpty)
            ? [_EmptyState(onAdd: () => _goToCreate(context))]
            : _sections(grouped, species),
    };
  }

  List<Widget> _sections(
    Map<VaccinationStatus, List<Vaccination>> grouped,
    Species species,
  ) {
    const order = [
      VaccinationStatus.overdue,
      VaccinationStatus.dueSoon,
      VaccinationStatus.upToDate,
      VaccinationStatus.noNextDose,
    ];
    final widgets = <Widget>[];
    for (final status in order) {
      final items = grouped[status] ?? const <Vaccination>[];
      if (items.isEmpty) continue;
      widgets
        ..add(SectionHeader(title: VaccinationStatusMeta.label(status)))
        ..add(const SizedBox(height: AppSpacing.sm));
      for (final v in items) {
        widgets
          ..add(_VaccinationCard(
            vaccination: v,
            status: status,
            species: species,
          ))
          ..add(const SizedBox(height: AppSpacing.sm));
      }
      widgets.add(const SizedBox(height: AppSpacing.sm));
    }
    return widgets;
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final addCallback = onAdd;
    return Row(
      children: [
        CircleIconButton(
          icon: PhosphorIconsBold.arrowLeft,
          onTap: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            t.vaccinations.tabTitle,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (addCallback != null)
          CircleIconButton(
            icon: PhosphorIconsBold.plus,
            onTap: addCallback,
            tooltip: t.vaccinations.addVaccine,
          ),
      ],
    );
  }
}

class _Subtitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      t.vaccinations.tabSubtitle,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: context.palette.onSurfaceMuted,
        height: 1.4,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: AppRadii.brXL,
            ),
            child: Icon(
              PhosphorIconsBold.syringe,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            t.vaccinations.empty.title,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            t.vaccinations.empty.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.palette.onSurfaceMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FeatureListCard(
            icon: PhosphorIconsRegular.plus,
            title: t.vaccinations.addVaccine,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class _VaccinationCard extends StatelessWidget {
  const _VaccinationCard({
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
    final tone = VaccinationStatusMeta.toneFor(status);

    return AppCard(
      onTap: () => context.push(
        '${AppRoutes.petDetailBase}/${vaccination.petId}/vaccinations/${vaccination.id}/edit',
        extra: VaccinationFormArgs(
          householdId: vaccination.householdId,
          petId: vaccination.petId,
          species: species,
          existing: vaccination,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: AppRadii.brMd,
            ),
            child: Icon(
              PhosphorIconsBold.syringe,
              size: 22,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vaccination.name,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(dateFmt),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.palette.onSurfaceMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          StatusBadge(
            label: VaccinationStatusMeta.label(status).toUpperCase(),
            tone: tone,
          ),
        ],
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
