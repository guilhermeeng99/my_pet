import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/health/data/models/health_event_model.dart';
import 'package:my_pet/features/health/data/repositories/health_repository_impl.dart';
import 'package:my_pet/features/health/domain/entities/health_event_type.dart';
import 'package:my_pet/features/health/domain/entities/medication_details.dart';

import '../../../../harness/factories/health_event_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockHealthFirestoreDatasource datasource;
  late HealthRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(HealthEventFactory.buildModel());
  });

  setUp(() {
    datasource = MockHealthFirestoreDatasource();
    repository = HealthRepositoryImpl(datasource: datasource);
  });

  group('create', () {
    test('rejects empty title', () async {
      final result = await repository.create(
        HealthEventFactory.build(title: '   '),
      );
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('expected Left'),
      );
      verifyNever(() => datasource.create(any()));
    });

    test('rejects future-dated events', () async {
      final result = await repository.create(
        HealthEventFactory.build(
          date: DateTime.now().toUtc().add(const Duration(days: 1)),
        ),
      );
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('rejects endDate before date', () async {
      final result = await repository.create(
        HealthEventFactory.build(
          date: DateTime.utc(2026, 5, 10),
          endDate: DateTime.utc(2026, 5),
        ),
      );
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('rejects medication event without medication details', () async {
      final result = await repository.create(
        HealthEventFactory.build(type: HealthEventType.medication),
      );
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('rejects negative cost', () async {
      final result = await repository.create(
        HealthEventFactory.build(cost: -10),
      );
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('persists a valid medication event with full details', () async {
      final event = HealthEventFactory.build(
        type: HealthEventType.medication,
        medication: const MedicationDetails(
          name: 'Apoquel',
          dosage: '10 mg',
          frequency: 'every 12h',
          durationDays: 7,
        ),
      );
      when(() => datasource.create(any()))
          .thenAnswer((_) async => HealthEventModel.fromEntity(event));

      final result = await repository.create(event);

      expect(result.isRight(), isTrue);
      verify(() => datasource.create(any())).called(1);
    });
  });
}
