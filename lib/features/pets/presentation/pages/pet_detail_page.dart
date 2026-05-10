import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/router/app_router.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/circle_icon_button.dart';
import 'package:my_pet/app/widgets/feature_list_card.dart';
import 'package:my_pet/app/widgets/section_header.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/documents/presentation/pages/pet_documents_page.dart';
import 'package:my_pet/features/gallery/presentation/pages/pet_gallery_page.dart';
import 'package:my_pet/features/health/presentation/pages/pet_health_page.dart';
import 'package:my_pet/features/pets/domain/entities/pet.dart';
import 'package:my_pet/features/pets/domain/repositories/pet_repository.dart';
import 'package:my_pet/features/pets/presentation/cubit/pets_list_cubit.dart';
import 'package:my_pet/features/pets/presentation/widgets/pet_avatar.dart';
import 'package:my_pet/features/pets/presentation/widgets/species_meta.dart';
import 'package:my_pet/features/vaccinations/presentation/pages/pet_vaccinations_page.dart';
import 'package:my_pet/features/weight/presentation/pages/pet_weight_page.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Pet detail — overview only in Phase 1. Vaccinations / Health / Weight
/// tabs land alongside their own features.
class PetDetailPage extends StatelessWidget {
  const PetDetailPage({required this.petId, super.key});

  final String petId;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    final householdId = switch (auth) {
      AuthAuthenticated(:final user) => user.householdId,
      AuthNeedsHousehold(:final user) => user.householdId,
      _ => null,
    };
    if (householdId == null) {
      return Scaffold(body: Center(child: Text(t.auth.errors.unknown)));
    }
    return _PetDetailView(householdId: householdId, petId: petId);
  }
}

