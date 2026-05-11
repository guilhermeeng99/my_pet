import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/onboarding/onboarding_preference_service.dart';
import 'package:my_pet/app/router/app_shell.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/auth/presentation/pages/login_page.dart';
import 'package:my_pet/features/documents/presentation/pages/pet_documents_page.dart';
import 'package:my_pet/features/gallery/presentation/pages/pet_gallery_page.dart';
import 'package:my_pet/features/health/presentation/pages/pet_health_page.dart';
import 'package:my_pet/features/household/presentation/pages/household_audit_page.dart';
import 'package:my_pet/features/household/presentation/pages/household_members_page.dart';
import 'package:my_pet/features/household/presentation/pages/household_setup_page.dart';
import 'package:my_pet/features/household/presentation/pages/join_household_page.dart';
import 'package:my_pet/features/onboarding/presentation/notification_permission_page.dart';
import 'package:my_pet/features/onboarding/presentation/welcome_page.dart';
import 'package:my_pet/features/pets/domain/entities/pet.dart';
import 'package:my_pet/features/pets/presentation/pages/pet_detail_page.dart';
import 'package:my_pet/features/pets/presentation/pages/pet_form_page.dart';
import 'package:my_pet/features/pets/presentation/pages/pets_home_page.dart';
import 'package:my_pet/features/profile/presentation/pages/profile_page.dart';
import 'package:my_pet/features/reminders/domain/entities/reminder.dart';
import 'package:my_pet/features/reminders/presentation/pages/reminder_form_page.dart';
import 'package:my_pet/features/reminders/presentation/pages/reminders_home_page.dart';
import 'package:my_pet/features/startup/presentation/cubit/startup_cubit.dart';
import 'package:my_pet/features/startup/presentation/pages/startup_page.dart';
import 'package:my_pet/features/stats/presentation/pages/insights_page.dart';
import 'package:my_pet/features/vaccinations/presentation/pages/pet_vaccinations_page.dart';
import 'package:my_pet/features/vaccinations/presentation/pages/vaccination_form_page.dart';
import 'package:my_pet/features/weight/presentation/pages/pet_weight_page.dart';

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
  static const String notificationsPermission = '/onboarding/notifications';
  static const String petCreate = '/home/new';
  static const String petDetailBase = '/home/pet';
  static const String petDetailPattern = '$petDetailBase/:petId';
  static const String petEditPattern = '$petDetailBase/:petId/edit';
  static const String reminderCreate = '/reminders/new';
  static const String reminderEditPattern = '/reminders/:reminderId/edit';
  static String reminderEditFor(String reminderId) =>
      '/reminders/$reminderId/edit';
  static const String householdMembers = '/profile/family';
  static const String householdAudit = '/profile/family/audit';
}

/// Root navigator key. Sub-routes that should hide the bottom-nav shell
/// (pet detail, reminder form, manage family, etc.) declare
/// `parentNavigatorKey: _rootNavigatorKey` so go_router pushes them onto
/// the root navigator — above the [StatefulShellRoute] — instead of into
/// the active branch's nested navigator.
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'rootNavigator',
);

