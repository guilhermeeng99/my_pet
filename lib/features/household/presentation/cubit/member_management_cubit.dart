import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/auth/domain/entities/auth_user.dart';
import 'package:my_pet/features/household/domain/repositories/household_repository.dart';

sealed class MemberManagementState extends Equatable {
  const MemberManagementState();
  @override
  List<Object?> get props => const [];
}

class MemberManagementIdle extends MemberManagementState {
  const MemberManagementIdle();
}

class MemberManagementBusy extends MemberManagementState {
  const MemberManagementBusy();
}

class MemberManagementSuccess extends MemberManagementState {
  const MemberManagementSuccess(this.action);
  final MemberManagementAction action;
  @override
  List<Object?> get props => [action];
}

class MemberManagementError extends MemberManagementState {
  const MemberManagementError(this.action, this.failure);
  final MemberManagementAction action;
  final Failure failure;
  @override
  List<Object?> get props => [action, failure];
}

/// Action surfaces left to the UI after the Manage-Family screen was
/// removed. The repository still exposes `removeMember` and
/// `transferOwnership` for internal flows (e.g. the owner-leave
/// auto-transfer happens inside the datasource batch), but the surface
/// the user can trigger from the Profile tab is just `leave`.
enum MemberManagementAction { leave }

class MemberManagementCubit extends Cubit<MemberManagementState> {
  MemberManagementCubit({required HouseholdRepository repository})
      : _repository = repository,
        super(const MemberManagementIdle());

  final HouseholdRepository _repository;

  Future<void> leave({
    required String householdId,
    required AuthUser actor,
  }) async {
    emit(const MemberManagementBusy());
    final result = await _repository.leaveHousehold(
      householdId: householdId,
      actor: actor,
    );
    result.fold(
      (failure) =>
          emit(MemberManagementError(MemberManagementAction.leave, failure)),
      (_) =>
          emit(const MemberManagementSuccess(MemberManagementAction.leave)),
    );
  }

  void reset() => emit(const MemberManagementIdle());
}
