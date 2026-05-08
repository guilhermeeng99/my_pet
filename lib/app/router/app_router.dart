import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:my_pet/features/onboarding/presentation/splash_page.dart';
import 'package:my_pet/features/onboarding/presentation/welcome_page.dart';

/// Route paths kept as constants so deep links / navigation calls stay
/// consistent across the app. Every screen the user can land on must have
/// an entry here.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String home = '/home';
}

/// Phase 0 router: just splash → welcome. Real shell + tabs land in Phase 1
/// when Auth and Pets ship.
GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const _HomePlaceholder(),
      ),
    ],
  );
}

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
