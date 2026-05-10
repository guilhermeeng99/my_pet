import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/app_card.dart';
import 'package:my_pet/features/reminders/domain/entities/reminder.dart';
import 'package:my_pet/features/reminders/presentation/widgets/recurrence_meta.dart';
import 'package:my_pet/features/reminders/presentation/widgets/reminder_type_meta.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ReminderCard extends StatelessWidget {
  const ReminderCard({
    required this.reminder,
    required this.onTap,
    required this.onMarkDone,
    super.key,
  });

  final Reminder reminder;
  final VoidCallback onTap;
  final VoidCallback onMarkDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final overdue = reminder.isOverdue;
    final accent = overdue ? palette.danger : theme.colorScheme.primary;

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: AppRadii.brMd,
            ),
            child: Icon(
              ReminderTypeMeta.icon(reminder.type),
              size: 20,
              color: accent,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  reminder.title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _dueLabel(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: overdue ? palette.danger : palette.onSurfaceMuted,
                    fontWeight: overdue ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                if (reminder.recurrence.isRecurring) ...[
                  const SizedBox(height: 2),
                  Text(
                    RecurrenceMeta.label(reminder.recurrence),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.onSurfaceFaint,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            onPressed: onMarkDone,
            tooltip: t.reminders.actions.markDone,
            icon: Icon(
              PhosphorIconsBold.checkCircle,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _dueLabel() {
    final fmt = DateFormat.yMMMd().add_jm();
    return fmt.format(reminder.dueAt.toLocal());
  }
}
