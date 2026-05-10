import 'package:equatable/equatable.dart';
import 'package:my_pet/features/reminders/domain/entities/recurrence.dart';
import 'package:my_pet/features/reminders/domain/entities/reminder_type.dart';

/// Standalone reminder owned by a household. May be pet-scoped (`petId`
/// non-null) or household-wide. See `docs/specs/reminders.md` for the
/// invariants and recurrence rules.
class Reminder extends Equatable {
  const Reminder({
    required this.id,
    required this.householdId,
    required this.type,
    required this.title,
    required this.dueAt,
    required this.notifyBeforeMinutes,
    required this.recurrence,
    required this.done,
    required this.createdAt,
    required this.createdBy,
    this.petId,
    this.description,
    this.recurrenceIntervalDays,
    this.doneAt,
    this.sourceFeature,
  });

  final String id;
  final String householdId;
  final String? petId;
  final ReminderType type;
  final String title;
  final String? description;
  final DateTime dueAt;
  final List<int> notifyBeforeMinutes;
  final Recurrence recurrence;
  final int? recurrenceIntervalDays;
  final bool done;
  final DateTime? doneAt;
  final String? sourceFeature;
  final DateTime createdAt;
  final String createdBy;

  bool get isOverdue =>
      !done && dueAt.isBefore(DateTime.now().toUtc());

  Reminder copyWith({
    String? id,
    String? householdId,
    String? petId,
    ReminderType? type,
    String? title,
    String? description,
    DateTime? dueAt,
    List<int>? notifyBeforeMinutes,
    Recurrence? recurrence,
    int? recurrenceIntervalDays,
    bool? done,
    DateTime? doneAt,
    String? sourceFeature,
    DateTime? createdAt,
    String? createdBy,
    bool clearPet = false,
    bool clearDescription = false,
    bool clearDoneAt = false,
    bool clearSourceFeature = false,
    bool clearRecurrenceInterval = false,
  }) {
    return Reminder(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      petId: clearPet ? null : (petId ?? this.petId),
      type: type ?? this.type,
      title: title ?? this.title,
      description:
          clearDescription ? null : (description ?? this.description),
      dueAt: dueAt ?? this.dueAt,
      notifyBeforeMinutes: notifyBeforeMinutes ?? this.notifyBeforeMinutes,
      recurrence: recurrence ?? this.recurrence,
      recurrenceIntervalDays: clearRecurrenceInterval
          ? null
          : (recurrenceIntervalDays ?? this.recurrenceIntervalDays),
      done: done ?? this.done,
      doneAt: clearDoneAt ? null : (doneAt ?? this.doneAt),
      sourceFeature:
          clearSourceFeature ? null : (sourceFeature ?? this.sourceFeature),
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
        description,
        dueAt,
        notifyBeforeMinutes,
        recurrence,
        recurrenceIntervalDays,
        done,
        doneAt,
        sourceFeature,
        createdAt,
        createdBy,
      ];
}
