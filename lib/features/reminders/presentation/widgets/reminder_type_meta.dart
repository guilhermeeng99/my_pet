import 'package:flutter/widgets.dart';
import 'package:my_pet/features/reminders/domain/entities/reminder_type.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Icon + i18n label for a [ReminderType]. Centralized so the same
/// presentation runs in the list, form chip selector, and notification
/// templates.
class ReminderTypeMeta {
  static IconData icon(ReminderType type) => switch (type) {
        ReminderType.vaccination => PhosphorIconsBold.syringe,
        ReminderType.medication => PhosphorIconsBold.pill,
        ReminderType.feeding => PhosphorIconsBold.bowlFood,
        ReminderType.grooming => PhosphorIconsBold.sparkle,
        ReminderType.vetVisit => PhosphorIconsBold.stethoscope,
        ReminderType.custom => PhosphorIconsBold.bell,
      };

  static String label(ReminderType type) => switch (type) {
        ReminderType.vaccination => t.reminders.types.vaccination,
        ReminderType.medication => t.reminders.types.medication,
        ReminderType.feeding => t.reminders.types.feeding,
        ReminderType.grooming => t.reminders.types.grooming,
        ReminderType.vetVisit => t.reminders.types.vetVisit,
        ReminderType.custom => t.reminders.types.custom,
      };
}
