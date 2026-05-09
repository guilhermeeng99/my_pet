import 'package:my_pet/features/vaccinations/domain/entities/vaccination.dart';
import 'package:my_pet/features/vaccinations/domain/entities/vaccine_category.dart';

class VaccinationFactory {
  static Vaccination build({
    String id = 'vax_1',
    String householdId = 'household_42',
    String petId = 'pet_1',
    String name = 'V4',
    VaccineCategory category = VaccineCategory.core,
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
    String createdBy = 'uid_123',
  }) {
    final now = DateTime.utc(2026, 5, 9);
    return Vaccination(
      id: id,
      householdId: householdId,
      petId: petId,
      name: name,
      category: category,
      appliedDate: appliedDate ?? DateTime.utc(2026, 4),
      nextDueDate: nextDueDate,
      vetName: vetName,
      clinicName: clinicName,
      batchNumber: batchNumber,
      manufacturer: manufacturer,
      notes: notes,
      attachmentUrls: attachmentUrls ?? const <String>[],
      reminderId: reminderId,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      createdBy: createdBy,
    );
  }
}
