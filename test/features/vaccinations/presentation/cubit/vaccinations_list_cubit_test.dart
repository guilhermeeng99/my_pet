import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/features/vaccinations/domain/entities/vaccination.dart';
import 'package:my_pet/features/vaccinations/domain/entities/vaccination_status.dart';
import 'package:my_pet/features/vaccinations/presentation/cubit/vaccinations_list_cubit.dart';

import '../../../../harness/factories/vaccination_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockVaccinationRepository repository;

  setUp(() {
    repository = MockVaccinationRepository();
  });

  VaccinationsListCubit buildCubit() =>
      VaccinationsListCubit(repository: repository);

  group('VaccinationsListCubit', () {
    blocTest<VaccinationsListCubit, VaccinationsListState>(
      'emits Loading then a Loaded with empty groups when no records',
      build: () {
        when(() => repository.watchByPet('h', 'p'))
            .thenAnswer((_) => Stream<List<Vaccination>>.value(const []));
        return buildCubit();
      },
      act: (cubit) => cubit.start('h', 'p'),
      verify: (cubit) {
        final state = cubit.state;
        expect(state, isA<VaccinationsListLoaded>());
        expect((state as VaccinationsListLoaded).isEmpty, isTrue);
      },
    );

    blocTest<VaccinationsListCubit, VaccinationsListState>(
      'groups vaccinations by VaccinationStatus',
      build: () {
        final now = DateTime.now().toUtc();
        final list = [
          // Past due -> overdue
          VaccinationFactory.build(
            id: 'late',
            nextDueDate: now.subtract(const Duration(days: 3)),
          ),
          // Within 30 days -> dueSoon
          VaccinationFactory.build(
            id: 'soon',
            nextDueDate: now.add(const Duration(days: 10)),
          ),
          // Beyond 30 days -> upToDate
          VaccinationFactory.build(
            id: 'ok',
            nextDueDate: now.add(const Duration(days: 200)),
          ),
          // No next dose -> noNextDose
          VaccinationFactory.build(id: 'none'),
        ];
        when(() => repository.watchByPet('h', 'p'))
            .thenAnswer((_) => Stream<List<Vaccination>>.value(list));
        return buildCubit();
      },
      act: (cubit) => cubit.start('h', 'p'),
      verify: (cubit) {
        final loaded = cubit.state as VaccinationsListLoaded;
        expect(loaded.grouped[VaccinationStatus.overdue]!.map((v) => v.id),
            ['late']);
        expect(loaded.grouped[VaccinationStatus.dueSoon]!.map((v) => v.id),
            ['soon']);
        expect(loaded.grouped[VaccinationStatus.upToDate]!.map((v) => v.id),
            ['ok']);
        expect(loaded.grouped[VaccinationStatus.noNextDose]!.map((v) => v.id),
            ['none']);
      },
    );

    blocTest<VaccinationsListCubit, VaccinationsListState>(
      'emits Error when the stream errors',
      build: () {
        when(() => repository.watchByPet('h', 'p'))
            .thenAnswer((_) => Stream<List<Vaccination>>.error(Exception()));
        return buildCubit();
      },
      act: (cubit) => cubit.start('h', 'p'),
      expect: () => [
        const VaccinationsListLoading(),
        isA<VaccinationsListError>(),
      ],
    );
  });
}
