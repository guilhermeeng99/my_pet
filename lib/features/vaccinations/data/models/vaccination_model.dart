import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:my_pet/features/vaccinations/domain/entities/vaccination.dart';
import 'package:my_pet/features/vaccinations/domain/entities/vaccine_category.dart';

class VaccinationModel extends Vaccination {
  const VaccinationModel({
    required super.id,
    required super.householdId,
    required super.petId,
    required super.name,
    required super.category,
    required super.appliedDate,
    required super.createdAt,
    required super.updatedAt,
    required super.createdBy,
    super.nextDueDate,
    super.vetName,
    super.clinicName,
    super.batchNumber,
    super.manufacturer,
    super.notes,
    super.attachmentUrls,
    super.reminderId,
  });

  factory VaccinationModel.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime? ts(String key) => (data[key] as Timestamp?)?.toDate();
    return VaccinationModel(
      id: id,
      householdId: (data['householdId'] ?? '') as String,
      petId: (data['petId'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      category: _categoryFromString(data['category'] as String?),
      appliedDate: ts('appliedDate') ?? DateTime.now().toUtc(),
      nextDueDate: ts('nextDueDate'),
      vetName: data['vetName'] as String?,
      clinicName: data['clinicName'] as String?,
      batchNumber: data['batchNumber'] as String?,
      manufacturer: data['manufacturer'] as String?,
      notes: data['notes'] as String?,
      attachmentUrls:
          List<String>.from((data['attachmentUrls'] ?? <String>[]) as List),
      reminderId: data['reminderId'] as String?,
      createdAt: ts('createdAt') ?? DateTime.now().toUtc(),
      updatedAt: ts('updatedAt') ?? DateTime.now().toUtc(),
      createdBy: (data['createdBy'] ?? '') as String,
    );
  }

  VaccinationModel.fromEntity(Vaccination v)
      : super(
          id: v.id,
          householdId: v.householdId,
          petId: v.petId,
          name: v.name,
          category: v.category,
          appliedDate: v.appliedDate,
          nextDueDate: v.nextDueDate,
          vetName: v.vetName,
          clinicName: v.clinicName,
          batchNumber: v.batchNumber,
          manufacturer: v.manufacturer,
          notes: v.notes,
          attachmentUrls: v.attachmentUrls,
          reminderId: v.reminderId,
          createdAt: v.createdAt,
          updatedAt: v.updatedAt,
          createdBy: v.createdBy,
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
      'petId': petId,
      'name': name,
      'category': category.name,
      'appliedDate': Timestamp.fromDate(appliedDate),
      if (nextDueDate != null)
        'nextDueDate': Timestamp.fromDate(nextDueDate!),
      if (vetName != null) 'vetName': vetName,
      if (clinicName != null) 'clinicName': clinicName,
      if (batchNumber != null) 'batchNumber': batchNumber,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (notes != null) 'notes': notes,
      'attachmentUrls': attachmentUrls,
      if (reminderId != null) 'reminderId': reminderId,
      'createdBy': createdBy,
    };
  }

  static VaccineCategory _categoryFromString(String? raw) {
    return VaccineCategory.values.firstWhere(
      (c) => c.name == raw,
      orElse: () => VaccineCategory.other,
    );
  }
}
