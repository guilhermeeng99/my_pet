import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/features/reminders/domain/entities/reminder.dart';
import 'package:my_pet/features/reminders/presentation/cubit/reminders_list_cubit.dart';
import 'package:my_pet/features/reminders/presentation/cubit/reminders_list_state.dart';

import '../../../../harness/factories/reminder_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockReminderRepository repository;

  setUp(() {
    repository = MockReminderRepository();
  });

  RemindersListCubit buildCubit() =>
      RemindersListCubit(repository: repository);

  group('RemindersListCubit', () {
    blocTest<RemindersListCubit, RemindersListState>(
      'emits Empty when the household has no active reminders',
      build: () {
        when(() => repository.watchActive('h'))
            .thenAnswer((_) => Stream<List<Reminder>>.value(const []));
        return buildCubit();
      },
      act: (cubit) => cubit.start('h'),
      expect: () => [
        const RemindersListLoading(),
        const RemindersListEmpty(),
      ],
    );

    blocTest<RemindersListCubit, RemindersListState>(
      'groups reminders into overdue / today / week / later',
      build: () {
        final now = DateTime.now().toUtc();
        final reminders = [
          ReminderFactory.build(
            id: 'past',
            dueAt: now.subtract(const Duration(days: 2)),
          ),
          ReminderFactory.build(
            id: 'today',
            dueAt: now.add(const Duration(hours: 1)),
          ),
          ReminderFactory.build(
            id: 'week',
            dueAt: now.add(const Duration(days: 3)),
          ),
          ReminderFactory.build(
            id: 'later',
            dueAt: now.add(const Duration(days: 20)),
          ),
        ];
        when(() => repository.watchActive('h'))
            .thenAnswer((_) => Stream<List<Reminder>>.value(reminders));
        return buildCubit();
      },
      act: (cubit) => cubit.start('h'),
      verify: (cubit) {
        final state = cubit.state;
        expect(state, isA<RemindersListLoaded>());
        final loaded = state as RemindersListLoaded;
        expect(loaded.overdue.map((r) => r.id), ['past']);
        expect(loaded.later.map((r) => r.id), ['later']);
        // today vs. thisWeek boundary depends on time-of-day but `today`
        // entry is always one of the two; we just assert non-empty.
        expect(
          loaded.today.length + loaded.thisWeek.length,
          equals(2),
        );
      },
    );
  });
}
