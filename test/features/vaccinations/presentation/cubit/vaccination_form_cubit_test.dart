import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/vaccinations/domain/entities/vaccination.dart';
import 'package:my_pet/features/vaccinations/presentation/cubit/vaccination_form_cubit.dart';

import '../../../../harness/factories/vaccination_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockVaccinationRepository repository;

  setUpAll(() {
    registerFallbackValue(VaccinationFactory.build());
  });

  setUp(() {
    repository = MockVaccinationRepository();
  });

  VaccinationFormCubit buildCubit() =>
      VaccinationFormCubit(repository: repository);

  group('VaccinationFormCubit', () {
    blocTest<VaccinationFormCubit, VaccinationFormState>(
      'create: Submitting -> Success',
      build: () {
        when(() => repository.create(any())).thenAnswer(
          (_) async => Right<Failure, Vaccination>(VaccinationFactory.build()),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.create(VaccinationFactory.build()),
      expect: () => [
        const VaccinationFormSubmitting(),
        const VaccinationFormSuccess(),
      ],
    );

    blocTest<VaccinationFormCubit, VaccinationFormState>(
      'update failure -> Error',
      build: () {
        when(() => repository.update(any())).thenAnswer(
          (_) async => const Left(ValidationFailure(message: 'bad')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.update(VaccinationFactory.build()),
      expect: () => [
        const VaccinationFormSubmitting(),
        const VaccinationFormError(ValidationFailure(message: 'bad')),
      ],
    );

    blocTest<VaccinationFormCubit, VaccinationFormState>(
      'delete: Submitting -> Success',
      build: () {
        when(() => repository.delete(any(), any(), any()))
            .thenAnswer((_) async => const Right(unit));
        return buildCubit();
      },
      act: (cubit) => cubit.delete(VaccinationFactory.build()),
      expect: () => [
        const VaccinationFormSubmitting(),
        const VaccinationFormSuccess(),
      ],
    );
  });
}
