import 'package:equatable/equatable.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/health/domain/entities/health_event.dart';
import 'package:my_pet/features/health/domain/entities/health_event_type.dart';

sealed class HealthTimelineState extends Equatable {
  const HealthTimelineState();
  @override
  List<Object?> get props => const [];
}

class HealthTimelineInitial extends HealthTimelineState {
  const HealthTimelineInitial();
}

class HealthTimelineLoading extends HealthTimelineState {
  const HealthTimelineLoading();
}

class HealthTimelineEmpty extends HealthTimelineState {
  const HealthTimelineEmpty({this.filter});
  final HealthEventType? filter;
  @override
  List<Object?> get props => [filter];
}

class HealthTimelineLoaded extends HealthTimelineState {
  const HealthTimelineLoaded({
    required this.events,
    required this.totalCost,
    this.filter,
  });

  /// Events ordered newest-first.
  final List<HealthEvent> events;
  final HealthEventType? filter;

  /// Sum of all `cost` values for the loaded events. Surfaced in the
  /// timeline header so the user has a quick read of spending in the
  /// current filter.
  final double totalCost;

  @override
  List<Object?> get props => [events, totalCost, filter];
}

class HealthTimelineError extends HealthTimelineState {
  const HealthTimelineError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
