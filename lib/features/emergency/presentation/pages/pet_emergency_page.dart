import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/app_card.dart';
import 'package:my_pet/app/widgets/circle_icon_button.dart';
import 'package:my_pet/app/widgets/pet_mascot.dart';
import 'package:my_pet/features/auth/domain/entities/auth_user.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/pets/domain/entities/pet.dart';
import 'package:my_pet/features/pets/presentation/widgets/species_meta.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PetEmergencyArgs {
  const PetEmergencyArgs({required this.pet, required this.contactEmail});

  final Pet pet;
  final String contactEmail;
}

/// "Pet ID card" — a single-page printable summary for emergencies
/// (lost-pet sign, vet handoff). Shows photo, key identifiers, allergies,
/// and the owner's email so a stranger can reach them. The "Copy summary"
/// action drops a plain-text version onto the clipboard.
class PetEmergencyPage extends StatelessWidget {
  const PetEmergencyPage({required this.pet, super.key});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = _currentUser(authState);
        return _EmergencyView(pet: pet, contactEmail: user?.email ?? '');
      },
    );
  }

  AuthUser? _currentUser(AuthState state) => switch (state) {
        AuthAuthenticated(:final user) => user,
        AuthNeedsHousehold(:final user) => user,
        _ => null,
      };
}

class _EmergencyView extends StatelessWidget {
  const _EmergencyView({required this.pet, required this.contactEmail});

  final Pet pet;
  final String contactEmail;

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
                      t.emergency.title,
                      style: theme.textTheme.headlineLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _copySummary(context),
                    tooltip: t.emergency.copySummary,
                    icon: const Icon(PhosphorIconsBold.copy),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView(
                  children: [
                    _HeroCard(pet: pet),
                    const SizedBox(height: AppSpacing.md),
                    _DetailsCard(pet: pet),
                    if (pet.allergies.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _AllergiesCard(pet: pet),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    _ContactCard(email: contactEmail),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copySummary(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _plainText()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(t.emergency.copied)));
  }

  String _plainText() {
    final buf = StringBuffer()
      ..writeln(t.emergency.summaryHeader(name: pet.name))
      ..writeln('${t.pets.form.species}: ${SpeciesMeta.label(pet.species)}');
    if (pet.breed?.isNotEmpty ?? false) {
      buf.writeln('${t.pets.form.breed}: ${pet.breed}');
    }
    if (pet.color?.isNotEmpty ?? false) {
      buf.writeln('${t.pets.form.color}: ${pet.color}');
    }
    if (pet.microchipId?.isNotEmpty ?? false) {
      buf.writeln('${t.pets.form.microchipId}: ${pet.microchipId}');
    }
    if (pet.allergies.isNotEmpty) {
      buf.writeln('${t.emergency.allergies}: ${pet.allergies.join(', ')}');
    }
    if (contactEmail.isNotEmpty) {
      buf.writeln('${t.emergency.contact}: $contactEmail');
    }
    return buf.toString();
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return AppCard(
      child: Column(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: AppRadii.brXL,
            ),
            clipBehavior: Clip.antiAlias,
            child: pet.photoUrl != null && pet.photoUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: pet.photoUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => const PetMascot(size: 140),
                  )
                : const PetMascot(size: 140),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            pet.name,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: AppRadii.brPill,
            ),
            child: Text(
              SpeciesMeta.label(pet.species),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          if (pet.breed?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              pet.breed!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: palette.onSurfaceMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          if (pet.color?.isNotEmpty ?? false)
            _Row(label: t.pets.form.color, value: pet.color!),
          if (pet.microchipId?.isNotEmpty ?? false)
            _Row(label: t.pets.form.microchipId, value: pet.microchipId!),
          if (pet.currentWeightKg != null)
            _Row(
              label: t.weight.tabTitle,
              value: '${pet.currentWeightKg!.toStringAsFixed(2)} kg',
            ),
        ],
      ),
    );
  }
}

class _AllergiesCard extends StatelessWidget {
  const _AllergiesCard({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIconsBold.warningOctagon,
                size: 18,
                color: palette.danger,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                t.emergency.allergies,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: palette.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final allergy in pet.allergies)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: palette.danger.withValues(alpha: 0.12),
                    borderRadius: AppRadii.brPill,
                  ),
                  child: Text(
                    allergy,
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: palette.danger),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: AppRadii.brMd,
            ),
            child: Icon(
              PhosphorIconsBold.envelope,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.emergency.contact,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.palette.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email.isEmpty ? '—' : email,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.palette.onSurfaceMuted,
              ),
            ),
          ),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
