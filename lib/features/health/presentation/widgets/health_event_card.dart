import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:my_pet/app/widgets/app_card.dart';
import 'package:my_pet/features/health/domain/entities/health_event.dart';
import 'package:my_pet/features/health/presentation/widgets/health_event_type_meta.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class HealthEventCard extends StatelessWidget {
  const HealthEventCard({
    required this.event,
    required this.onTap,
    super.key,
  });

  final HealthEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final fmt = DateFormat.yMMMd();
    final hasCost = event.cost != null && event.cost! > 0;
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: AppRadii.brMd,
            ),
            child: Icon(
              HealthEventTypeMeta.icon(event.type),
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  fmt.format(event.date.toLocal()),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: palette.onSurfaceMuted),
                ),
                if (event.medication != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${event.medication!.dosage} · ${event.medication!.frequency}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: palette.onSurfaceFaint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          if (hasCost)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  event.cost!.toStringAsFixed(2),
                  style: theme.textTheme.titleMedium,
                ),
                Icon(
                  PhosphorIconsRegular.coins,
                  size: 14,
                  color: palette.onSurfaceFaint,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
