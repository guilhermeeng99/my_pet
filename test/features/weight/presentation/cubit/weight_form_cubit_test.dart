import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/weight/domain/entities/weight_entry.dart';
import 'package:my_pet/features/weight/presentation/cubit/weight_form_cubit.dart';
import 'package:my_pet/features/weight/presentation/cubit/weight_form_state.dart';

import '../../../../harness/factories/weight_entry_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockWeightRepository repository;

  setUpAll(() {
    registerFallbackValue(WeightEntryFactory.build());
  });

  setUp(() {
    repository = MockWeightRepository();
  });

  WeightFormCubit buildCubit() => WeightFormCubit(repository: repository);

  group('WeightFormCubit', () {
    blocTest<WeightFormCubit, WeightFormState>(
      'create: Submitting -> Success carries saved entry',
      build: () {
        final saved = WeightEntryFactory.build();
        when(() => repository.create(any()))
            .thenAnswer((_) async => Right<Failure, WeightEntry>(saved));
        return buildCubit();
      },
      act: (cubit) => cubit.create(WeightEntryFactory.build()),
      expect: () => [
        const WeightFormSubmitting(),
        WeightFormSuccess(WeightEntryFactory.build()),
      ],
    );

    blocTest<WeightFormCubit, WeightFormState>(
      'update failure surfaces WeightFormError',
      build: () {
        when(() => repository.update(any())).thenAnswer(
          (_) async => const Left(ValidationFailure(message: 'too heavy')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.update(WeightEntryFactory.build()),
      expect: () => [
        const WeightFormSubmitting(),
        const WeightFormError(ValidationFailure(message: 'too heavy')),
      ],
    );
  });
}
