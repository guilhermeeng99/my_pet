import 'package:my_pet/features/health/data/models/health_event_model.dart';
import 'package:my_pet/features/health/domain/entities/health_event.dart';
import 'package:my_pet/features/health/domain/entities/health_event_type.dart';
import 'package:my_pet/features/health/domain/entities/medication_details.dart';

class HealthEventFactory {
  static HealthEvent build({
    String id = 'he_1',
    String householdId = 'household_42',
    String petId = 'pet_1',
    HealthEventType type = HealthEventType.vetVisit,
    String title = 'Routine checkup',
    DateTime? date,
    DateTime? endDate,
    String? description,
    String? vetName,
    String? clinicName,
    MedicationDetails? medication,
    double? cost,
    List<String>? attachmentUrls,
    List<String>? reminderIds,
    DateTime? createdAt,
    String createdBy = 'uid_123',
  }) {
    final now = DateTime.utc(2026, 5, 10);
    return HealthEvent(
      id: id,
      householdId: householdId,
      petId: petId,
      type: type,
      title: title,
      date: date ?? now,
      endDate: endDate,
      description: description,
      vetName: vetName,
      clinicName: clinicName,
      medication: medication,
      cost: cost,
      attachmentUrls: attachmentUrls ?? const <String>[],
      reminderIds: reminderIds ?? const <String>[],
      createdAt: createdAt ?? now,
      createdBy: createdBy,
    );
  }

  static HealthEventModel buildModel({
    String id = 'he_1',
    HealthEventType type = HealthEventType.vetVisit,
  }) =>
      HealthEventModel.fromEntity(build(id: id, type: type));
}
