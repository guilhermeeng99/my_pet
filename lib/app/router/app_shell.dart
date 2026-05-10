import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pet/app/widgets/app_bottom_nav.dart';
import 'package:my_pet/gen/strings.g.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Wraps the four authenticated tabs (Home / Reminders / Stats / Profile)
/// with a shared bottom nav. The shell preserves a separate navigator stack
/// per branch so deep navigation (e.g. /home → pet detail → vaccinations)
/// doesn't reset when the user switches tabs.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final items = [
      NavItem(
        icon: PhosphorIconsRegular.house,
        activeIcon: PhosphorIconsFill.house,
        label: t.nav.home,
      ),
      NavItem(
        icon: PhosphorIconsRegular.bell,
        activeIcon: PhosphorIconsFill.bell,
        label: t.nav.reminders,
      ),
      NavItem(
        icon: PhosphorIconsRegular.chartLineUp,
        activeIcon: PhosphorIconsFill.chartLineUp,
        label: t.nav.stats,
      ),
      NavItem(
        icon: PhosphorIconsRegular.user,
        activeIcon: PhosphorIconsFill.user,
        label: t.nav.profile,
      ),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        items: items,
        onTap: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
