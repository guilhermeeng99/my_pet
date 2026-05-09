// Centralized mock declarations. Add a `class MockX extends Mock
// implements X {}` line per boundary that needs to be stubbed in tests.
// (CLAUDE.md / Harness Engineering)

import 'package:mocktail/mocktail.dart';

import 'package:my_pet/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:my_pet/features/auth/data/datasources/user_profile_datasource.dart';
import 'package:my_pet/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_pet/features/household/data/datasources/household_firestore_datasource.dart';
import 'package:my_pet/features/household/domain/repositories/household_repository.dart';
import 'package:my_pet/features/pets/data/datasources/pet_firestore_datasource.dart';
import 'package:my_pet/features/pets/domain/repositories/pet_repository.dart';

class MockFirebaseAuthDatasource extends Mock
    implements FirebaseAuthDatasource {}

class MockUserProfileDatasource extends Mock implements UserProfileDatasource {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockHouseholdFirestoreDatasource extends Mock
    implements HouseholdFirestoreDatasource {}

class MockHouseholdRepository extends Mock implements HouseholdRepository {}

class MockPetFirestoreDatasource extends Mock implements PetFirestoreDatasource {}

class MockPetRepository extends Mock implements PetRepository {}
