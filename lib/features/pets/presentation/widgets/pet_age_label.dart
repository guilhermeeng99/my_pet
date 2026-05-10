import 'package:my_pet/features/pets/domain/entities/pet.dart';
import 'package:my_pet/gen/strings.g.dart';

/// Display rule for a pet's age, matching `specs/pets.md`:
/// `Xy Ym` once both apply, otherwise the most precise unit (years,
/// months, or days). Returns the localized "unknown" label when the pet
/// has no birth date.
String petAgeLabel(Pet pet) {
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
