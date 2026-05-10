import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_pet/features/health/domain/entities/health_event.dart';
import 'package:my_pet/features/health/domain/entities/health_event_type.dart';
import 'package:my_pet/features/health/domain/entities/medication_details.dart';

class HealthEventModel extends HealthEvent {
  const HealthEventModel({
    required super.id,
    required super.householdId,
    required super.petId,
    required super.type,
    required super.title,
    required super.date,
    required super.createdAt,
    required super.createdBy,
    super.endDate,
    super.description,
    super.vetName,
    super.clinicName,
    super.medication,
    super.cost,
    super.attachmentUrls,
    super.reminderIds,
  });

  factory HealthEventModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    DateTime? ts(String key) => (data[key] as Timestamp?)?.toDate();
    final medRaw = data['medication'] as Map<String, dynamic>?;
    return HealthEventModel(
      id: id,
      householdId: (data['householdId'] ?? '') as String,
      petId: (data['petId'] ?? '') as String,
      type: _typeFromString(data['type'] as String?),
      title: (data['title'] ?? '') as String,
      date: ts('date') ?? DateTime.now().toUtc(),
      endDate: ts('endDate'),
      description: data['description'] as String?,
      vetName: data['vetName'] as String?,
      clinicName: data['clinicName'] as String?,
      medication: medRaw == null ? null : _medFromMap(medRaw),
      cost: (data['cost'] as num?)?.toDouble(),
      attachmentUrls: (data['attachmentUrls'] as List<dynamic>?)
              ?.cast<String>() ??
          const <String>[],
      reminderIds:
          (data['reminderIds'] as List<dynamic>?)?.cast<String>() ??
              const <String>[],
      createdAt: ts('createdAt') ?? DateTime.now().toUtc(),
      createdBy: (data['createdBy'] ?? '') as String,
    );
  }

  HealthEventModel.fromEntity(HealthEvent e)
      : super(
          id: e.id,
          householdId: e.householdId,
          petId: e.petId,
          type: e.type,
          title: e.title,
          date: e.date,
          endDate: e.endDate,
          description: e.description,
          vetName: e.vetName,
          clinicName: e.clinicName,
          medication: e.medication,
          cost: e.cost,
          attachmentUrls: e.attachmentUrls,
          reminderIds: e.reminderIds,
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
      'type': type.name,
      'title': title,
      'date': Timestamp.fromDate(date),
      'endDate': endDate == null ? null : Timestamp.fromDate(endDate!),
      'description': description,
      'vetName': vetName,
      'clinicName': clinicName,
      'medication': medication == null ? null : _medToMap(medication!),
      'cost': cost,
      'attachmentUrls': attachmentUrls,
      'reminderIds': reminderIds,
      'createdBy': createdBy,
    };
  }

  static HealthEventType _typeFromString(String? raw) => HealthEventType.values
      .firstWhere((t) => t.name == raw, orElse: () => HealthEventType.other);

  static MedicationDetails _medFromMap(Map<String, dynamic> data) =>
      MedicationDetails(
        name: (data['name'] ?? '') as String,
        dosage: (data['dosage'] ?? '') as String,
        frequency: (data['frequency'] ?? '') as String,
        durationDays: (data['durationDays'] as num? ?? 0).toInt(),
        prescribedBy: data['prescribedBy'] as String?,
      );

  static Map<String, dynamic> _medToMap(MedicationDetails m) => {
        'name': m.name,
        'dosage': m.dosage,
        'frequency': m.frequency,
        'durationDays': m.durationDays,
        'prescribedBy': m.prescribedBy,
      };
}
