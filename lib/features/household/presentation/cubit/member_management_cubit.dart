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

enum MemberManagementAction { remove, transfer, leave }

class MemberManagementCubit extends Cubit<MemberManagementState> {
  MemberManagementCubit({required HouseholdRepository repository})
      : _repository = repository,
        super(const MemberManagementIdle());

  final HouseholdRepository _repository;

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
      (_) => emit(
        const MemberManagementSuccess(MemberManagementAction.remove),
      ),
    );
  }

  Future<void> transfer({
    required String householdId,
    required AuthUser actor,
    required HouseholdMember newOwner,
  }) async {
    emit(const MemberManagementBusy());
    final result = await _repository.transferOwnership(
      householdId: householdId,
      actor: actor,
      newOwner: newOwner,
    );
    result.fold(
      (failure) => emit(
        MemberManagementError(MemberManagementAction.transfer, failure),
      ),
      (_) => emit(
        const MemberManagementSuccess(MemberManagementAction.transfer),
      ),
    );
  }

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
