import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/household/presentation/cubit/member_management_cubit.dart';

import '../../../../harness/factories/auth_user_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockHouseholdRepository repository;

  setUpAll(() {
    registerFallbackValue(AuthUserFactory.withHousehold());
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
  });
}
