import 'package:equatable/equatable.dart';
import 'package:my_pet/features/health/domain/entities/health_event_type.dart';
import 'package:my_pet/features/health/domain/entities/medication_details.dart';

/// Clinical or care event in a pet's history. Lives in
/// `households/{hid}/pets/{petId}/health_events/{id}`. See
/// `docs/specs/health.md`.
class HealthEvent extends Equatable {
  const HealthEvent({
    required this.id,
    required this.householdId,
    required this.petId,
    required this.type,
    required this.title,
    required this.date,
    required this.createdAt,
    required this.createdBy,
    this.endDate,
    this.description,
    this.vetName,
    this.clinicName,
    this.medication,
    this.cost,
    this.attachmentUrls = const <String>[],
    this.reminderIds = const <String>[],
  });

  final String id;
  final String householdId;
  final String petId;
  final HealthEventType type;
  final String title;
  final DateTime date;
  final DateTime? endDate;
  final String? description;
  final String? vetName;
  final String? clinicName;
  final MedicationDetails? medication;
  final double? cost;
  final List<String> attachmentUrls;
  final List<String> reminderIds;
  final DateTime createdAt;
  final String createdBy;

  HealthEvent copyWith({
    String? id,
    String? householdId,
    String? petId,
    HealthEventType? type,
    String? title,
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
    String? createdBy,
    bool clearEndDate = false,
    bool clearDescription = false,
    bool clearVet = false,
    bool clearClinic = false,
    bool clearMedication = false,
    bool clearCost = false,
  }) {
    return HealthEvent(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      petId: petId ?? this.petId,
      type: type ?? this.type,
      title: title ?? this.title,
      date: date ?? this.date,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      description:
          clearDescription ? null : (description ?? this.description),
      vetName: clearVet ? null : (vetName ?? this.vetName),
      clinicName: clearClinic ? null : (clinicName ?? this.clinicName),
      medication: clearMedication ? null : (medication ?? this.medication),
      cost: clearCost ? null : (cost ?? this.cost),
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      reminderIds: reminderIds ?? this.reminderIds,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        householdId,
        petId,
        type,
        title,
        date,
        endDate,
        description,
        vetName,
        clinicName,
        medication,
        cost,
        attachmentUrls,
        reminderIds,
        createdAt,
        createdBy,
      ];
}
