import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/router/app_router.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/pets/domain/entities/pet.dart';
import 'package:my_pet/features/pets/domain/repositories/pet_repository.dart';
import 'package:my_pet/features/pets/presentation/cubit/pets_list_cubit.dart';
import 'package:my_pet/features/pets/presentation/widgets/pet_avatar.dart';
import 'package:my_pet/features/pets/presentation/widgets/species_meta.dart';
import 'package:my_pet/gen/strings.g.dart';

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
    final muted = context.palette.onSurfaceMuted;
    final dateFmt = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        title: Text(pet.name),
        actions: [
          IconButton(
            tooltip: t.common.edit,
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => context.push(
              '${AppRoutes.petDetailBase}/${pet.id}/edit',
              extra: pet,
            ),
          ),
          IconButton(
            tooltip: t.pets.actions.archive,
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => _confirmArchive(context, pet),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Center(child: PetAvatar(pet: pet, size: 160)),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              SpeciesMeta.label(pet.species),
              style: theme.textTheme.titleMedium?.copyWith(color: muted),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Field(label: t.pets.form.sex, value: SexMeta.label(pet.sex)),
          if (pet.breed?.isNotEmpty ?? false)
            _Field(label: t.pets.form.breed, value: pet.breed!),
          _Field(label: t.pets.form.neutered, value: pet.neutered ? t.common.yes : t.common.no),
          if (pet.birthDate != null)
            _Field(label: t.pets.form.birthDate, value: dateFmt.format(pet.birthDate!)),
          _Field(label: 'Age', value: _ageLabel(pet)),
          if (pet.adoptionDate != null)
            _Field(label: t.pets.form.adoptionDate, value: dateFmt.format(pet.adoptionDate!)),
          if (pet.color?.isNotEmpty ?? false)
            _Field(label: t.pets.form.color, value: pet.color!),
          if (pet.microchipId?.isNotEmpty ?? false)
            _Field(label: t.pets.form.microchipId, value: pet.microchipId!),
          if (pet.notes?.isNotEmpty ?? false)
            _Field(label: t.pets.form.notes, value: pet.notes!),
        ],
      ),
    );
  }

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

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.palette.onSurfaceMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
