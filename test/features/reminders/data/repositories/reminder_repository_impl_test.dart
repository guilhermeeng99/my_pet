import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/reminders/data/models/reminder_model.dart';
import 'package:my_pet/features/reminders/data/repositories/reminder_repository_impl.dart';
import 'package:my_pet/features/reminders/domain/entities/recurrence.dart';

import '../../../../harness/factories/reminder_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockReminderFirestoreDatasource datasource;
  late MockNotificationService notifications;
  late ReminderRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(ReminderFactory.buildModel());
    registerFallbackValue(<DateTime>[]);
  });

  setUp(() {
    datasource = MockReminderFirestoreDatasource();
    notifications = MockNotificationService();
    repository = ReminderRepositoryImpl(
      datasource: datasource,
      notifications: notifications,
    );

    when(() => notifications.scheduleAll(
          groupKey: any(named: 'groupKey'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          firings: any(named: 'firings'),
        )).thenAnswer((_) async {});
    when(() => notifications.cancelGroup(any())).thenAnswer((_) async {});
  });

  group('create', () {
    test('rejects empty title', () async {
      final reminder = ReminderFactory.build(title: '   ');
      final result = await repository.create(reminder);
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('expected Left'),
      );
      verifyNever(() => datasource.create(any()));
    });

    test('rejects custom recurrence without interval', () async {
      final reminder = ReminderFactory.build(
        recurrence: Recurrence.custom,
      );
      final result = await repository.create(reminder);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('persists and schedules notifications when valid', () async {
      final reminder = ReminderFactory.build(
        notifyBeforeMinutes: const [10080, 0],
      );
      when(() => datasource.create(any()))
          .thenAnswer((_) async => ReminderModel.fromEntity(reminder));

      final result = await repository.create(reminder);

      expect(result.isRight(), isTrue);
      verify(() => datasource.create(any())).called(1);
      verify(() => notifications.scheduleAll(
            groupKey: 'rem:rem_1',
            title: reminder.title,
            body: any(named: 'body'),
            firings: any(named: 'firings'),
          )).called(1);
    });
  });

  group('markDone', () {
    test('one-shot completes without scheduling a new instance', () async {
      final reminder = ReminderFactory.build();
      when(() => datasource.update(any()))
          .thenAnswer((_) async => ReminderModel.fromEntity(reminder));

      final result = await repository.markDone(reminder);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (saved) => expect(saved.done, isTrue),
      );
      verify(() => datasource.update(any())).called(1);
      verify(() => notifications.cancelGroup('rem:rem_1')).called(1);
      verifyNever(() => datasource.create(any()));
    });

    test('recurring rolls a fresh instance forward', () async {
      final reminder = ReminderFactory.build(
        recurrence: Recurrence.daily,
        dueAt: DateTime.now().toUtc().add(const Duration(days: 1)),
      );
      when(() => datasource.update(any()))
          .thenAnswer((_) async => ReminderModel.fromEntity(reminder));
      when(() => datasource.create(any()))
          .thenAnswer((invocation) async =>
              invocation.positionalArguments.first as ReminderModel);

      final result = await repository.markDone(reminder);

      expect(result.isRight(), isTrue);
      verify(() => datasource.update(any())).called(1); // complete current
      verify(() => datasource.create(any())).called(1); // create next
      result.fold(
        (_) => fail('expected Right'),
        (next) => expect(next.done, isFalse),
      );
    });
  });

  test('delete forwards to datasource and cancels notifications', () async {
    when(() => datasource.delete(any(), any())).thenAnswer((_) async {});

    final result = await repository.delete('h', 'rem_1');

    expect(result, equals(const Right<Failure, Unit>(unit)));
    verify(() => datasource.delete('h', 'rem_1')).called(1);
    verify(() => notifications.cancelGroup('rem:rem_1')).called(1);
  });
}
