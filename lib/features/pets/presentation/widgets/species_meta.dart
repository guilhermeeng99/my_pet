import 'package:flutter/material.dart';
import 'package:my_pet/features/pets/domain/entities/sex.dart';
import 'package:my_pet/features/pets/domain/entities/species.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Static, UI-only mapping from domain enums to icons + localized labels.
/// Lives next to widgets — domain stays presentation-free.
abstract final class SpeciesMeta {
  static IconData iconFor(Species species) {
    return switch (species) {
      Species.cat => PhosphorIconsBold.cat,
      Species.dog => PhosphorIconsBold.dog,
      Species.bird => PhosphorIconsBold.bird,
      Species.rabbit => PhosphorIconsBold.rabbit,
      Species.other => PhosphorIconsBold.pawPrint,
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
