import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/weight/domain/entities/weight_entry.dart';
import 'package:my_pet/features/weight/domain/entities/weight_stats.dart';
import 'package:my_pet/features/weight/domain/repositories/weight_repository.dart';
import 'package:my_pet/features/weight/presentation/cubit/weight_history_state.dart';

class WeightHistoryCubit extends Cubit<WeightHistoryState> {
  WeightHistoryCubit({
    required WeightRepository repository,
    WeightStatsCalculator calculator = const WeightStatsCalculator(),
  })  : _repository = repository,
        _calculator = calculator,
        super(const WeightHistoryInitial());

  final WeightRepository _repository;
  final WeightStatsCalculator _calculator;
  StreamSubscription<List<WeightEntry>>? _subscription;

  void start(String householdId, String petId) {
    emit(const WeightHistoryLoading());
    unawaited(_subscription?.cancel());
    _subscription =
        _repository.watchByPet(householdId, petId).listen(
      (entries) {
        if (entries.isEmpty) {
          emit(const WeightHistoryEmpty());
          return;
        }
        emit(
          WeightHistoryLoaded(
            entries: entries,
            stats: _calculator.from(entries),
          ),
        );
      },
      onError: (Object error, StackTrace _) {
        emit(WeightHistoryError(ServerFailure(message: error.toString())));
      },
    );
  }

  Future<void> delete(
    String householdId,
    String petId,
    String entryId,
  ) async {
    await _repository.delete(householdId, petId, entryId);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
