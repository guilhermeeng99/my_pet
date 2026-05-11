import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/household/domain/entities/household.dart';
import 'package:my_pet/features/household/domain/entities/household_member.dart';
import 'package:my_pet/features/household/presentation/cubit/household_cubit.dart';

import '../../../../harness/factories/household_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockHouseholdRepository repository;

  setUpAll(() {
    registerFallbackValue(HouseholdFactory.build());
  });

  setUp(() {
    repository = MockHouseholdRepository();
  });

  HouseholdCubit buildCubit() => HouseholdCubit(repository: repository);

  group('HouseholdCubit', () {
    blocTest<HouseholdCubit, HouseholdState>(
      'watch + fetchMembers success -> Loaded',
      build: () {
        final household = HouseholdFactory.build();
        when(() => repository.watch('h'))
            .thenAnswer((_) => Stream<Household?>.value(household));
        when(() => repository.fetchMembers(any())).thenAnswer(
          (_) async => const Right<Failure, List<HouseholdMember>>([
            HouseholdMember(
              uid: 'uid_123',
              email: 'jane@example.com',
              role: HouseholdRole.owner,
            ),
          ]),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.start('h'),
      verify: (cubit) {
        expect(cubit.state, isA<HouseholdLoaded>());
        expect((cubit.state as HouseholdLoaded).hasPartner, isFalse);
      },
    );

    blocTest<HouseholdCubit, HouseholdState>(
      'watch yields null -> NotFound',
      build: () {
        when(() => repository.watch('h'))
            .thenAnswer((_) => Stream<Household?>.value(null));
        return buildCubit();
      },
      act: (cubit) => cubit.start('h'),
      expect: () => [const HouseholdLoading(), const HouseholdNotFound()],
    );

    blocTest<HouseholdCubit, HouseholdState>(
      'fetchMembers failure -> HouseholdError',
      build: () {
        final household = HouseholdFactory.build();
        when(() => repository.watch('h'))
            .thenAnswer((_) => Stream<Household?>.value(household));
        when(() => repository.fetchMembers(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'rules denied')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.start('h'),
      verify: (cubit) {
        expect(cubit.state, isA<HouseholdError>());
      },
    );
  });
}
