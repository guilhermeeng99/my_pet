import 'package:my_pet/features/pets/domain/entities/species.dart';
import 'package:my_pet/features/vaccinations/domain/entities/vaccine_category.dart';

class VaccinePreset {
  const VaccinePreset({
    required this.name,
    required this.category,
    required this.defaultBoosterIntervalDays,
  });

  final String name;
  final VaccineCategory category;
  final int defaultBoosterIntervalDays;
}

/// Static catalog used by the form to suggest common vaccines and to
/// pre-fill `nextDueDate`. See [`specs/vaccinations.md`](../../../specs/vaccinations.md).
abstract final class VaccinePresets {
  static const _yearly = 365;

  static const List<VaccinePreset> _cat = [
    VaccinePreset(name: 'V3', category: VaccineCategory.core, defaultBoosterIntervalDays: _yearly),
    VaccinePreset(name: 'V4', category: VaccineCategory.core, defaultBoosterIntervalDays: _yearly),
    VaccinePreset(name: 'V5', category: VaccineCategory.core, defaultBoosterIntervalDays: _yearly),
    VaccinePreset(name: 'Rabies', category: VaccineCategory.rabies, defaultBoosterIntervalDays: _yearly),
    VaccinePreset(name: 'FELV', category: VaccineCategory.noncore, defaultBoosterIntervalDays: _yearly),
  ];

  static const List<VaccinePreset> _dog = [
    VaccinePreset(name: 'V8', category: VaccineCategory.core, defaultBoosterIntervalDays: _yearly),
    VaccinePreset(name: 'V10', category: VaccineCategory.core, defaultBoosterIntervalDays: _yearly),
    VaccinePreset(name: 'Rabies', category: VaccineCategory.rabies, defaultBoosterIntervalDays: _yearly),
    VaccinePreset(name: 'Kennel cough', category: VaccineCategory.noncore, defaultBoosterIntervalDays: _yearly),
    VaccinePreset(name: 'Giardia', category: VaccineCategory.noncore, defaultBoosterIntervalDays: _yearly),
  ];

  static List<VaccinePreset> forSpecies(Species species) {
    return switch (species) {
      Species.cat => _cat,
      Species.dog => _dog,
      _ => const <VaccinePreset>[],
    };
  }
}
