import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/router/app_router.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/pets/domain/entities/pet.dart';
import 'package:my_pet/features/pets/presentation/cubit/pets_list_cubit.dart';
import 'package:my_pet/features/pets/presentation/widgets/pet_avatar.dart';
import 'package:my_pet/features/pets/presentation/widgets/species_meta.dart';
import 'package:my_pet/gen/strings.g.dart';

/// Home: grid of pet cards. Subscribes to the active-pets stream scoped
/// to the signed-in user's household.
class PetsHomePage extends StatelessWidget {
  const PetsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PetsListCubit>(
      create: (_) => sl<PetsListCubit>()..start(_householdId(context)),
      child: const _PetsHomeView(),
    );
  }

  String _householdId(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    return switch (auth) {
      AuthAuthenticated(user: final u) => u.householdId!,
      AuthNeedsHousehold(user: final u) => u.householdId ?? '',
      _ => '',
    };
  }
}

class _PetsHomeView extends StatelessWidget {
  const _PetsHomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.pets.homeTitle),
        actions: [
          IconButton(
            tooltip: t.auth.signOut,
            icon: const Icon(Icons.logout_rounded),
            onPressed: () =>
                context.read<AuthBloc>().add(const SignOutRequested()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.petCreate),
        icon: const Icon(Icons.add_rounded),
        label: Text(t.pets.addPet),
      ),
      body: BlocBuilder<PetsListCubit, PetsListState>(
        builder: (context, state) {
          return switch (state) {
            PetsListLoading() || PetsListInitial() =>
              const Center(child: CircularProgressIndicator()),
            PetsListEmpty() => const _EmptyState(),
            PetsListLoaded(:final pets) => _PetsGrid(pets: pets),
            PetsListError(failure: final f) => _ErrorState(message: f.message),
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
            Icon(Icons.pets_rounded, size: 96, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              t.pets.empty.title,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              t.pets.empty.subtitle,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(message ?? t.auth.errors.unknown, textAlign: TextAlign.center),
      ),
    );
  }
}

class _PetsGrid extends StatelessWidget {
  const _PetsGrid({required this.pets});
  final List<Pet> pets;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.78,
      ),
      itemCount: pets.length,
      itemBuilder: (context, i) => _PetCard(pet: pets[i]),
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('${AppRoutes.petDetailBase}/${pet.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: PetAvatar(pet: pet, size: 96)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                pet.name,
                style: theme.textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                SpeciesMeta.label(pet.species),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: context.palette.onSurfaceMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
