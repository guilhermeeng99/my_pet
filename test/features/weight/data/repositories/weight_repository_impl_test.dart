import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/weight/data/models/weight_entry_model.dart';
import 'package:my_pet/features/weight/data/repositories/weight_repository_impl.dart';

import '../../../../harness/factories/weight_entry_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockWeightFirestoreDatasource datasource;
  late MockPetFirestoreDatasource pets;
  late WeightRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(WeightEntryFactory.buildModel());
  });

  setUp(() {
    datasource = MockWeightFirestoreDatasource();
    pets = MockPetFirestoreDatasource();
    repository = WeightRepositoryImpl(datasource: datasource, pets: pets);

    when(() => pets.setCurrentWeight(any(), any(), any()))
        .thenAnswer((_) async {});
  });

  group('create', () {
    test('rejects zero/negative or > 200 kg weights', () async {
      final tooLight = WeightEntryFactory.build(weightKg: 0);
      final tooHeavy = WeightEntryFactory.build(weightKg: 250);

      final r1 = await repository.create(tooLight);
      final r2 = await repository.create(tooHeavy);

      r1.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('expected Left'),
      );
      r2.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('expected Left'),
      );
      verifyNever(() => datasource.create(any()));
    });

    test('rejects future-dated entries', () async {
      final entry = WeightEntryFactory.build(
        date: DateTime.now().toUtc().add(const Duration(days: 1)),
      );
      final result = await repository.create(entry);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('persists and cascades to pet.currentWeightKg when latest',
        () async {
      final entry = WeightEntryFactory.build(weightKg: 4.5);
      when(() => datasource.create(any()))
          .thenAnswer((_) async => WeightEntryModel.fromEntity(entry));
      when(() => datasource.watchByPet(any(), any())).thenAnswer(
        (_) => Stream.value([WeightEntryModel.fromEntity(entry)]),
      );

      final result = await repository.create(entry);

      expect(result.isRight(), isTrue);
      verify(() => datasource.create(any())).called(1);
      verify(() => pets.setCurrentWeight('household_42', 'pet_1', 4.5))
          .called(1);
    });

    test('does not overwrite currentWeightKg with a backfilled older entry',
        () async {
      final newer = WeightEntryFactory.build(
        id: 'newer',
        date: DateTime.utc(2026, 5, 10),
        weightKg: 5.0,
      );
      final backfilled = WeightEntryFactory.build(
        id: 'older',
        date: DateTime.utc(2026, 1, 1),
        weightKg: 3.5,
      );
      when(() => datasource.create(any()))
          .thenAnswer((_) async => WeightEntryModel.fromEntity(backfilled));
      when(() => datasource.watchByPet(any(), any())).thenAnswer(
        (_) => Stream.value([
          WeightEntryModel.fromEntity(newer),
          WeightEntryModel.fromEntity(backfilled),
        ]),
      );

      await repository.create(backfilled);

      verifyNever(() => pets.setCurrentWeight(any(), any(), any()));
    });
  });

  group('delete', () {
    test('recomputes pet.currentWeightKg to the new latest', () async {
      final remaining = WeightEntryFactory.build(
        id: 'remaining',
        weightKg: 6.2,
      );
      when(() => datasource.delete(any(), any(), any()))
          .thenAnswer((_) async {});
      when(() => datasource.watchByPet(any(), any())).thenAnswer(
        (_) => Stream.value([WeightEntryModel.fromEntity(remaining)]),
      );

      final result = await repository.delete('h', 'p', 'w_1');

      expect(result.isRight(), isTrue);
      verify(() => pets.setCurrentWeight('h', 'p', 6.2)).called(1);
    });

    test('clears pet.currentWeightKg when the last entry is removed',
        () async {
      when(() => datasource.delete(any(), any(), any()))
          .thenAnswer((_) async {});
      when(() => datasource.watchByPet(any(), any()))
          .thenAnswer((_) => Stream.value(<WeightEntryModel>[]));

      final result = await repository.delete('h', 'p', 'w_1');

      expect(result.isRight(), isTrue);
      verify(() => pets.setCurrentWeight('h', 'p', null)).called(1);
    });
  });
}
