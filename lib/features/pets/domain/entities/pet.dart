import 'package:equatable/equatable.dart';

import 'package:my_pet/features/pets/domain/entities/age.dart';
import 'package:my_pet/features/pets/domain/entities/sex.dart';
import 'package:my_pet/features/pets/domain/entities/species.dart';

/// Pet aggregate root. See [`specs/pets.md`](../../../../../specs/pets.md).
class Pet extends Equatable {
  const Pet({
    required this.id,
    required this.householdId,
    required this.name,
    required this.species,
    required this.sex,
    required this.neutered,
    required this.allergies,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.breed,
    this.birthDate,
    this.adoptionDate,
    this.color,
    this.microchipId,
    this.photoUrl,
    this.currentWeightKg,
    this.notes,
    this.archivedAt,
  });

  final String id;
  final String householdId;
  final String name;
  final Species species;
  final String? breed;
  final Sex sex;
  final bool neutered;
  final DateTime? birthDate;
  final DateTime? adoptionDate;
  final String? color;
  final String? microchipId;
  final String? photoUrl;
  final double? currentWeightKg;
  final List<String> allergies;
  final String? notes;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  bool get isArchived => archivedAt != null;

  Age? get age => Age.from(birthDate);

  Pet copyWith({
    String? id,
    String? householdId,
    String? name,
    Species? species,
    String? breed,
    Sex? sex,
    bool? neutered,
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
    String? createdBy,
    bool clearArchived = false,
  }) {
    return Pet(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      sex: sex ?? this.sex,
      neutered: neutered ?? this.neutered,
      birthDate: birthDate ?? this.birthDate,
      adoptionDate: adoptionDate ?? this.adoptionDate,
      color: color ?? this.color,
      microchipId: microchipId ?? this.microchipId,
      photoUrl: photoUrl ?? this.photoUrl,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      allergies: allergies ?? this.allergies,
      notes: notes ?? this.notes,
      archivedAt: clearArchived ? null : (archivedAt ?? this.archivedAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        householdId,
        name,
        species,
        breed,
        sex,
        neutered,
        birthDate,
        adoptionDate,
        color,
        microchipId,
        photoUrl,
        currentWeightKg,
        allergies,
        notes,
        archivedAt,
        createdAt,
        updatedAt,
        createdBy,
      ];
}
