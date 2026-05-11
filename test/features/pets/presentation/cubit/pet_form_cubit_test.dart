import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/pets/domain/entities/pet.dart';
import 'package:my_pet/features/pets/presentation/cubit/pet_form_cubit.dart';

import '../../../../harness/factories/pet_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockPetRepository repository;

  setUpAll(() {
    registerFallbackValue(PetFactory.build());
  });

  setUp(() {
    repository = MockPetRepository();
  });

  PetFormCubit buildCubit() => PetFormCubit(repository: repository);

  group('PetFormCubit', () {
    blocTest<PetFormCubit, PetFormState>(
      'create: Submitting -> Success',
      build: () {
        final pet = PetFactory.build();
        when(() => repository.create(any()))
            .thenAnswer((_) async => Right<Failure, Pet>(pet));
        return buildCubit();
      },
      act: (cubit) => cubit.create(PetFactory.build()),
      expect: () => [
        const PetFormSubmitting(),
        PetFormSuccess(PetFactory.build()),
      ],
    );

    blocTest<PetFormCubit, PetFormState>(
      'create: validation failure -> Error',
      build: () {
        when(() => repository.create(any())).thenAnswer(
          (_) async => const Left(ValidationFailure(message: 'bad')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.create(PetFactory.build()),
      expect: () => [
        const PetFormSubmitting(),
        const PetFormError(ValidationFailure(message: 'bad')),
      ],
    );

    blocTest<PetFormCubit, PetFormState>(
      'update: Submitting -> Success',
      build: () {
        final pet = PetFactory.build(name: 'Renamed');
        when(() => repository.update(any()))
            .thenAnswer((_) async => Right<Failure, Pet>(pet));
        return buildCubit();
      },
      act: (cubit) => cubit.update(PetFactory.build(name: 'Renamed')),
      expect: () => [
        const PetFormSubmitting(),
        PetFormSuccess(PetFactory.build(name: 'Renamed')),
      ],
    );
  });
}
