import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/health/domain/entities/health_event.dart';
import 'package:my_pet/features/health/presentation/cubit/health_form_cubit.dart';
import 'package:my_pet/features/health/presentation/cubit/health_form_state.dart';

import '../../../../harness/factories/health_event_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockHealthRepository repository;

  setUpAll(() {
    registerFallbackValue(HealthEventFactory.build());
  });

  setUp(() {
    repository = MockHealthRepository();
  });

  HealthFormCubit buildCubit() => HealthFormCubit(repository: repository);

  group('HealthFormCubit', () {
    blocTest<HealthFormCubit, HealthFormState>(
      'create: Submitting -> Success carries saved event',
      build: () {
        final saved = HealthEventFactory.build();
        when(() => repository.create(any()))
            .thenAnswer((_) async => Right<Failure, HealthEvent>(saved));
        return buildCubit();
      },
      act: (cubit) => cubit.create(HealthEventFactory.build()),
      expect: () => [
        const HealthFormSubmitting(),
        HealthFormSuccess(HealthEventFactory.build()),
      ],
    );

    blocTest<HealthFormCubit, HealthFormState>(
      'update failure surfaces HealthFormError',
      build: () {
        when(() => repository.update(any())).thenAnswer(
          (_) async => const Left(ValidationFailure(message: 'bad')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.update(HealthEventFactory.build()),
      expect: () => [
        const HealthFormSubmitting(),
        const HealthFormError(ValidationFailure(message: 'bad')),
      ],
    );
  });
}
