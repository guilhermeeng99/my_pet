import 'package:flutter/material.dart';
import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';

/// Form-field shell shaped like the FocaAI inputs: a soft white card with a
/// 1px outline and an icon-prefixed label sitting at the top, with the actual
/// input ([child]) rendered below as a borderless control.
///
/// Pair with `InputBorder.none` on `TextField` / `DropdownButtonFormField`
/// so the visible chrome comes from this card, not the Material default.
class AppField extends StatelessWidget {
  const AppField({
    required this.icon,
    required this.label,
    required this.child,
    this.suffix,
    super.key,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm + 2,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: context.palette.outline, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              ?suffix,
            ],
          ),
          const SizedBox(height: 2),
          DefaultTextStyle.merge(
            style: theme.textTheme.bodyLarge ?? const TextStyle(),
            child: child,
          ),
        ],
      ),
    );
  }
}
