import 'package:equatable/equatable.dart';

/// A single weigh-in for a pet. Kept in
/// `households/{hid}/pets/{petId}/weights/{id}` and indexed by `date`
/// descending. See `docs/specs/weight.md`.
class WeightEntry extends Equatable {
  const WeightEntry({
    required this.id,
    required this.householdId,
    required this.petId,
    required this.date,
    required this.weightKg,
    required this.createdAt,
    required this.createdBy,
    this.notes,
  });

  final String id;
  final String householdId;
  final String petId;
  final DateTime date;
  final double weightKg;
  final String? notes;
  final DateTime createdAt;
  final String createdBy;

  WeightEntry copyWith({
    String? id,
    String? householdId,
    String? petId,
    DateTime? date,
    double? weightKg,
    String? notes,
    DateTime? createdAt,
    String? createdBy,
    bool clearNotes = false,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      petId: petId ?? this.petId,
      date: date ?? this.date,
      weightKg: weightKg ?? this.weightKg,
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props =>
      [id, householdId, petId, date, weightKg, notes, createdAt, createdBy];
}
