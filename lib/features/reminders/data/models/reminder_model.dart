import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_pet/features/reminders/domain/entities/recurrence.dart';
import 'package:my_pet/features/reminders/domain/entities/reminder.dart';
import 'package:my_pet/features/reminders/domain/entities/reminder_type.dart';

/// Firestore-aware [Reminder] wrapper. Mirrors the
/// `households/{hid}/reminders/{id}` schema documented in CLAUDE.md.
class ReminderModel extends Reminder {
  const ReminderModel({
    required super.id,
    required super.householdId,
    required super.type,
    required super.title,
    required super.dueAt,
    required super.notifyBeforeMinutes,
    required super.recurrence,
    required super.done,
    required super.createdAt,
    required super.createdBy,
    super.petId,
    super.description,
    super.recurrenceIntervalDays,
    super.doneAt,
    super.sourceFeature,
  });

  factory ReminderModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    DateTime? ts(String key) => (data[key] as Timestamp?)?.toDate();
    return ReminderModel(
      id: id,
      householdId: (data['householdId'] ?? '') as String,
      petId: data['petId'] as String?,
      type: _typeFromString(data['type'] as String?),
      title: (data['title'] ?? '') as String,
      description: data['description'] as String?,
      dueAt: ts('dueAt') ?? DateTime.now().toUtc(),
      notifyBeforeMinutes: (data['notifyBeforeMinutes'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList(growable: false) ??
          const <int>[0],
      recurrence: _recurrenceFromString(data['recurrence'] as String?),
      recurrenceIntervalDays:
          (data['recurrenceIntervalDays'] as num?)?.toInt(),
      done: (data['done'] ?? false) as bool,
      doneAt: ts('doneAt'),
      sourceFeature: data['sourceFeature'] as String?,
      createdAt: ts('createdAt') ?? DateTime.now().toUtc(),
      createdBy: (data['createdBy'] ?? '') as String,
    );
  }

  ReminderModel.fromEntity(Reminder reminder)
      : super(
          id: reminder.id,
          householdId: reminder.householdId,
          petId: reminder.petId,
          type: reminder.type,
          title: reminder.title,
          description: reminder.description,
          dueAt: reminder.dueAt,
          notifyBeforeMinutes: reminder.notifyBeforeMinutes,
          recurrence: reminder.recurrence,
          recurrenceIntervalDays: reminder.recurrenceIntervalDays,
          done: reminder.done,
          doneAt: reminder.doneAt,
          sourceFeature: reminder.sourceFeature,
          createdAt: reminder.createdAt,
          createdBy: reminder.createdBy,
        );

  Map<String, dynamic> toFirestoreCreate() {
    final map = _toMap();
    map['createdAt'] = FieldValue.serverTimestamp();
    return map;
  }

  Map<String, dynamic> toFirestoreUpdate() {
    return _toMap()..remove('createdAt');
  }

  Map<String, dynamic> _toMap() {
    return {
      'householdId': householdId,
      'petId': petId,
      'type': type.name,
      'title': title,
      'description': description,
      'dueAt': Timestamp.fromDate(dueAt),
      'notifyBeforeMinutes': notifyBeforeMinutes,
      'recurrence': recurrence.name,
      'recurrenceIntervalDays': recurrenceIntervalDays,
      'done': done,
      'doneAt': doneAt == null ? null : Timestamp.fromDate(doneAt!),
      'sourceFeature': sourceFeature,
      'createdBy': createdBy,
    };
  }

  static ReminderType _typeFromString(String? raw) => ReminderType.values
      .firstWhere((t) => t.name == raw, orElse: () => ReminderType.custom);

  static Recurrence _recurrenceFromString(String? raw) => Recurrence.values
      .firstWhere((r) => r.name == raw, orElse: () => Recurrence.oneShot);
}
