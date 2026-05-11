import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/features/pets/domain/entities/pet.dart';
import 'package:my_pet/features/pets/domain/entities/species.dart';
import 'package:my_pet/features/reminders/domain/entities/reminder.dart';
import 'package:my_pet/features/stats/presentation/cubit/insights_cubit.dart';
import 'package:my_pet/features/stats/presentation/cubit/insights_state.dart';

import '../../../../harness/factories/pet_factory.dart';
import '../../../../harness/factories/reminder_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockPetRepository pets;
  late MockReminderRepository reminders;

  setUp(() {
    pets = MockPetRepository();
    reminders = MockReminderRepository();
  });

  InsightsCubit buildCubit() => InsightsCubit(pets: pets, reminders: reminders);

  group('InsightsCubit', () {
    blocTest<InsightsCubit, InsightsState>(
      'aggregates pets and reminders into a snapshot',
      build: () {
        final petList = [
          PetFactory.build(id: 'a'),
          PetFactory.build(id: 'b', species: Species.dog),
        ];
        final now = DateTime.now().toUtc();
        final reminderList = [
          ReminderFactory.build(
            id: 'late',
            dueAt: now.subtract(const Duration(days: 1)),
          ),
          ReminderFactory.build(
            id: 'soon',
            dueAt: now.add(const Duration(days: 2)),
          ),
          ReminderFactory.build(
            id: 'later',
            dueAt: now.add(const Duration(days: 30)),
          ),
        ];
        when(() => pets.watchActive('h'))
            .thenAnswer((_) => Stream<List<Pet>>.value(petList));
        when(() => reminders.watchActive('h'))
            .thenAnswer((_) => Stream<List<Reminder>>.value(reminderList));
        return buildCubit();
      },
      act: (cubit) => cubit.start('h'),
      verify: (cubit) {
        final state = cubit.state;
        expect(state, isA<InsightsLoaded>());
        final snap = (state as InsightsLoaded).snapshot;
        expect(snap.totalPets, equals(2));
        expect(snap.bySpecies[Species.cat], equals(1));
        expect(snap.bySpecies[Species.dog], equals(1));
        expect(snap.activeReminders, equals(3));
        expect(snap.overdueReminders, equals(1));
        expect(snap.dueThisWeek, equals(1));
      },
    );

    blocTest<InsightsCubit, InsightsState>(
      'upstream error renders an empty snapshot instead of staying in Loading',
      build: () {
        when(() => pets.watchActive('h'))
            .thenAnswer((_) => Stream<List<Pet>>.error(Exception()));
        when(() => reminders.watchActive('h'))
            .thenAnswer((_) => Stream<List<Reminder>>.error(Exception()));
        return buildCubit();
      },
      act: (cubit) => cubit.start('h'),
      verify: (cubit) {
        // After both upstreams emit (or error), an InsightsLoaded should
        // appear with zeros so the dashboard doesn't get stuck.
        expect(cubit.state, isA<InsightsLoaded>());
      },
    );
  });
}
