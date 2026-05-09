import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:my_pet/features/pets/domain/entities/pet.dart';
import 'package:my_pet/features/pets/domain/entities/sex.dart';
import 'package:my_pet/features/pets/domain/entities/species.dart';

/// Firestore-aware extension of [Pet]. Models extend entities and handle
/// serialization (CLAUDE.md / Code Conventions).
class PetModel extends Pet {
  const PetModel({
    required super.id,
    required super.householdId,
    required super.name,
    required super.species,
    required super.sex,
    required super.neutered,
    required super.allergies,
    required super.createdAt,
    required super.updatedAt,
    required super.createdBy,
    super.breed,
    super.birthDate,
    super.adoptionDate,
    super.color,
    super.microchipId,
    super.photoUrl,
    super.currentWeightKg,
    super.notes,
    super.archivedAt,
  });

  factory PetModel.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime? ts(String key) => (data[key] as Timestamp?)?.toDate();
    return PetModel(
      id: id,
      householdId: (data['householdId'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      species: _speciesFromString(data['species'] as String?),
      sex: _sexFromString(data['sex'] as String?),
      neutered: (data['neutered'] ?? false) as bool,
      breed: data['breed'] as String?,
      birthDate: ts('birthDate'),
      adoptionDate: ts('adoptionDate'),
      color: data['color'] as String?,
      microchipId: data['microchipId'] as String?,
      photoUrl: data['photoUrl'] as String?,
      currentWeightKg: (data['currentWeightKg'] as num?)?.toDouble(),
      allergies: List<String>.from((data['allergies'] ?? <String>[]) as List),
      notes: data['notes'] as String?,
      archivedAt: ts('archivedAt'),
      createdAt: ts('createdAt') ?? DateTime.now().toUtc(),
      updatedAt: ts('updatedAt') ?? DateTime.now().toUtc(),
      createdBy: (data['createdBy'] ?? '') as String,
    );
  }

  PetModel.fromEntity(Pet pet)
      : super(
          id: pet.id,
          householdId: pet.householdId,
          name: pet.name,
          species: pet.species,
          sex: pet.sex,
          neutered: pet.neutered,
          breed: pet.breed,
          birthDate: pet.birthDate,
          adoptionDate: pet.adoptionDate,
          color: pet.color,
          microchipId: pet.microchipId,
          photoUrl: pet.photoUrl,
          currentWeightKg: pet.currentWeightKg,
          allergies: pet.allergies,
          notes: pet.notes,
          archivedAt: pet.archivedAt,
          createdAt: pet.createdAt,
          updatedAt: pet.updatedAt,
          createdBy: pet.createdBy,
        );

  Map<String, dynamic> toFirestoreCreate() {
    final map = _toMap();
    map['createdAt'] = FieldValue.serverTimestamp();
    map['updatedAt'] = FieldValue.serverTimestamp();
    return map;
  }

  Map<String, dynamic> toFirestoreUpdate() {
    final map = _toMap()..remove('createdAt');
    map['updatedAt'] = FieldValue.serverTimestamp();
    return map;
  }

  Map<String, dynamic> _toMap() {
    return {
      'householdId': householdId,
      'name': name,
      'species': species.name,
      'sex': sex.name,
      'neutered': neutered,
      if (breed != null) 'breed': breed,
      if (birthDate != null) 'birthDate': Timestamp.fromDate(birthDate!),
      if (adoptionDate != null) 'adoptionDate': Timestamp.fromDate(adoptionDate!),
      if (color != null) 'color': color,
      if (microchipId != null) 'microchipId': microchipId,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (currentWeightKg != null) 'currentWeightKg': currentWeightKg,
      'allergies': allergies,
      if (notes != null) 'notes': notes,
      'archivedAt':
          archivedAt != null ? Timestamp.fromDate(archivedAt!) : null,
      'createdBy': createdBy,
    };
  }

  static Species _speciesFromString(String? raw) {
    return Species.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => Species.other,
    );
  }

  static Sex _sexFromString(String? raw) {
    return Sex.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => Sex.unknown,
    );
  }
}
