import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pet/core/constants/app_constants.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/core/utils/date_time_utils.dart';
import 'package:my_pet/features/reminders/domain/entities/reminder.dart';
import 'package:my_pet/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:my_pet/features/reminders/presentation/cubit/reminders_list_state.dart';

/// Drives the Reminders tab. Watches the household-wide active stream and
/// groups results into overdue / today / this week / later so the UI can
/// render section headers cheaply. Cancels the subscription on close.
class RemindersListCubit extends Cubit<RemindersListState> {
  RemindersListCubit({required ReminderRepository repository})
      : _repository = repository,
        super(const RemindersListInitial());

  final ReminderRepository _repository;
  StreamSubscription<List<Reminder>>? _subscription;

  void start(String householdId) {
    emit(const RemindersListLoading());
    unawaited(_subscription?.cancel());
    _subscription = _repository.watchActive(householdId).listen(
      (reminders) {
        if (reminders.isEmpty) {
          emit(const RemindersListEmpty());
          return;
        }
        emit(_group(reminders));
      },
      onError: (Object error, StackTrace _) {
        emit(RemindersListError(ServerFailure(message: error.toString())));
      },
    );
  }

  Future<void> markDone(Reminder reminder) async {
    await _repository.markDone(reminder);
  }

  Future<void> delete(String householdId, String reminderId) async {
    await _repository.delete(householdId, reminderId);
  }

  RemindersListLoaded _group(List<Reminder> all) {
    final startOfToday = DateTimeUtils.startOfTodayUtc();
    final endOfToday = DateTimeUtils.addDays(startOfToday, 1);
    final endOfWeek = DateTimeUtils.addDays(
      startOfToday,
      AppConstants.upcomingWindowDays,
    );

    final overdue = <Reminder>[];
    final today = <Reminder>[];
    final thisWeek = <Reminder>[];
    final later = <Reminder>[];

    for (final r in all) {
      if (r.dueAt.isBefore(startOfToday)) {
        overdue.add(r);
      } else if (r.dueAt.isBefore(endOfToday)) {
        today.add(r);
      } else if (r.dueAt.isBefore(endOfWeek)) {
        thisWeek.add(r);
      } else {
        later.add(r);
      }
    }
    return RemindersListLoaded(
      overdue: overdue,
      today: today,
      thisWeek: thisWeek,
      later: later,
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
