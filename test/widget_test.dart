// Smoke test for the design system. Phase 0 cannot pump MyPetApp directly
// because bootstrap requires Firebase + Hive — that is covered by
// integration tests once they land. Here we verify the AppTheme builds
// without errors and renders the welcome page.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_pet/app/theme/app_theme.dart';
import 'package:my_pet/features/onboarding/presentation/welcome_page.dart';

void main() {
  testWidgets('Welcome page renders with light theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const WelcomePage(),
      ),
    );

    expect(find.byType(WelcomePage), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('Welcome page renders with dark theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const WelcomePage(),
      ),
    );

    expect(find.byType(WelcomePage), findsOneWidget);
  });
}
