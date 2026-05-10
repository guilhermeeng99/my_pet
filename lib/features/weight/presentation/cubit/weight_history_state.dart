import 'package:equatable/equatable.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/weight/domain/entities/weight_entry.dart';
import 'package:my_pet/features/weight/domain/entities/weight_stats.dart';

sealed class WeightHistoryState extends Equatable {
  const WeightHistoryState();
  @override
  List<Object?> get props => const [];
}

class WeightHistoryInitial extends WeightHistoryState {
  const WeightHistoryInitial();
}

class WeightHistoryLoading extends WeightHistoryState {
  const WeightHistoryLoading();
}

class WeightHistoryEmpty extends WeightHistoryState {
  const WeightHistoryEmpty();
}

class WeightHistoryLoaded extends WeightHistoryState {
  const WeightHistoryLoaded({
    required this.entries,
    required this.stats,
  });

  /// Sorted descending by date so the UI list reads newest-first.
  final List<WeightEntry> entries;
  final WeightStats stats;

  @override
  List<Object?> get props => [entries, stats];
}

class WeightHistoryError extends WeightHistoryState {
  const WeightHistoryError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
