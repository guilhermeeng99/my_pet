import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/router/app_router.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/app_card.dart';
import 'package:my_pet/app/widgets/app_primary_button.dart';
import 'package:my_pet/app/widgets/feature_list_card.dart';
import 'package:my_pet/app/widgets/greeting_card.dart';
import 'package:my_pet/app/widgets/screen_scaffold.dart';
import 'package:my_pet/app/widgets/section_header.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/pets/domain/entities/pet.dart';
import 'package:my_pet/features/pets/presentation/cubit/pets_list_cubit.dart';
import 'package:my_pet/features/pets/presentation/widgets/pet_avatar.dart';
import 'package:my_pet/features/pets/presentation/widgets/species_meta.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Home: greeting hero + primary-action card + pets list + stats. Subscribes
/// to the active-pets stream scoped to the signed-in user's household.
///
/// Gated on [AuthAuthenticated] so we never wire the cubit with an empty
/// householdId during the [AuthNeedsHousehold] window (auto-create is
/// in-flight; Firestore would reject `.doc('')`).
class PetsHomePage extends StatelessWidget {
  const PetsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = switch (state) {
          AuthAuthenticated(:final user) => user,
          _ => null,
        };
        final householdId = user?.householdId;
        if (householdId == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return BlocProvider<PetsListCubit>(
          // Key so the cubit is rebuilt if householdId ever changes
          // (e.g. user accepts an invite into another household — Phase 3).
          key: ValueKey('pets-home-$householdId'),
          create: (_) => sl<PetsListCubit>()..start(householdId),
          child: _PetsHomeView(displayName: user?.displayName),
        );
      },
    );
  }
}

class _PetsHomeView extends StatelessWidget {
  const _PetsHomeView({required this.displayName});

  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = (displayName == null || displayName!.isEmpty)
        ? null
        : displayName!.split(' ').first;
    final greetingTitle = firstName == null
        ? t.home.greetingTitleAnon
        : t.home.greetingTitle(name: firstName);

    return ScreenScaffold(
      title: t.nav.home,
      titleSize: ScreenTitleSize.large,
      body: BlocBuilder<PetsListCubit, PetsListState>(
        builder: (context, state) {
          final pets = switch (state) {
            PetsListLoaded(:final pets) => pets,
            _ => const <Pet>[],
          };
          final isLoading =
              state is PetsListLoading || state is PetsListInitial;
          final isError = state is PetsListError;

          return ListView(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.xxl,
            ),
            children: [
                GreetingCard(
                  title: greetingTitle,
                  subtitle: t.home.greetingSubtitle,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (isError)
                  AppCard(
                    child: Text(
                      state.failure.message ?? t.auth.errors.unknown,
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                else if (pets.isEmpty)
                  _QuickAddCard(
                    onPressed: () => context.push(AppRoutes.petCreate),
                  )
                else ...[
                  SectionHeader(title: t.home.myPets),
                  const SizedBox(height: AppSpacing.sm),
                  for (final pet in pets) ...[
                    _PetRow(pet: pet),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  FeatureListCard(
                    icon: PhosphorIconsBold.plus,
                    title: t.home.addAnother,
                    onTap: () => context.push(AppRoutes.petCreate),
                  ),
                ],
              ],
            );
          },
        ),
    );
  }
}

class _QuickAddCard extends StatelessWidget {
  const _QuickAddCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  PhosphorIconsBold.pawPrint,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  t.home.quickAdd.title,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            t.home.quickAdd.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.palette.onSurfaceMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: t.home.quickAdd.cta,
            icon: PhosphorIconsBold.plus,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

class _PetRow extends StatelessWidget {
  const _PetRow({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: () => context.push('${AppRoutes.petDetailBase}/${pet.id}'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          PetAvatar(pet: pet, size: 56),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pet.name,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: AppRadii.brPill,
                  ),
                  child: Text(
                    SpeciesMeta.label(pet.species),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            PhosphorIconsRegular.caretRight,
            size: 18,
            color: context.palette.onSurfaceFaint,
          ),
        ],
      ),
    );
  }
}
