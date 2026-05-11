import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/household/presentation/cubit/account_deletion_cubit.dart';

import '../../../../harness/mocks.dart';

void main() {
  late MockHouseholdRepository households;
  late MockAuthRepository auth;

  setUp(() {
    households = MockHouseholdRepository();
    auth = MockAuthRepository();
  });

  AccountDeletionCubit buildCubit() =>
      AccountDeletionCubit(households: households, auth: auth);

  group('AccountDeletionCubit', () {
    blocTest<AccountDeletionCubit, AccountDeletionState>(
      'wipe success + auth delete success -> Done',
      build: () {
        when(
          () => households.wipeAndLeave(
            householdId: any(named: 'householdId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => const Right(unit));
        when(auth.deleteCurrentAccount)
            .thenAnswer((_) async => const Right(unit));
        return buildCubit();
      },
      act: (cubit) => cubit.run(householdId: 'h', userId: 'u'),
      expect: () => [
        const AccountDeletionDeleting(),
        const AccountDeletionDone(),
      ],
    );

    blocTest<AccountDeletionCubit, AccountDeletionState>(
      'wipe failure short-circuits without calling auth delete',
      build: () {
        when(
          () => households.wipeAndLeave(
            householdId: any(named: 'householdId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => const Left(HouseholdNotEmptyFailure()));
        return buildCubit();
      },
      act: (cubit) => cubit.run(householdId: 'h', userId: 'u'),
      expect: () => [
        const AccountDeletionDeleting(),
        const AccountDeletionFailed(HouseholdNotEmptyFailure()),
      ],
      verify: (_) => verifyNever(auth.deleteCurrentAccount),
    );

    blocTest<AccountDeletionCubit, AccountDeletionState>(
      'auth delete failure surfaces RequiresRecentLogin without losing data',
      build: () {
        when(
          () => households.wipeAndLeave(
            householdId: any(named: 'householdId'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => const Right(unit));
        when(auth.deleteCurrentAccount)
            .thenAnswer((_) async => const Left(RequiresRecentLoginFailure()));
        return buildCubit();
      },
      act: (cubit) => cubit.run(householdId: 'h', userId: 'u'),
      expect: () => [
        const AccountDeletionDeleting(),
        const AccountDeletionFailed(RequiresRecentLoginFailure()),
      ],
    );
  });
}
