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

/// List tile for a reminder. Mirrors `_PetRow` on Home — square icon tile,
/// title + meta, trailing action — so the two surfaces feel like siblings.
/// The trailing slot is a check button instead of a chevron because the
/// tap target there ("mark done") is the high-frequency action.
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
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: AppRadii.brLg,
            ),
            alignment: Alignment.center,
            child: Icon(
              ReminderTypeMeta.icon(reminder.type),
              size: 24,
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: overdue
                            ? palette.danger.withValues(alpha: 0.12)
                            : theme.colorScheme.primaryContainer,
                        borderRadius: AppRadii.brPill,
                      ),
                      child: Text(
                        _dueLabel(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: overdue
                              ? palette.danger
                              : theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (reminder.recurrence.isRecurring) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '· ${RecurrenceMeta.label(reminder.recurrence)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.onSurfaceFaint,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _MarkDoneButton(
            onTap: onMarkDone,
            tooltip: t.reminders.actions.markDone,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  String _dueLabel() {
    final fmt = DateFormat.MMMd().add_jm();
    return fmt.format(reminder.dueAt.toLocal());
  }
}

/// Compact circular check button — matches the visual weight of the
/// chevron used elsewhere so the card doesn't shout "Material IconButton".
class _MarkDoneButton extends StatelessWidget {
  const _MarkDoneButton({
    required this.onTap,
    required this.tooltip,
    required this.color,
  });

  final VoidCallback onTap;
  final String tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(PhosphorIconsBold.check, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}
