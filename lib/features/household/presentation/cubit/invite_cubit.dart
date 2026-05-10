import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/household/domain/entities/invite.dart';
import 'package:my_pet/features/household/domain/repositories/household_repository.dart';

part 'invite_state.dart';

/// Generates a fresh invite code for the current household. One-shot per
/// instance — re-tap "Generate" to produce a new code.
class InviteCubit extends Cubit<InviteState> {
  InviteCubit({required HouseholdRepository repository})
      : _repository = repository,
        super(const InviteIdle());

  final HouseholdRepository _repository;

  Future<void> generate({
    required String householdId,
    required String createdBy,
  }) async {
    emit(const InviteGenerating());
    final result = await _repository.generateInvite(
      householdId: householdId,
      createdBy: createdBy,
    );
    result.fold(
      (failure) => emit(InviteError(failure)),
      (invite) => emit(InviteGenerated(invite)),
    );
  }

  void reset() => emit(const InviteIdle());
}
