import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:my_pet/features/pets/presentation/widgets/pet_age_label.dart';
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
                  _PetGrid(pets: pets),
                  const SizedBox(height: AppSpacing.sm),
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

/// Two-column grid of pet tiles. The grid is non-scrollable and uses
/// the surrounding ListView for scrolling — fine for the 1..N pets a
/// household holds; revisit when we add archiving or shared collections.
class _PetGrid extends StatelessWidget {
  const _PetGrid({required this.pets});

  final List<Pet> pets;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pets.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        // Photo (1:1) + room for name + species pill + age row below.
        // Tuned for a 360dp phone so the meta row never overflows.
        childAspectRatio: 0.7,
      ),
      itemBuilder: (_, i) => _PetTile(pet: pets[i]),
    );
  }
}

/// Square tile with a large pet photo on top and identity beneath. Matches
/// the Home design pass requested 2026-05-10.
class _PetTile extends StatelessWidget {
  const _PetTile({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return AppCard(
      onTap: () => context.push('${AppRoutes.petDetailBase}/${pet.id}'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.lg),
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: _TilePhoto(pet: pet),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
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
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: AppRadii.brPill,
                        ),
                        child: Text(
                          SpeciesMeta.label(pet.species),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        petAgeLabel(pet),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.onSurfaceMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Photo or deterministic placeholder, sized to fill its parent. Used
/// inside the grid tile (the surrounding ClipRRect handles the top
/// rounded corners so it can match AppCard exactly).
class _TilePhoto extends StatelessWidget {
  const _TilePhoto({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = pet.photoUrl;
    if (url == null || url.isEmpty) {
      return _TilePhotoPlaceholder(pet: pet);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      errorWidget: (_, _, _) => _TilePhotoPlaceholder(pet: pet),
    );
  }
}

class _TilePhotoPlaceholder extends StatelessWidget {
  const _TilePhotoPlaceholder({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hue = (pet.id.codeUnits.fold<int>(0, (a, b) => a + b) * 37) % 360;
    final color =
        HSLColor.fromAHSL(1, hue.toDouble(), 0.45, 0.55).toColor();
    final initial =
        pet.name.isEmpty ? '?' : pet.name.characters.first.toUpperCase();
    return ColoredBox(
      color: color,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            initial,
            style: theme.textTheme.displayLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Positioned(
            right: 12,
            bottom: 10,
            child: Icon(
              SpeciesMeta.iconFor(pet.species),
              size: 28,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
