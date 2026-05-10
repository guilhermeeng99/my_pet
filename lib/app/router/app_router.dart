import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:my_pet/app/router/app_shell.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/auth/presentation/pages/login_page.dart';
import 'package:my_pet/features/household/presentation/pages/household_setup_page.dart';
import 'package:my_pet/features/household/presentation/pages/join_household_page.dart';
import 'package:my_pet/features/onboarding/presentation/splash_page.dart';
import 'package:my_pet/features/onboarding/presentation/welcome_page.dart';
import 'package:my_pet/features/pets/domain/entities/pet.dart';
import 'package:my_pet/features/pets/presentation/pages/pet_detail_page.dart';
import 'package:my_pet/features/pets/presentation/pages/pet_form_page.dart';
import 'package:my_pet/features/pets/presentation/pages/pets_home_page.dart';
import 'package:my_pet/features/profile/presentation/pages/profile_page.dart';
import 'package:my_pet/features/reminders/presentation/pages/reminders_stub_page.dart';
import 'package:my_pet/features/stats/presentation/pages/stats_stub_page.dart';
import 'package:my_pet/features/vaccinations/presentation/pages/pet_vaccinations_page.dart';
import 'package:my_pet/features/vaccinations/presentation/pages/vaccination_form_page.dart';

/// Route paths kept as constants so deep links / navigation calls stay
/// consistent across the app. Every screen the user can land on must have
/// an entry here.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String home = '/home';
  static const String reminders = '/reminders';
  static const String stats = '/stats';
  static const String profile = '/profile';
  static const String householdSetup = '/household/setup';
  static const String join = '/join';
  static const String petCreate = '/home/new';
  static const String petDetailBase = '/home/pet';
  static const String petDetailPattern = '$petDetailBase/:petId';
  static const String petEditPattern = '$petDetailBase/:petId/edit';
}

/// Builds the app router. Redirects on every auth state change so the user
/// is always on the right page for their session. Authenticated tabs live
/// behind a [StatefulShellRoute] so each tab keeps its own back-stack.
GoRouter buildAppRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _BlocChangeNotifier(authBloc.stream),
    redirect: (context, state) {
      final auth = authBloc.state;
      final loc = state.matchedLocation;
      final isShellRoute = loc == AppRoutes.home ||
          loc == AppRoutes.reminders ||
          loc == AppRoutes.stats ||
          loc == AppRoutes.profile ||
          loc.startsWith('${AppRoutes.home}/');

      switch (auth) {
        case AuthInitial() || AuthLoading():
          return null;
        case AuthUnauthenticated() || AuthErrorState():
          if (loc == AppRoutes.login || loc == AppRoutes.welcome) return null;
          return AppRoutes.welcome;
        case AuthNeedsHousehold() || AuthCreatingHousehold():
          // User has no householdId yet — anchor on setup (or /join when they
          // chose that branch). Anywhere else would crash on empty
          // householdId.
          if (loc == AppRoutes.householdSetup || loc == AppRoutes.join) {
            return null;
          }
          return AppRoutes.householdSetup;
        case AuthAuthenticated():
          if (loc == AppRoutes.login ||
              loc == AppRoutes.welcome ||
              loc == AppRoutes.splash ||
              loc == AppRoutes.householdSetup) {
            return AppRoutes.home;
          }
          if (!isShellRoute &&
              loc != AppRoutes.splash &&
              loc != AppRoutes.welcome &&
              loc != AppRoutes.login &&
              loc != AppRoutes.join) {
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
        path: AppRoutes.householdSetup,
        builder: (context, state) => const HouseholdSetupPage(),
      ),
      GoRoute(
        path: AppRoutes.join,
        builder: (context, state) => const JoinHouseholdPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const PetsHomePage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const PetFormPage(),
                  ),
                  GoRoute(
                    path: 'pet/:petId',
                    builder: (context, state) =>
                        PetDetailPage(petId: state.pathParameters['petId']!),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) =>
                            PetFormPage(existing: state.extra as Pet?),
                      ),
                      GoRoute(
                        path: 'vaccinations',
                        builder: (context, state) {
                          final args = state.extra! as VaccinationFormArgs;
                          return PetVaccinationsPage(
                            householdId: args.householdId,
                            petId: args.petId,
                            species: args.species,
                          );
                        },
                        routes: [
                          GoRoute(
                            path: 'new',
                            builder: (context, state) {
                              final args =
                                  state.extra! as VaccinationFormArgs;
                              return VaccinationFormPage(
                                householdId: args.householdId,
                                petId: args.petId,
                                species: args.species,
                              );
                            },
                          ),
                          GoRoute(
                            path: ':vaccinationId/edit',
                            builder: (context, state) {
                              final args =
                                  state.extra! as VaccinationFormArgs;
                              return VaccinationFormPage(
                                householdId: args.householdId,
                                petId: args.petId,
                                species: args.species,
                                existing: args.existing,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.reminders,
                builder: (context, state) => const RemindersStubPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.stats,
                builder: (context, state) => const StatsStubPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
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
