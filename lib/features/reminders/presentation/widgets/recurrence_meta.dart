import 'package:my_pet/features/reminders/domain/entities/recurrence.dart';
import 'package:my_pet/gen/strings.g.dart';

class RecurrenceMeta {
  static String label(Recurrence r) => switch (r) {
        Recurrence.oneShot => t.reminders.recurrence.oneShot,
        Recurrence.daily => t.reminders.recurrence.daily,
        Recurrence.weekly => t.reminders.recurrence.weekly,
        Recurrence.monthly => t.reminders.recurrence.monthly,
        Recurrence.yearly => t.reminders.recurrence.yearly,
        Recurrence.custom => t.reminders.recurrence.custom,
      };
}
