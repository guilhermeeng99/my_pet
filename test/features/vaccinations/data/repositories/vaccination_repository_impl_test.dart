import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/vaccinations/data/models/vaccination_model.dart';
import 'package:my_pet/features/vaccinations/data/repositories/vaccination_repository_impl.dart';

import '../../../../harness/factories/vaccination_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockVaccinationFirestoreDatasource datasource;
  late VaccinationRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      VaccinationModel.fromEntity(VaccinationFactory.build()),
    );
  });

  setUp(() {
    datasource = MockVaccinationFirestoreDatasource();
    repository = VaccinationRepositoryImpl(datasource: datasource);
  });

  group('create', () {
    test('rejects empty name with ValidationFailure', () async {
      final v = VaccinationFactory.build(name: '   ');
      final result = await repository.create(v);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('rejects future appliedDate', () async {
      final future = DateTime.now().add(const Duration(days: 1)).toUtc();
      final v = VaccinationFactory.build(appliedDate: future);
      final result = await repository.create(v);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('rejects nextDueDate not after appliedDate', () async {
      final applied = DateTime.utc(2026, 4);
      final v = VaccinationFactory.build(
        appliedDate: applied,
        nextDueDate: applied,
      );
      final result = await repository.create(v);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('persists when valid', () async {
      final v = VaccinationFactory.build(
        appliedDate: DateTime.utc(2026, 4),
        nextDueDate: DateTime.utc(2027, 4),
      );
      when(() => datasource.create(any()))
          .thenAnswer((_) async => VaccinationModel.fromEntity(v));

      final result = await repository.create(v);

      expect(result.isRight(), isTrue);
      verify(() => datasource.create(any())).called(1);
    });
  });

  group('delete', () {
    test('forwards to datasource', () async {
      when(() => datasource.delete('h', 'p', 'v')).thenAnswer((_) async {});
      final result = await repository.delete('h', 'p', 'v');
      expect(result.isRight(), isTrue);
    });
  });
}
