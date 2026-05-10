import 'package:equatable/equatable.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/reminders/domain/entities/reminder.dart';

sealed class RemindersListState extends Equatable {
  const RemindersListState();
  @override
  List<Object?> get props => const [];
}

class RemindersListInitial extends RemindersListState {
  const RemindersListInitial();
}

class RemindersListLoading extends RemindersListState {
  const RemindersListLoading();
}

class RemindersListEmpty extends RemindersListState {
  const RemindersListEmpty();
}

/// Loaded list grouped by relevance buckets so the UI can render section
/// headers without re-computing on every rebuild.
class RemindersListLoaded extends RemindersListState {
  const RemindersListLoaded({
    required this.overdue,
    required this.today,
    required this.thisWeek,
    required this.later,
  });

  final List<Reminder> overdue;
  final List<Reminder> today;
  final List<Reminder> thisWeek;
  final List<Reminder> later;

  int get total =>
      overdue.length + today.length + thisWeek.length + later.length;

  @override
  List<Object?> get props => [overdue, today, thisWeek, later];
}

class RemindersListError extends RemindersListState {
  const RemindersListError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
