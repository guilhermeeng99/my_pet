import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/features/pets/domain/entities/pet.dart';
import 'package:my_pet/features/pets/presentation/widgets/species_meta.dart';

/// Square avatar that gracefully falls back to a deterministic colored
/// initial when the pet has no photo (specs/pets.md edge case).
class PetAvatar extends StatelessWidget {
  const PetAvatar({required this.pet, super.key, this.size = 64});

  final Pet pet;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.all(Radius.circular(size / 4));
    final placeholder = _Placeholder(pet: pet, size: size, radius: radius);

    final url = pet.photoUrl;
    if (url == null || url.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => SizedBox(
          width: size,
          height: size,
          child: ColoredBox(color: theme.colorScheme.surfaceContainerHighest),
        ),
        errorWidget: (_, _, _) => placeholder,
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.pet,
    required this.size,
    required this.radius,
  });

  final Pet pet;
  final double size;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hue = (pet.id.codeUnits.fold<int>(0, (a, b) => a + b) * 37) % 360;
    final color = HSLColor.fromAHSL(1, hue.toDouble(), 0.45, 0.55).toColor();
    final initial = pet.name.isEmpty ? '?' : pet.name.characters.first.toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, borderRadius: radius),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            initial,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: size / 2,
            ),
          ),
          Positioned(
            right: AppRadii.brSm.bottomRight.x,
            bottom: AppRadii.brSm.bottomRight.x,
            child: Icon(
              SpeciesMeta.iconFor(pet.species),
              size: size / 4,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
