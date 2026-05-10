import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pet/features/reminders/domain/entities/reminder.dart';
import 'package:my_pet/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:my_pet/features/reminders/presentation/cubit/reminder_form_state.dart';

class ReminderFormCubit extends Cubit<ReminderFormState> {
  ReminderFormCubit({required ReminderRepository repository})
      : _repository = repository,
        super(const ReminderFormIdle());

  final ReminderRepository _repository;

  Future<void> create(Reminder draft) async {
    emit(const ReminderFormSubmitting());
    final result = await _repository.create(draft);
    result.fold(
      (failure) => emit(ReminderFormError(failure)),
      (saved) => emit(ReminderFormSuccess(saved)),
    );
  }

  Future<void> update(Reminder reminder) async {
    emit(const ReminderFormSubmitting());
    final result = await _repository.update(reminder);
    result.fold(
      (failure) => emit(ReminderFormError(failure)),
      (saved) => emit(ReminderFormSuccess(saved)),
    );
  }
}
