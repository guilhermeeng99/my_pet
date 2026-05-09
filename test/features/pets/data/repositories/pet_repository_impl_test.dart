import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/pets/data/models/pet_model.dart';
import 'package:my_pet/features/pets/data/repositories/pet_repository_impl.dart';

import '../../../../harness/factories/pet_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockPetFirestoreDatasource datasource;
  late PetRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(PetFactory.buildModel());
  });

  setUp(() {
    datasource = MockPetFirestoreDatasource();
    repository = PetRepositoryImpl(datasource: datasource);
  });

  group('create', () {
    test('returns ValidationFailure when name is blank', () async {
      final pet = PetFactory.build(name: '   ');

      final result = await repository.create(pet);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('expected Left'),
      );
      verifyNever(() => datasource.create(any()));
    });

    test('returns ValidationFailure for a future birthDate', () async {
      final pet = PetFactory.build(
        birthDate: DateTime.now().add(const Duration(days: 1)).toUtc(),
      );

      final result = await repository.create(pet);

      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('persists via datasource on valid input', () async {
      final pet = PetFactory.build();
      when(() => datasource.create(any()))
          .thenAnswer((_) async => PetModel.fromEntity(pet));

      final result = await repository.create(pet);

      expect(result.isRight(), isTrue);
      verify(() => datasource.create(any())).called(1);
    });

    test('wraps datasource exceptions in ServerFailure', () async {
      final pet = PetFactory.build();
      when(() => datasource.create(any())).thenThrow(Exception('boom'));

      final result = await repository.create(pet);

      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('archive', () {
    test('forwards to datasource', () async {
      when(() => datasource.archive('h', 'p')).thenAnswer((_) async {});
      final result = await repository.archive('h', 'p');
      expect(result.isRight(), isTrue);
      verify(() => datasource.archive('h', 'p')).called(1);
    });
  });
}
