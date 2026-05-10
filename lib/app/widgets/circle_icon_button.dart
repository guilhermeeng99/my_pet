import 'package:flutter/material.dart';

/// Round 44×44 white-surface icon button used as the page-level back / edit /
/// archive control across feature pages. Unifies the pattern duplicated in
/// pet detail / form / vaccinations.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.foregroundColor,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final btn = Material(
      color: theme.colorScheme.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 20,
            color: foregroundColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
    final label = tooltip;
    if (label == null) return btn;
    return Tooltip(message: label, child: btn);
  }
}
