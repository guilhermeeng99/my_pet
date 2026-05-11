import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/household/domain/entities/invite.dart';
import 'package:my_pet/features/household/presentation/cubit/invite_cubit.dart';

import '../../../../harness/mocks.dart';

Invite _stubInvite() => Invite(
      code: 'ABC123',
      householdId: 'h',
      createdBy: 'uid_123',
      createdAt: DateTime.utc(2026, 5, 10),
      expiresAt: DateTime.utc(2026, 5, 11),
    );

void main() {
  late MockHouseholdRepository repository;

  setUp(() {
    repository = MockHouseholdRepository();
  });

  InviteCubit buildCubit() => InviteCubit(repository: repository);

  group('InviteCubit', () {
    blocTest<InviteCubit, InviteState>(
      'generate: Generating -> Generated on success',
      build: () {
        when(
          () => repository.generateInvite(
            householdId: any(named: 'householdId'),
            createdBy: any(named: 'createdBy'),
          ),
        ).thenAnswer((_) async => Right<Failure, Invite>(_stubInvite()));
        return buildCubit();
      },
      act: (cubit) =>
          cubit.generate(householdId: 'h', createdBy: 'uid_123'),
      expect: () => [
        const InviteGenerating(),
        InviteGenerated(_stubInvite()),
      ],
    );

    blocTest<InviteCubit, InviteState>(
      'generate: HouseholdFullFailure surfaces InviteError',
      build: () {
        when(
          () => repository.generateInvite(
            householdId: any(named: 'householdId'),
            createdBy: any(named: 'createdBy'),
          ),
        ).thenAnswer((_) async => const Left(HouseholdFullFailure()));
        return buildCubit();
      },
      act: (cubit) =>
          cubit.generate(householdId: 'h', createdBy: 'uid_123'),
      expect: () => [
        const InviteGenerating(),
        const InviteError(HouseholdFullFailure()),
      ],
    );

    blocTest<InviteCubit, InviteState>(
      'reset returns to Idle',
      build: buildCubit,
      seed: () => InviteGenerated(_stubInvite()),
      act: (cubit) => cubit.reset(),
      expect: () => [const InviteIdle()],
    );
  });
}
