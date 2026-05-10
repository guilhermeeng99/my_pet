import 'package:flutter/material.dart';

import 'package:my_pet/app/theme/app_palette.dart';
import 'package:my_pet/app/theme/app_shadows.dart';
import 'package:my_pet/app/theme/app_spacing.dart';

/// Minimalist bottom nav: 4 items, no pill behind active. Active state is the
/// filled icon variant + primary color + label in primary; inactive is the
/// outline icon + faint label.
///
/// Items must already include both the inactive ([NavItem.icon]) and active
/// ([NavItem.activeIcon]) glyphs so the caller can pick e.g. Phosphor regular
/// vs. fill variants without this widget knowing about the icon set.
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: AppShadows.elevation2(theme.brightness),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
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
    final iconColor =
        selected ? theme.colorScheme.primary : context.palette.onSurfaceFaint;
    final labelColor =
        selected ? theme.colorScheme.primary : context.palette.onSurfaceMuted;
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
