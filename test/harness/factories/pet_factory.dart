import 'package:my_pet/features/pets/data/models/pet_model.dart';
import 'package:my_pet/features/pets/domain/entities/pet.dart';
import 'package:my_pet/features/pets/domain/entities/sex.dart';
import 'package:my_pet/features/pets/domain/entities/species.dart';

class PetFactory {
  static Pet build({
    String id = 'pet_1',
    String householdId = 'household_42',
    String name = 'Mia',
    Species species = Species.cat,
    Sex sex = Sex.female,
    bool neutered = true,
    String? breed,
    DateTime? birthDate,
    DateTime? adoptionDate,
    String? color,
    String? microchipId,
    String? photoUrl,
    double? currentWeightKg,
    List<String>? allergies,
    String? notes,
    DateTime? archivedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String createdBy = 'uid_123',
  }) {
    final now = DateTime.utc(2026, 5, 9);
    return Pet(
      id: id,
      householdId: householdId,
      name: name,
      species: species,
      sex: sex,
      neutered: neutered,
      breed: breed,
      birthDate: birthDate,
      adoptionDate: adoptionDate,
      color: color,
      microchipId: microchipId,
      photoUrl: photoUrl,
      currentWeightKg: currentWeightKg,
      allergies: allergies ?? const <String>[],
      notes: notes,
      archivedAt: archivedAt,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      createdBy: createdBy,
    );
  }

  static PetModel buildModel({
    String id = 'pet_1',
    String householdId = 'household_42',
    String name = 'Mia',
    Species species = Species.cat,
    Sex sex = Sex.female,
  }) {
    return PetModel.fromEntity(build(
      id: id,
      householdId: householdId,
      name: name,
      species: species,
      sex: sex,
    ));
  }
}
