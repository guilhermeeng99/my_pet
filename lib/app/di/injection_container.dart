import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:my_pet/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:my_pet/features/auth/data/datasources/user_profile_datasource.dart';
import 'package:my_pet/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:my_pet/features/auth/domain/repositories/auth_repository.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/household/data/datasources/household_firestore_datasource.dart';
import 'package:my_pet/features/household/data/repositories/household_repository_impl.dart';
import 'package:my_pet/features/household/domain/repositories/household_repository.dart';
import 'package:my_pet/features/pets/data/datasources/pet_firestore_datasource.dart';
import 'package:my_pet/features/pets/data/repositories/pet_repository_impl.dart';
import 'package:my_pet/features/pets/domain/repositories/pet_repository.dart';
import 'package:my_pet/features/pets/presentation/cubit/pet_form_cubit.dart';
import 'package:my_pet/features/pets/presentation/cubit/pets_list_cubit.dart';
import 'package:my_pet/features/vaccinations/data/datasources/vaccination_firestore_datasource.dart';
import 'package:my_pet/features/vaccinations/data/repositories/vaccination_repository_impl.dart';
import 'package:my_pet/features/vaccinations/domain/repositories/vaccination_repository.dart';
import 'package:my_pet/features/vaccinations/presentation/cubit/vaccination_form_cubit.dart';
import 'package:my_pet/features/vaccinations/presentation/cubit/vaccinations_list_cubit.dart';

/// Service locator. All implementations are registered here.
///
/// - `registerLazySingleton` — global services (auth repo, sync engine).
/// - `registerFactory` — short-lived objects like form cubits.
final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  if (sl.isRegistered<bool>(instanceName: '_diReady')) return;

  sl
    // ── Firebase / Google clients ───────────────────────────────────
    ..registerLazySingleton<fb.FirebaseAuth>(() => fb.FirebaseAuth.instance)
    ..registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance)
    ..registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance)
    ..registerLazySingleton<GoogleSignIn>(() => GoogleSignIn.instance)
    // ── Auth feature ────────────────────────────────────────────────
    ..registerLazySingleton<FirebaseAuthDatasource>(
      () => FirebaseAuthDatasourceImpl(
        firebaseAuth: sl(),
        googleSignIn: sl(),
      ),
    )
    ..registerLazySingleton<UserProfileDatasource>(
      () => UserProfileDatasourceImpl(firestore: sl()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(auth: sl(), profiles: sl()),
    )
    // ── Household feature ───────────────────────────────────────────
    ..registerLazySingleton<HouseholdFirestoreDatasource>(
      () => HouseholdFirestoreDatasourceImpl(firestore: sl()),
    )
    ..registerLazySingleton<HouseholdRepository>(
      () => HouseholdRepositoryImpl(datasource: sl()),
    )
    // AuthBloc depends on HouseholdRepository for first-sign-in auto-create.
    ..registerLazySingleton<AuthBloc>(
      () => AuthBloc(repository: sl(), householdRepository: sl()),
    )
    // ── Pets feature ────────────────────────────────────────────────
    ..registerLazySingleton<PetFirestoreDatasource>(
      () => PetFirestoreDatasourceImpl(firestore: sl()),
    )
    ..registerLazySingleton<PetRepository>(
      () => PetRepositoryImpl(datasource: sl()),
    )
    // List cubit is a singleton — keeps the active-pets stream alive
    // across detail navigation (avoids re-fetching on pop).
    ..registerLazySingleton<PetsListCubit>(
      () => PetsListCubit(repository: sl()),
    )
    // Form cubit is per-form session.
    ..registerFactory<PetFormCubit>(() => PetFormCubit(repository: sl()))
    // ── Vaccinations feature ────────────────────────────────────────
    ..registerLazySingleton<VaccinationFirestoreDatasource>(
      () => VaccinationFirestoreDatasourceImpl(firestore: sl()),
    )
    ..registerLazySingleton<VaccinationRepository>(
      () => VaccinationRepositoryImpl(datasource: sl()),
    )
    // List cubit is per-pet session — created when entering the page,
    // disposed by BlocProvider on pop.
    ..registerFactory<VaccinationsListCubit>(
      () => VaccinationsListCubit(repository: sl()),
    )
    ..registerFactory<VaccinationFormCubit>(
      () => VaccinationFormCubit(repository: sl()),
    )
    ..registerSingleton<bool>(true, instanceName: '_diReady');
}
