import 'package:flutter/material.dart';

import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_radii.dart';
import 'package:my_pet/app/theme/app_shadows.dart';
import 'package:my_pet/app/theme/app_spacing.dart';

/// Floating-pill bottom nav. The bar is inset from the screen edges, has
/// large rounded corners, and casts a soft shadow — reads as a card hovering
/// above the content instead of a chrome strip stuck to the bottom.
///
/// Active item: filled icon + primary-colored bold label + tiny dot beneath.
/// Inactive: outline icon + muted label.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final List<NavItem> items;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadii.brXL,
          boxShadow: AppShadows.elevation2,
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _NavButton(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final accent = theme.colorScheme.primary;
    final iconColor = selected ? accent : palette.onSurfaceFaint;
    final labelColor = selected ? accent : palette.onSurfaceMuted;
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: labelColor,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? item.activeIcon : item.icon,
              size: 24,
              color: iconColor,
            ),
            const SizedBox(height: 4),
            Text(item.label, style: labelStyle),
            const SizedBox(height: 4),
            // Active indicator dot beneath the label.
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 5 : 0,
              height: selected ? 5 : 0,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavItem {
  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
