// Centralized mock declarations. Add a `class MockX extends Mock
// implements X {}` line per boundary that needs to be stubbed in tests.
// (CLAUDE.md / Harness Engineering)

import 'package:mocktail/mocktail.dart';

import 'package:my_pet/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:my_pet/features/auth/data/datasources/user_profile_datasource.dart';
import 'package:my_pet/features/auth/domain/repositories/auth_repository.dart';

class MockFirebaseAuthDatasource extends Mock
    implements FirebaseAuthDatasource {}

class MockUserProfileDatasource extends Mock implements UserProfileDatasource {}

class MockAuthRepository extends Mock implements AuthRepository {}
