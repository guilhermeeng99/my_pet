import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/household/domain/entities/household.dart';
import 'package:my_pet/features/household/domain/entities/household_member.dart';
import 'package:my_pet/features/household/domain/repositories/household_repository.dart';

part 'household_state.dart';

/// Watches `households/{householdId}` and resolves its `memberIds` into rich
/// [HouseholdMember]s on every change. Used by the Profile screen to drive
/// the partner card.
class HouseholdCubit extends Cubit<HouseholdState> {
  HouseholdCubit({required HouseholdRepository repository})
      : _repository = repository,
        super(const HouseholdInitial());

  final HouseholdRepository _repository;
  StreamSubscription<Household?>? _subscription;
  String? _currentHouseholdId;

  void start(String householdId) {
    if (_currentHouseholdId == householdId &&
        state is! HouseholdInitial &&
        state is! HouseholdError) {
      return;
    }
    _currentHouseholdId = householdId;
    emit(const HouseholdLoading());
    unawaited(_subscription?.cancel());
    _subscription = _repository.watch(householdId).listen(
      (household) async {
        if (household == null) {
          emit(const HouseholdNotFound());
          return;
        }
        final result = await _repository.fetchMembers(household);
        result.fold(
          (failure) => emit(HouseholdError(failure)),
          (members) => emit(HouseholdLoaded(household: household, members: members)),
        );
      },
      onError: (Object error, StackTrace _) {
        emit(HouseholdError(ServerFailure(message: error.toString())));
      },
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
