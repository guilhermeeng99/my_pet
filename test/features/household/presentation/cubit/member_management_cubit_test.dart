import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/household/domain/entities/household.dart';
import 'package:my_pet/features/household/domain/entities/household_member.dart';
import 'package:my_pet/features/household/presentation/cubit/member_management_cubit.dart';

import '../../../../harness/factories/auth_user_factory.dart';
import '../../../../harness/factories/household_factory.dart';
import '../../../../harness/mocks.dart';

const _partner = HouseholdMember(
  uid: 'uid_partner',
  email: 'p@example.com',
  role: HouseholdRole.partner,
);

void main() {
  late MockHouseholdRepository repository;

  setUpAll(() {
    registerFallbackValue(AuthUserFactory.withHousehold());
    registerFallbackValue(_partner);
  });

  setUp(() {
    repository = MockHouseholdRepository();
  });

  MemberManagementCubit buildCubit() =>
      MemberManagementCubit(repository: repository);

  group('MemberManagementCubit', () {
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
          (_) async => Right<Failure, Household>(HouseholdFactory.build()),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.remove(
        householdId: 'h',
        actor: AuthUserFactory.withHousehold(),
        target: _partner,
      ),
      expect: () => [
        const MemberManagementBusy(),
        const MemberManagementSuccess(MemberManagementAction.remove),
      ],
    );

    blocTest<MemberManagementCubit, MemberManagementState>(
      'transfer failure emits Busy -> Error(transfer, …)',
      build: () {
        when(
          () => repository.transferOwnership(
            householdId: any(named: 'householdId'),
            actor: any(named: 'actor'),
            newOwner: any(named: 'newOwner'),
          ),
        ).thenAnswer(
          (_) async => const Left(PermissionFailure(message: 'not owner')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.transfer(
        householdId: 'h',
        actor: AuthUserFactory.withHousehold(),
        newOwner: _partner,
      ),
      expect: () => [
        const MemberManagementBusy(),
        const MemberManagementError(
          MemberManagementAction.transfer,
          PermissionFailure(message: 'not owner'),
        ),
      ],
    );

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
  });
}
