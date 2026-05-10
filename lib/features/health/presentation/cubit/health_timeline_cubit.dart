import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/health/domain/entities/health_event.dart';
import 'package:my_pet/features/health/domain/entities/health_event_type.dart';
import 'package:my_pet/features/health/domain/repositories/health_repository.dart';
import 'package:my_pet/features/health/presentation/cubit/health_timeline_state.dart';

/// Drives the per-pet Health timeline. Re-subscribes when the user toggles
/// the type filter so we don't filter client-side (Firestore indexes on
/// `(petId, type, date)` carry the cost).
class HealthTimelineCubit extends Cubit<HealthTimelineState> {
  HealthTimelineCubit({required HealthRepository repository})
      : _repository = repository,
        super(const HealthTimelineInitial());

  final HealthRepository _repository;
  StreamSubscription<List<HealthEvent>>? _subscription;
  String? _householdId;
  String? _petId;
  HealthEventType? _filter;

  void start(String householdId, String petId) {
    _householdId = householdId;
    _petId = petId;
    _subscribe();
  }

  void setFilter(HealthEventType? filter) {
    if (_filter == filter) return;
    _filter = filter;
    _subscribe();
  }

  void _subscribe() {
    final hid = _householdId;
    final petId = _petId;
    if (hid == null || petId == null) return;
    emit(const HealthTimelineLoading());
    unawaited(_subscription?.cancel());
    final stream = _filter == null
        ? _repository.watchByPet(hid, petId)
        : _repository.watchByPetAndType(hid, petId, _filter!);
    _subscription = stream.listen(
      (events) {
        if (events.isEmpty) {
          emit(HealthTimelineEmpty(filter: _filter));
          return;
        }
        final total = events.fold<double>(
          0,
          (sum, e) => sum + (e.cost ?? 0),
        );
        emit(HealthTimelineLoaded(
          events: events,
          totalCost: total,
          filter: _filter,
        ));
      },
      onError: (Object error, StackTrace _) {
        emit(HealthTimelineError(ServerFailure(message: error.toString())));
      },
    );
  }

  Future<void> delete(String eventId) async {
    final hid = _householdId;
    final petId = _petId;
    if (hid == null || petId == null) return;
    await _repository.delete(hid, petId, eventId);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
