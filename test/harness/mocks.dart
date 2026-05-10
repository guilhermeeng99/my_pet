// Centralized mock declarations. Add a `class MockX extends Mock
// implements X {}` line per boundary that needs to be stubbed in tests.
// (CLAUDE.md / Harness Engineering)

import 'package:mocktail/mocktail.dart';

import 'package:my_pet/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:my_pet/features/auth/data/datasources/user_profile_datasource.dart';
import 'package:my_pet/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_pet/features/health/data/datasources/health_firestore_datasource.dart';
import 'package:my_pet/features/health/domain/repositories/health_repository.dart';
import 'package:my_pet/features/household/data/datasources/household_firestore_datasource.dart';
import 'package:my_pet/features/household/domain/repositories/household_repository.dart';
import 'package:my_pet/features/notifications/domain/notification_service.dart';
import 'package:my_pet/features/pets/data/datasources/pet_firestore_datasource.dart';
import 'package:my_pet/features/pets/domain/repositories/pet_repository.dart';
import 'package:my_pet/features/reminders/data/datasources/reminder_firestore_datasource.dart';
import 'package:my_pet/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:my_pet/features/vaccinations/data/datasources/vaccination_firestore_datasource.dart';
import 'package:my_pet/features/vaccinations/domain/repositories/vaccination_repository.dart';
import 'package:my_pet/features/weight/data/datasources/weight_firestore_datasource.dart';
import 'package:my_pet/features/weight/domain/repositories/weight_repository.dart';

class MockFirebaseAuthDatasource extends Mock
    implements FirebaseAuthDatasource {}

class MockUserProfileDatasource extends Mock implements UserProfileDatasource {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockHealthFirestoreDatasource extends Mock
    implements HealthFirestoreDatasource {}

class MockHealthRepository extends Mock implements HealthRepository {}

class MockHouseholdFirestoreDatasource extends Mock
    implements HouseholdFirestoreDatasource {}

class MockHouseholdRepository extends Mock implements HouseholdRepository {}

class MockPetFirestoreDatasource extends Mock implements PetFirestoreDatasource {}

class MockPetRepository extends Mock implements PetRepository {}

class MockVaccinationFirestoreDatasource extends Mock
    implements VaccinationFirestoreDatasource {}

class MockVaccinationRepository extends Mock implements VaccinationRepository {}

class MockReminderFirestoreDatasource extends Mock
    implements ReminderFirestoreDatasource {}

class MockReminderRepository extends Mock implements ReminderRepository {}

class MockWeightFirestoreDatasource extends Mock
    implements WeightFirestoreDatasource {}

class MockWeightRepository extends Mock implements WeightRepository {}

class MockNotificationService extends Mock implements NotificationService {}
