import 'package:flutter/material.dart';

import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_spacing.dart';

/// Pill-shaped primary button. Wraps [FilledButton] so we can centralize
/// loading state and the leading-icon spec from specs/design.md.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.size = AppButtonSize.large,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final AppButtonSize size;

  @override
  Widget build(BuildContext context) {
    final disabled = loading || onPressed == null;
    final scheme = Theme.of(context).colorScheme;
    final height = switch (size) {
      AppButtonSize.large => 56.0,
      AppButtonSize.medium => 44.0,
      AppButtonSize.small => 36.0,
    };

    final child = loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(scheme.onPrimary),
            ),
          )
        : _LabelWithIcon(label: label, icon: icon);

    return FilledButton(
      onPressed: disabled ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: Size.fromHeight(height),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.brPill),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
      child: child,
    );
  }
}

class _LabelWithIcon extends StatelessWidget {
  const _LabelWithIcon({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: AppSpacing.xs),
        Text(label),
      ],
    );
  }
}

enum AppButtonSize { small, medium, large }
