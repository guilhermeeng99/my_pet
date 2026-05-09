import 'package:flutter/material.dart';

import 'package:my_pet/features/pets/domain/entities/sex.dart';
import 'package:my_pet/features/pets/domain/entities/species.dart';
import 'package:my_pet/gen/strings.g.dart';

/// Static, UI-only mapping from domain enums to icons + localized labels.
/// Lives next to widgets — domain stays presentation-free.
abstract final class SpeciesMeta {
  static IconData iconFor(Species species) {
    return switch (species) {
      Species.cat => Icons.pets_rounded,
      Species.dog => Icons.pets_rounded,
      Species.bird => Icons.flutter_dash_rounded,
      Species.rabbit => Icons.cruelty_free_rounded,
      Species.other => Icons.emoji_nature_rounded,
    };
  }

  static String label(Species species) {
    return switch (species) {
      Species.cat => t.pets.species.cat,
      Species.dog => t.pets.species.dog,
      Species.bird => t.pets.species.bird,
      Species.rabbit => t.pets.species.rabbit,
      Species.other => t.pets.species.other,
    };
  }
}

abstract final class SexMeta {
  static String label(Sex sex) {
    return switch (sex) {
      Sex.male => t.pets.sex.male,
      Sex.female => t.pets.sex.female,
      Sex.unknown => t.pets.sex.unknown,
    };
  }
}
