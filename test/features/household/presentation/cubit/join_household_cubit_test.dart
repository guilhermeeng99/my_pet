import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/household/domain/entities/household.dart';
import 'package:my_pet/features/household/presentation/cubit/join_household_cubit.dart';

import '../../../../harness/factories/household_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockHouseholdRepository repository;

  setUp(() {
    repository = MockHouseholdRepository();
  });

  JoinHouseholdCubit buildCubit() =>
      JoinHouseholdCubit(repository: repository);

  group('JoinHouseholdCubit', () {
    blocTest<JoinHouseholdCubit, JoinHouseholdState>(
      'codes shorter than 6 chars short-circuit before any network call',
      build: buildCubit,
      act: (cubit) => cubit.submit(code: 'AB', userId: 'u'),
      expect: () => [const JoinHouseholdInvalidLength()],
      verify: (_) => verifyNever(
        () => repository.acceptInvite(
          code: any(named: 'code'),
          userId: any(named: 'userId'),
        ),
      ),
    );

    blocTest<JoinHouseholdCubit, JoinHouseholdState>(
      'submit: Submitting -> Joined on success',
      build: () {
        final h = HouseholdFactory.build();
        when(
          () => repository.acceptInvite(
            code: any(named: 'code'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => Right<Failure, Household>(h));
        return buildCubit();
      },
      act: (cubit) => cubit.submit(code: 'abc123', userId: 'u'),
      expect: () => [
        const JoinHouseholdSubmitting(),
        JoinHouseholdJoined(HouseholdFactory.build()),
      ],
      verify: (_) {
        // Codes must be normalized (trim + uppercase) before the call.
        verify(() => repository.acceptInvite(code: 'ABC123', userId: 'u'))
            .called(1);
      },
    );

    blocTest<JoinHouseholdCubit, JoinHouseholdState>(
      'submit: InviteExpiredFailure surfaces JoinHouseholdError',
      build: () {
        when(
          () => repository.acceptInvite(
            code: any(named: 'code'),
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => const Left(InviteExpiredFailure()));
        return buildCubit();
      },
      act: (cubit) => cubit.submit(code: 'ABC123', userId: 'u'),
      expect: () => [
        const JoinHouseholdSubmitting(),
        const JoinHouseholdError(InviteExpiredFailure()),
      ],
    );
  });
}