class _PetDetailView extends StatelessWidget {
  const _PetDetailView({required this.householdId, required this.petId});
  final String householdId;
  final String petId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Pet?>(
      stream: sl<PetRepository>().watchPet(householdId, petId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final pet = snap.data;
        if (pet == null) {
          return Scaffold(body: Center(child: Text(t.auth.errors.unknown)));
        }
        return _Loaded(pet: pet);
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat.yMMMd();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xxl,
          ),
          children: [
            _DetailHeader(
              onEdit: () => context.push(
                '${AppRoutes.petDetailBase}/${pet.id}/edit',
                extra: pet,
              ),
              onArchive: () => _confirmArchive(context, pet),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(child: PetAvatar(pet: pet, size: 160)),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(pet.name, style: theme.textTheme.headlineLarge),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: AppRadii.brPill,
                ),
                child: Text(
                  SpeciesMeta.label(pet.species),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FeatureListCard(
              icon: PhosphorIconsRegular.syringe,
              title: t.vaccinations.tabTitle,
              onTap: () => context.push(
                '${AppRoutes.petDetailBase}/${pet.id}/vaccinations',
                extra: VaccinationFormArgs(
                  householdId: pet.householdId,
                  petId: pet.id,
                  species: pet.species,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FeatureListCard(
              icon: PhosphorIconsRegular.heart,
              title: t.health.tabTitle,
              onTap: () => context.push(
                '${AppRoutes.petDetailBase}/${pet.id}/health',
                extra: PetHealthArgs(
                  householdId: pet.householdId,
                  petId: pet.id,
                  petName: pet.name,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FeatureListCard(
              icon: PhosphorIconsRegular.folderOpen,
              title: t.documents.tabTitle,
              onTap: () => context.push(
                '${AppRoutes.petDetailBase}/${pet.id}/documents',
                extra: PetDocumentsArgs(
                  householdId: pet.householdId,
                  petId: pet.id,
                  petName: pet.name,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FeatureListCard(
              icon: PhosphorIconsRegular.imagesSquare,
              title: t.gallery.tabTitle,
              onTap: () => context.push(
                '${AppRoutes.petDetailBase}/${pet.id}/gallery',
                extra: PetGalleryArgs(
                  householdId: pet.householdId,
                  petId: pet.id,
                  petName: pet.name,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FeatureListCard(
              icon: PhosphorIconsRegular.scales,
              title: t.weight.tabTitle,
              subtitle: pet.currentWeightKg == null
                  ? null
                  : '${pet.currentWeightKg!.toStringAsFixed(2)} kg',
              onTap: () => context.push(
                '${AppRoutes.petDetailBase}/${pet.id}/weights',
                extra: PetWeightArgs(
                  householdId: pet.householdId,
                  petId: pet.id,
                  petName: pet.name,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(title: t.pets.detail.detailsHeader),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: PhosphorIconsBold.cake,
                    label: t.pets.detail.ageLabel,
                    value: _ageLabel(pet),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _InfoTile(
                    icon: PhosphorIconsBold.identificationCard,
                    label: t.pets.form.sex,
                    value: SexMeta.label(pet.sex),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: PhosphorIconsBold.tag,
                    label: t.pets.form.breed,
                    value: _orDash(pet.breed),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _InfoTile(
                    icon: PhosphorIconsBold.shieldCheck,
                    label: t.pets.form.neutered,
                    value: pet.neutered ? t.common.yes : t.common.no,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: PhosphorIconsBold.calendarBlank,
                    label: t.pets.form.birthDate,
                    value: pet.birthDate == null
                        ? '—'
                        : dateFmt.format(pet.birthDate!),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _InfoTile(
                    icon: PhosphorIconsBold.heart,
                    label: t.pets.form.adoptionDate,
                    value: pet.adoptionDate == null
                        ? '—'
                        : dateFmt.format(pet.adoptionDate!),
                  ),
                ),
              ],
            ),
            if (pet.color?.isNotEmpty ?? false) ...[
              const SizedBox(height: AppSpacing.sm),
              _InfoTile(
                icon: PhosphorIconsBold.palette,
                label: t.pets.form.color,
                value: pet.color!,
              ),
            ],
            if (pet.microchipId?.isNotEmpty ?? false) ...[
              const SizedBox(height: AppSpacing.sm),
              _InfoTile(
                icon: PhosphorIconsBold.barcode,
                label: t.pets.form.microchipId,
                value: pet.microchipId!,
              ),
            ],
            if (pet.notes?.isNotEmpty ?? false) ...[
              const SizedBox(height: AppSpacing.sm),
              _InfoTile(
                icon: PhosphorIconsBold.notePencil,
                label: t.pets.form.notes,
                value: pet.notes!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _orDash(String? value) =>
      value == null || value.isEmpty ? '—' : value;

  String _ageLabel(Pet pet) {
    final age = pet.age;
    if (age == null) return t.pets.detail.ageUnknown;
    if (age.isUnderOneMonth) {
      return t.pets.detail.ageDays(days: age.days);
    }
    if (age.isUnderOneYear) {
      return t.pets.detail.ageMonths(months: age.months);
    }
    if (age.months == 0) {
      return t.pets.detail.ageYears(years: age.years);
    }
    return t.pets.detail.ageYearsMonths(years: age.years, months: age.months);
  }

  Future<void> _confirmArchive(BuildContext context, Pet pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.pets.actions.archiveConfirmTitle(petName: pet.name)),
        content: Text(t.pets.actions.archiveConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.pets.actions.archive),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final cubit = sl<PetsListCubit>();
    final result = await cubit.archive(pet.householdId, pet.id);
    if (!context.mounted) return;
    result.fold(
      (failure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(failure.message ?? t.auth.errors.unknown),
          ));
      },
      (_) => context.pop(),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.onEdit, required this.onArchive});

  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleIconButton(
          icon: PhosphorIconsBold.arrowLeft,
          onTap: () => Navigator.of(context).pop(),
        ),
        const Spacer(),
        CircleIconButton(
          icon: PhosphorIconsBold.pencilSimple,
          onTap: onEdit,
          tooltip: t.common.edit,
        ),
        const SizedBox(width: AppSpacing.xs),
        CircleIconButton(
          icon: PhosphorIconsBold.archive,
          onTap: onArchive,
          tooltip: t.pets.actions.archive,
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm + 2,
        AppSpacing.md,
        AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: context.palette.outline, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.palette.onSurfaceMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
