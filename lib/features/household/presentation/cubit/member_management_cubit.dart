import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/auth/domain/entities/auth_user.dart';
import 'package:my_pet/features/household/domain/entities/household_member.dart';
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

/// Action surfaces the Profile tab triggers. `leave` is shown to the
/// non-owner partner; `remove` is the owner-side equivalent (kicks the
/// partner out of the household instead of leaving). `transferOwnership`
/// stays inside the datasource batch on owner-leave and never reaches
/// the UI directly.
enum MemberManagementAction { leave, remove }

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

  /// Owner kicks a partner out of the household. The household data
  /// stays with the owner; the partner's `users/{uid}.householdId` is
  /// cleared so they land on the setup flow on next sign-in.
  Future<void> remove({
    required String householdId,
    required AuthUser actor,
    required HouseholdMember target,
  }) async {
    emit(const MemberManagementBusy());
    final result = await _repository.removeMember(
      householdId: householdId,
      actor: actor,
      target: target,
    );
    result.fold(
      (failure) =>
          emit(MemberManagementError(MemberManagementAction.remove, failure)),
      (_) =>
          emit(const MemberManagementSuccess(MemberManagementAction.remove)),
    );
  }

  void reset() => emit(const MemberManagementIdle());
}
