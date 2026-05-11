import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/features/weight/domain/entities/weight_entry.dart';
import 'package:my_pet/features/weight/presentation/cubit/weight_history_cubit.dart';
import 'package:my_pet/features/weight/presentation/cubit/weight_history_state.dart';

import '../../../../harness/factories/weight_entry_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockWeightRepository repository;

  setUp(() {
    repository = MockWeightRepository();
  });

  WeightHistoryCubit buildCubit() =>
      WeightHistoryCubit(repository: repository);

  group('WeightHistoryCubit', () {
    blocTest<WeightHistoryCubit, WeightHistoryState>(
      'emits Empty when the stream yields no entries',
      build: () {
        when(() => repository.watchByPet('h', 'p'))
            .thenAnswer((_) => Stream<List<WeightEntry>>.value(const []));
        return buildCubit();
      },
      act: (cubit) => cubit.start('h', 'p'),
      expect: () => [
        const WeightHistoryLoading(),
        const WeightHistoryEmpty(),
      ],
    );

    blocTest<WeightHistoryCubit, WeightHistoryState>(
      'emits Loaded with computed stats when entries arrive',
      build: () {
        final entries = [
          WeightEntryFactory.build(id: 'a', weightKg: 4),
          WeightEntryFactory.build(id: 'b'),
        ];
        when(() => repository.watchByPet('h', 'p'))
            .thenAnswer((_) => Stream<List<WeightEntry>>.value(entries));
        return buildCubit();
      },
      act: (cubit) => cubit.start('h', 'p'),
      verify: (cubit) {
        final state = cubit.state;
        expect(state, isA<WeightHistoryLoaded>());
        final loaded = state as WeightHistoryLoaded;
        expect(loaded.entries.length, equals(2));
        expect(loaded.stats.latest, isNotNull);
      },
    );

    blocTest<WeightHistoryCubit, WeightHistoryState>(
      'stream error surfaces WeightHistoryError',
      build: () {
        when(() => repository.watchByPet('h', 'p'))
            .thenAnswer((_) => Stream<List<WeightEntry>>.error(Exception()));
        return buildCubit();
      },
      act: (cubit) => cubit.start('h', 'p'),
      expect: () => [
        const WeightHistoryLoading(),
        isA<WeightHistoryError>(),
      ],
    );
  });
}
