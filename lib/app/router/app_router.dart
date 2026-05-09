import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/auth/presentation/pages/login_page.dart';
import 'package:my_pet/features/onboarding/presentation/splash_page.dart';
import 'package:my_pet/features/onboarding/presentation/welcome_page.dart';
import 'package:my_pet/features/pets/presentation/pages/pets_home_page.dart';

/// Route paths kept as constants so deep links / navigation calls stay
/// consistent across the app. Every screen the user can land on must have
/// an entry here.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String home = '/home';
}

/// Builds the app router. Redirects on every auth state change so the user
/// is always on the right page for their session.
GoRouter buildAppRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _BlocChangeNotifier(authBloc.stream),
    redirect: (context, state) {
      final auth = authBloc.state;
      final loc = state.matchedLocation;

      // Splash decides where to go on first frame; once auth resolves we
      // stop letting the user linger there.
      switch (auth) {
        case AuthInitial() || AuthLoading():
          return null;
        case AuthUnauthenticated() || AuthErrorState():
          if (loc == AppRoutes.login || loc == AppRoutes.welcome) return null;
          return AppRoutes.welcome;
        case AuthNeedsHousehold():
          // Phase 1 simplification: auto-create runs in the bloc; while it
          // resolves the user sees Home in a loading state.
          return loc == AppRoutes.home ? null : AppRoutes.home;
        case AuthAuthenticated():
          if (loc == AppRoutes.login ||
              loc == AppRoutes.welcome ||
              loc == AppRoutes.splash) {
            return AppRoutes.home;
          }
          return null;
      }
    },
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
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const PetsHomePage(),
      ),
    ],
  );
}

/// Bridges a Bloc stream to go_router's `refreshListenable` (which expects
/// a `Listenable`).
class _BlocChangeNotifier extends ChangeNotifier {
  _BlocChangeNotifier(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}