/// Builds the app router. Redirects on every auth state change so the user
/// is always on the right page for their session. Authenticated tabs live
/// behind a [StatefulShellRoute] so each tab keeps its own back-stack.
///
/// The redirect gates on [StartupCubit] first — until startup emits a
/// terminal state, every path resolves back to `/` (the splash) so the
/// router never flips to welcome mid-resolution. See `docs/specs/startup.md`.
GoRouter buildAppRouter({
  required AuthBloc authBloc,
  required StartupCubit startupCubit,
}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: _BlocChangeNotifier([
      authBloc.stream,
      startupCubit.stream,
    ]),
    redirect: (context, state) {
      final auth = authBloc.state;
      final startup = startupCubit.state;
      final loc = state.matchedLocation;

      // Stay on the splash until startup finishes its first auth resolution.
      // Without this gate the redirect would flip through `welcome` (because
      // `AuthInitial` falls through to the default below) before settling.
      final startupDone = startup is StartupAuthenticated ||
          startup is StartupUnauthenticated;
      if (!startupDone) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final isShellRoute = loc == AppRoutes.home ||
          loc == AppRoutes.reminders ||
          loc == AppRoutes.stats ||
          loc == AppRoutes.profile ||
          loc.startsWith('${AppRoutes.home}/') ||
          loc.startsWith('${AppRoutes.reminders}/') ||
          loc.startsWith('${AppRoutes.profile}/');

      switch (auth) {
        case AuthInitial() || AuthLoading():
          // After startup, AuthBloc should not return to Initial. Loading
          // happens mid-Google-sign-in; let the current page stay so the
          // login button can show a spinner without a navigation flicker.
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
          final needsNotifPrompt = !sl<OnboardingPreferenceService>()
              .notificationsPromptShown;
          if (needsNotifPrompt && loc != AppRoutes.notificationsPermission) {
            return AppRoutes.notificationsPermission;
          }
          if (!needsNotifPrompt &&
              loc == AppRoutes.notificationsPermission) {
            return AppRoutes.home;
          }
          if (loc == AppRoutes.login ||
              loc == AppRoutes.welcome ||
              loc == AppRoutes.splash ||
              loc == AppRoutes.householdSetup) {
            return AppRoutes.home;
          }
          if (!isShellRoute &&
              loc != AppRoutes.notificationsPermission &&
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
        builder: (context, state) => const StartupPage(),
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
      GoRoute(
        path: AppRoutes.notificationsPermission,
        builder: (context, state) => const NotificationPermissionPage(),
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
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const PetFormPage(),
                  ),
                  GoRoute(
                    path: 'pet/:petId',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        PetDetailPage(petId: state.pathParameters['petId']!),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) =>
                            PetFormPage(existing: state.extra as Pet?),
                      ),
                      GoRoute(
                        path: 'weights',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) {
                          final args = state.extra! as PetWeightArgs;
                          return PetWeightPage(
                            householdId: args.householdId,
                            petId: args.petId,
                            petName: args.petName,
                          );
                        },
                      ),
                      GoRoute(
                        path: 'health',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) {
                          final args = state.extra! as PetHealthArgs;
                          return PetHealthPage(
                            householdId: args.householdId,
                            petId: args.petId,
                            petName: args.petName,
                          );
                        },
                      ),
                      GoRoute(
                        path: 'gallery',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) {
                          final args = state.extra! as PetGalleryArgs;
                          return PetGalleryPage(
                            householdId: args.householdId,
                            petId: args.petId,
                            petName: args.petName,
                          );
                        },
                      ),
                      GoRoute(
                        path: 'documents',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) {
                          final args = state.extra! as PetDocumentsArgs;
                          return PetDocumentsPage(
                            householdId: args.householdId,
                            petId: args.petId,
                            petName: args.petName,
                          );
                        },
                      ),
                      GoRoute(
                        path: 'vaccinations',
                        parentNavigatorKey: _rootNavigatorKey,
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
                            parentNavigatorKey: _rootNavigatorKey,
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
                            parentNavigatorKey: _rootNavigatorKey,
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
                builder: (context, state) => const RemindersHomePage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const ReminderFormPage(),
                  ),
                  GoRoute(
                    path: ':reminderId/edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => ReminderFormPage(
                      existing: state.extra as Reminder?,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.stats,
                builder: (context, state) => const InsightsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: 'family',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const HouseholdMembersPage(),
                    routes: [
                      GoRoute(
                        path: 'audit',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => HouseholdAuditPage(
                          householdId: state.extra! as String,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Bridges one or more Bloc/Cubit streams to go_router's `refreshListenable`
/// (which expects a `Listenable`). Any emission from any source notifies
/// listeners, so the redirect re-evaluates on auth *or* startup changes.
class _BlocChangeNotifier extends ChangeNotifier {
  _BlocChangeNotifier(List<Stream<dynamic>> streams) {
    _subs = [
      for (final stream in streams)
        stream.listen((_) => notifyListeners()),
    ];
  }

  late final List<StreamSubscription<dynamic>> _subs;

  @override
  void dispose() {
    for (final sub in _subs) {
      unawaited(sub.cancel());
    }
    super.dispose();
  }
}
