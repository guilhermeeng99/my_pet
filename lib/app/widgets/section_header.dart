import 'package:flutter/material.dart';

import 'package:my_pet/app/theme/app_spacing.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Bold left-aligned section title with an optional trailing chevron action.
/// Used between vertically stacked content blocks on Home / Detail.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.onTap,
    this.actionLabel,
    super.key,
  });

  final String title;
  final VoidCallback? onTap;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tappable = onTap != null;

    final row = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (tappable) ...[
          if (actionLabel != null) ...[
            Text(
              actionLabel!,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Icon(
            PhosphorIconsRegular.caretRight,
            size: 18,
            color: theme.colorScheme.primary,
          ),
        ],
      ],
    );

    if (!tappable) return row;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: row,
      ),
    );
  }
}
