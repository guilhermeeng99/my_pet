import 'package:my_pet/features/weight/data/models/weight_entry_model.dart';
import 'package:my_pet/features/weight/domain/entities/weight_entry.dart';

class WeightEntryFactory {
  static WeightEntry build({
    String id = 'w_1',
    String householdId = 'household_42',
    String petId = 'pet_1',
    DateTime? date,
    double weightKg = 4.5,
    String? notes,
    DateTime? createdAt,
    String createdBy = 'uid_123',
  }) {
    final now = DateTime.utc(2026, 5, 10);
    return WeightEntry(
      id: id,
      householdId: householdId,
      petId: petId,
      date: date ?? now,
      weightKg: weightKg,
      notes: notes,
      createdAt: createdAt ?? now,
      createdBy: createdBy,
    );
  }

  static WeightEntryModel buildModel({
    String id = 'w_1',
    DateTime? date,
    double weightKg = 4.5,
  }) =>
      WeightEntryModel.fromEntity(
        build(id: id, date: date, weightKg: weightKg),
      );
}
