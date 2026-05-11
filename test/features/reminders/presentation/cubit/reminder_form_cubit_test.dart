import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/reminders/domain/entities/reminder.dart';
import 'package:my_pet/features/reminders/presentation/cubit/reminder_form_cubit.dart';
import 'package:my_pet/features/reminders/presentation/cubit/reminder_form_state.dart';

import '../../../../harness/factories/reminder_factory.dart';
import '../../../../harness/mocks.dart';

void main() {
  late MockReminderRepository repository;

  setUpAll(() {
    registerFallbackValue(ReminderFactory.build());
  });

  setUp(() {
    repository = MockReminderRepository();
  });

  ReminderFormCubit buildCubit() => ReminderFormCubit(repository: repository);

  group('ReminderFormCubit', () {
    blocTest<ReminderFormCubit, ReminderFormState>(
      'create: Submitting -> Success carries the saved entity',
      build: () {
        final saved = ReminderFactory.build();
        when(() => repository.create(any()))
            .thenAnswer((_) async => Right<Failure, Reminder>(saved));
        return buildCubit();
      },
      act: (cubit) => cubit.create(ReminderFactory.build()),
      expect: () => [
        const ReminderFormSubmitting(),
        ReminderFormSuccess(ReminderFactory.build()),
      ],
    );

    blocTest<ReminderFormCubit, ReminderFormState>(
      'update failure surfaces ReminderFormError',
      build: () {
        when(() => repository.update(any())).thenAnswer(
          (_) async => const Left(ValidationFailure(message: 'bad')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.update(ReminderFactory.build()),
      expect: () => [
        const ReminderFormSubmitting(),
        const ReminderFormError(ValidationFailure(message: 'bad')),
      ],
    );
  });
}
