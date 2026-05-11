import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/features/health/domain/entities/health_event.dart';
import 'package:my_pet/features/health/domain/entities/health_event_type.dart';
import 'package:my_pet/features/health/presentation/cubit/health_timeline_cubit.dart';
import 'package:my_pet/features/health/presentation/cubit/health_timeline_state.dart';

import '../../../../harness/factories/health_event_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockHealthRepository repository;

  setUp(() {
    repository = MockHealthRepository();
  });

  HealthTimelineCubit buildCubit() =>
      HealthTimelineCubit(repository: repository);

  group('HealthTimelineCubit', () {
    blocTest<HealthTimelineCubit, HealthTimelineState>(
      'emits Empty when stream yields no events',
      build: () {
        when(() => repository.watchByPet('h', 'p'))
            .thenAnswer((_) => Stream<List<HealthEvent>>.value(const []));
        return buildCubit();
      },
      act: (cubit) => cubit.start('h', 'p'),
      expect: () => [
        const HealthTimelineLoading(),
        const HealthTimelineEmpty(),
      ],
    );

    blocTest<HealthTimelineCubit, HealthTimelineState>(
      'computes totalCost as the sum of event costs',
      build: () {
        final events = [
          HealthEventFactory.build(id: 'a', cost: 50),
          HealthEventFactory.build(id: 'b', cost: 12.5),
          HealthEventFactory.build(id: 'c'),
        ];
        when(() => repository.watchByPet('h', 'p'))
            .thenAnswer((_) => Stream<List<HealthEvent>>.value(events));
        return buildCubit();
      },
      act: (cubit) => cubit.start('h', 'p'),
      verify: (cubit) {
        final state = cubit.state;
        expect(state, isA<HealthTimelineLoaded>());
        expect((state as HealthTimelineLoaded).totalCost, equals(62.5));
      },
    );

    blocTest<HealthTimelineCubit, HealthTimelineState>(
      'setFilter switches to watchByPetAndType and re-subscribes',
      build: () {
        when(() => repository.watchByPet('h', 'p'))
            .thenAnswer((_) => Stream<List<HealthEvent>>.value(const []));
        when(
          () => repository.watchByPetAndType(
            'h',
            'p',
            HealthEventType.medication,
          ),
        ).thenAnswer((_) => Stream<List<HealthEvent>>.value(const []));
        return buildCubit();
      },
      act: (cubit) async {
        cubit
          ..start('h', 'p')
          ..setFilter(HealthEventType.medication);
      },
      verify: (_) {
        verify(() => repository.watchByPet('h', 'p')).called(1);
        verify(
          () => repository.watchByPetAndType(
            'h',
            'p',
            HealthEventType.medication,
          ),
        ).called(1);
      },
    );
  });
}
