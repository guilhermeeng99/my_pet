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
    ..registerLazySingleton<AuthBloc>(() => AuthBloc(repository: sl()))
    ..registerSingleton<bool>(true, instanceName: '_diReady');
}
