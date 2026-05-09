import 'package:equatable/equatable.dart';

import 'package:my_pet/features/vaccinations/domain/entities/vaccine_category.dart';

/// See [`specs/vaccinations.md`](../../../../../specs/vaccinations.md).
class Vaccination extends Equatable {
  const Vaccination({
    required this.id,
    required this.householdId,
    required this.petId,
    required this.name,
    required this.category,
    required this.appliedDate,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.nextDueDate,
    this.vetName,
    this.clinicName,
    this.batchNumber,
    this.manufacturer,
    this.notes,
    this.attachmentUrls = const <String>[],
    this.reminderId,
  });

  final String id;
  final String householdId;
  final String petId;
  final String name;
  final VaccineCategory category;
  final DateTime appliedDate;
  final DateTime? nextDueDate;
  final String? vetName;
  final String? clinicName;
  final String? batchNumber;
  final String? manufacturer;
  final String? notes;
  final List<String> attachmentUrls;
  final String? reminderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  Vaccination copyWith({
    String? id,
    String? householdId,
    String? petId,
    String? name,
    VaccineCategory? category,
    DateTime? appliedDate,
    DateTime? nextDueDate,
    String? vetName,
    String? clinicName,
    String? batchNumber,
    String? manufacturer,
    String? notes,
    List<String>? attachmentUrls,
    String? reminderId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool clearNextDueDate = false,
    bool clearReminder = false,
  }) {
    return Vaccination(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      petId: petId ?? this.petId,
      name: name ?? this.name,
      category: category ?? this.category,
      appliedDate: appliedDate ?? this.appliedDate,
      nextDueDate:
          clearNextDueDate ? null : (nextDueDate ?? this.nextDueDate),
      vetName: vetName ?? this.vetName,
      clinicName: clinicName ?? this.clinicName,
      batchNumber: batchNumber ?? this.batchNumber,
      manufacturer: manufacturer ?? this.manufacturer,
      notes: notes ?? this.notes,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      reminderId: clearReminder ? null : (reminderId ?? this.reminderId),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        householdId,
        petId,
        name,
        category,
        appliedDate,
        nextDueDate,
        vetName,
        clinicName,
        batchNumber,
        manufacturer,
        notes,
        attachmentUrls,
        reminderId,
        createdAt,
        updatedAt,
        createdBy,
      ];
}
