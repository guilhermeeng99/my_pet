// Smoke test for the design system. Phase 0 cannot pump MyPetApp directly
// because bootstrap requires Firebase + Hive — that is covered by
// integration tests once they land. Here we verify the AppTheme builds
// without errors and renders the consolidated login page (sign-in is the
// only unauthenticated entry point — the old WelcomePage was removed).

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_pet/app/theme/app_theme.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/auth/presentation/pages/login_page.dart';

import 'harness/mocks.dart';

void main() {
  testWidgets('Login page renders with light theme', (tester) async {
    final authBloc = MockAuthBloc();
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthUnauthenticated(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const LoginPage(),
        ),
      ),
    );

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
