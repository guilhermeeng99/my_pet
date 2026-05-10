import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/household/domain/entities/household.dart';
import 'package:my_pet/features/household/domain/repositories/household_repository.dart';

part 'join_household_state.dart';

/// Drives the "Enter invite code" page: validates the code, performs the
/// atomic accept, and emits [JoinHouseholdJoined] once the user is in the
/// new household. The auth bloc reacts to the `users/{uid}.householdId`
/// change and the rest of the app re-routes naturally.
class JoinHouseholdCubit extends Cubit<JoinHouseholdState> {
  JoinHouseholdCubit({required HouseholdRepository repository})
      : _repository = repository,
        super(const JoinHouseholdIdle());

  final HouseholdRepository _repository;

  Future<void> submit({required String code, required String userId}) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.length != 6) {
      emit(const JoinHouseholdInvalidLength());
      return;
    }
    emit(const JoinHouseholdSubmitting());
    final result = await _repository.acceptInvite(
      code: normalized,
      userId: userId,
    );
    result.fold(
      (failure) => emit(JoinHouseholdError(failure)),
      (household) => emit(JoinHouseholdJoined(household)),
    );
  }

  void reset() => emit(const JoinHouseholdIdle());
}
