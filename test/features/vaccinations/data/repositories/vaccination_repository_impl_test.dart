import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/vaccinations/data/models/vaccination_model.dart';
import 'package:my_pet/features/vaccinations/data/repositories/vaccination_repository_impl.dart';

import '../../../../harness/factories/vaccination_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockVaccinationFirestoreDatasource datasource;
  late MockNotificationService notifications;
  late VaccinationRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      VaccinationModel.fromEntity(VaccinationFactory.build()),
    );
  });

  setUp(() {
    datasource = MockVaccinationFirestoreDatasource();
    notifications = MockNotificationService();
    repository = VaccinationRepositoryImpl(
      datasource: datasource,
      notifications: notifications,
    );

    // Default: notification calls succeed silently.
    when(
      () => notifications.scheduleAll(
        groupKey: any(named: 'groupKey'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        firings: any(named: 'firings'),
      ),
    ).thenAnswer((_) async {});
    when(() => notifications.cancelGroup(any())).thenAnswer((_) async {});
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

    test('schedules two firings (D-7 and on-the-day) when nextDueDate set',
        () async {
      final due = DateTime.utc(2027, 4);
      final v = VaccinationFactory.build(
        appliedDate: DateTime.utc(2026, 4),
        nextDueDate: due,
      );
      when(() => datasource.create(any()))
          .thenAnswer((_) async => VaccinationModel.fromEntity(v));

      await repository.create(v);

      verify(
        () => notifications.scheduleAll(
          groupKey: 'vax:${v.id}',
          title: any(named: 'title'),
          body: any(named: 'body'),
          firings: [due.subtract(const Duration(days: 7)), due],
        ),
      ).called(1);
    });

    test('cancels reminders when nextDueDate is null', () async {
      final v = VaccinationFactory.build(
        appliedDate: DateTime.utc(2026, 4),
      );
      when(() => datasource.create(any()))
          .thenAnswer((_) async => VaccinationModel.fromEntity(v));

      await repository.create(v);

      verify(() => notifications.cancelGroup('vax:${v.id}')).called(1);
      verifyNever(
        () => notifications.scheduleAll(
          groupKey: any(named: 'groupKey'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          firings: any(named: 'firings'),
        ),
      );
    });
  });

  group('delete', () {
    test('forwards to datasource and cancels reminders', () async {
      when(() => datasource.delete('h', 'p', 'v')).thenAnswer((_) async {});
      final result = await repository.delete('h', 'p', 'v');
      expect(result.isRight(), isTrue);
      verify(() => notifications.cancelGroup('vax:v')).called(1);
    });
  });
}
