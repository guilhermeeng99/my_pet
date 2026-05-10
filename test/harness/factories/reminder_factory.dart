import 'package:my_pet/features/reminders/data/models/reminder_model.dart';
import 'package:my_pet/features/reminders/domain/entities/recurrence.dart';
import 'package:my_pet/features/reminders/domain/entities/reminder.dart';
import 'package:my_pet/features/reminders/domain/entities/reminder_type.dart';

class ReminderFactory {
  static Reminder build({
    String id = 'rem_1',
    String householdId = 'household_42',
    String? petId,
    ReminderType type = ReminderType.custom,
    String title = 'Change litter',
    String? description,
    DateTime? dueAt,
    List<int>? notifyBeforeMinutes,
    Recurrence recurrence = Recurrence.oneShot,
    int? recurrenceIntervalDays,
    bool done = false,
    DateTime? doneAt,
    String? sourceFeature,
    DateTime? createdAt,
    String createdBy = 'uid_123',
  }) {
    final now = DateTime.utc(2026, 5, 10);
    return Reminder(
      id: id,
      householdId: householdId,
      petId: petId,
      type: type,
      title: title,
      description: description,
      dueAt: dueAt ?? now.add(const Duration(days: 1)),
      notifyBeforeMinutes: notifyBeforeMinutes ?? const [0],
      recurrence: recurrence,
      recurrenceIntervalDays: recurrenceIntervalDays,
      done: done,
      doneAt: doneAt,
      sourceFeature: sourceFeature,
      createdAt: createdAt ?? now,
      createdBy: createdBy,
    );
  }

  static ReminderModel buildModel({
    String id = 'rem_1',
    String householdId = 'household_42',
    DateTime? dueAt,
    Recurrence recurrence = Recurrence.oneShot,
    int? recurrenceIntervalDays,
  }) =>
      ReminderModel.fromEntity(
        build(
          id: id,
          householdId: householdId,
          dueAt: dueAt,
          recurrence: recurrence,
          recurrenceIntervalDays: recurrenceIntervalDays,
        ),
      );
}
