import 'package:flutter/material.dart';

import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_shadows.dart';
import 'package:my_pet/app/theme/app_spacing.dart';

/// Soft white rounded surface used as the primary content container across
/// the app. Replaces ad-hoc `Card` usage so radius, padding, and shadow stay
/// uniform.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.color,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decoration = BoxDecoration(
      color: color ?? theme.colorScheme.surface,
      borderRadius: AppRadii.brLg,
      boxShadow: AppShadows.elevation1,
    );

    if (onTap == null) {
      return DecoratedBox(
        decoration: decoration,
        child: Padding(padding: padding, child: child),
      );
    }
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadii.brLg,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.brLg,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
