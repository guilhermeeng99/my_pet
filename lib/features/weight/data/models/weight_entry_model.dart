import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_pet/features/weight/domain/entities/weight_entry.dart';

class WeightEntryModel extends WeightEntry {
  const WeightEntryModel({
    required super.id,
    required super.householdId,
    required super.petId,
    required super.date,
    required super.weightKg,
    required super.createdAt,
    required super.createdBy,
    super.notes,
  });

  factory WeightEntryModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    DateTime? ts(String key) => (data[key] as Timestamp?)?.toDate();
    return WeightEntryModel(
      id: id,
      householdId: (data['householdId'] ?? '') as String,
      petId: (data['petId'] ?? '') as String,
      date: ts('date') ?? DateTime.now().toUtc(),
      weightKg: (data['weightKg'] as num? ?? 0).toDouble(),
      notes: data['notes'] as String?,
      createdAt: ts('createdAt') ?? DateTime.now().toUtc(),
      createdBy: (data['createdBy'] ?? '') as String,
    );
  }

  WeightEntryModel.fromEntity(WeightEntry e)
      : super(
          id: e.id,
          householdId: e.householdId,
          petId: e.petId,
          date: e.date,
          weightKg: e.weightKg,
          notes: e.notes,
          createdAt: e.createdAt,
          createdBy: e.createdBy,
        );

  Map<String, dynamic> toFirestoreCreate() {
    final map = _toMap();
    map['createdAt'] = FieldValue.serverTimestamp();
    return map;
  }

  Map<String, dynamic> toFirestoreUpdate() => _toMap()..remove('createdAt');

  Map<String, dynamic> _toMap() {
    return {
      'householdId': householdId,
      'petId': petId,
      'date': Timestamp.fromDate(date),
      'weightKg': weightKg,
      'notes': notes,
      'createdBy': createdBy,
    };
  }
}
