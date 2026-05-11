import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/household/domain/entities/household.dart';
import 'package:my_pet/features/household/domain/entities/household_member.dart';
import 'package:my_pet/features/household/presentation/cubit/member_management_cubit.dart';

import '../../../../harness/factories/auth_user_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockHouseholdRepository repository;

  const partner = HouseholdMember(
    uid: 'partner_456',
    email: 'partner@example.com',
    role: HouseholdRole.partner,
    displayName: 'Sam',
  );

  setUpAll(() {
    registerFallbackValue(AuthUserFactory.withHousehold());
    registerFallbackValue(partner);
  });

  setUp(() {
    repository = MockHouseholdRepository();
  });

  MemberManagementCubit buildCubit() =>
      MemberManagementCubit(repository: repository);

  group('MemberManagementCubit', () {
    blocTest<MemberManagementCubit, MemberManagementState>(
      'leave success emits Busy -> Success(leave)',
      build: () {
        when(
          () => repository.leaveHousehold(
            householdId: any(named: 'householdId'),
            actor: any(named: 'actor'),
          ),
        ).thenAnswer((_) async => const Right(unit));
        return buildCubit();
      },
      act: (cubit) => cubit.leave(
        householdId: 'h',
        actor: AuthUserFactory.withHousehold(),
      ),
      expect: () => [
        const MemberManagementBusy(),
        const MemberManagementSuccess(MemberManagementAction.leave),
      ],
    );

    blocTest<MemberManagementCubit, MemberManagementState>(
      'leave failure emits Busy -> Error(leave, …)',
      build: () {
        when(
          () => repository.leaveHousehold(
            householdId: any(named: 'householdId'),
            actor: any(named: 'actor'),
          ),
        ).thenAnswer(
          (_) async =>
              const Left(ValidationFailure(message: 'cannot leave')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.leave(
        householdId: 'h',
        actor: AuthUserFactory.withHousehold(),
      ),
      expect: () => [
        const MemberManagementBusy(),
        const MemberManagementError(
          MemberManagementAction.leave,
          ValidationFailure(message: 'cannot leave'),
        ),
      ],
    );

    blocTest<MemberManagementCubit, MemberManagementState>(
      'remove success emits Busy -> Success(remove)',
      build: () {
        when(
          () => repository.removeMember(
            householdId: any(named: 'householdId'),
            actor: any(named: 'actor'),
            target: any(named: 'target'),
          ),
        ).thenAnswer(
          (_) async => Right(
            Household(
              id: 'h',
              name: 'Home',
              ownerId: 'uid_123',
              memberIds: const ['uid_123'],
              createdAt: DateTime(2026, 5, 11),
            ),
          ),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.remove(
        householdId: 'h',
        actor: AuthUserFactory.withHousehold(),
        target: partner,
      ),
      expect: () => [
        const MemberManagementBusy(),
        const MemberManagementSuccess(MemberManagementAction.remove),
      ],
    );

    blocTest<MemberManagementCubit, MemberManagementState>(
      'remove failure emits Busy -> Error(remove, …)',
      build: () {
        when(
          () => repository.removeMember(
            householdId: any(named: 'householdId'),
            actor: any(named: 'actor'),
            target: any(named: 'target'),
          ),
        ).thenAnswer(
          (_) async => const Left(PermissionFailure(message: 'not owner')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.remove(
        householdId: 'h',
        actor: AuthUserFactory.withHousehold(),
        target: partner,
      ),
      expect: () => [
        const MemberManagementBusy(),
        const MemberManagementError(
          MemberManagementAction.remove,
          PermissionFailure(message: 'not owner'),
        ),
      ],
    );
  });
}
