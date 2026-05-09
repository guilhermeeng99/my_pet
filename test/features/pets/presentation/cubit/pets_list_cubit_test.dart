import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/features/pets/domain/entities/pet.dart';
import 'package:my_pet/features/pets/presentation/cubit/pets_list_cubit.dart';

import '../../../../harness/factories/pet_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockPetRepository repository;

  setUp(() {
    repository = MockPetRepository();
  });

  PetsListCubit buildCubit() => PetsListCubit(repository: repository);

  group('PetsListCubit', () {
    blocTest<PetsListCubit, PetsListState>(
      'emits Loading then Loaded with pets',
      build: () {
        when(() => repository.watchActive('h'))
            .thenAnswer((_) => Stream<List<Pet>>.value([PetFactory.build()]));
        return buildCubit();
      },
      act: (cubit) => cubit.start('h'),
      expect: () => [
        const PetsListLoading(),
        PetsListLoaded([PetFactory.build()]),
      ],
    );

    blocTest<PetsListCubit, PetsListState>(
      'emits Empty when stream yields an empty list',
      build: () {
        when(() => repository.watchActive('h'))
            .thenAnswer((_) => Stream<List<Pet>>.value(const []));
        return buildCubit();
      },
      act: (cubit) => cubit.start('h'),
      expect: () => [const PetsListLoading(), const PetsListEmpty()],
    );

    blocTest<PetsListCubit, PetsListState>(
      'emits Error when the stream errors',
      build: () {
        when(() => repository.watchActive('h')).thenAnswer(
          (_) => Stream<List<Pet>>.error(Exception('boom')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.start('h'),
      expect: () => [
        const PetsListLoading(),
        isA<PetsListError>(),
      ],
    );
  });
}
