import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/pets/domain/entities/pet.dart';
import 'package:my_pet/features/pets/domain/repositories/pet_repository.dart';

part 'pets_list_state.dart';

/// Streams active pets for the current household. Subscribe via `start`
/// once the household id is known; cancel via `close`.
class PetsListCubit extends Cubit<PetsListState> {
  PetsListCubit({required PetRepository repository})
      : _repository = repository,
        super(const PetsListInitial());

  final PetRepository _repository;
  StreamSubscription<List<Pet>>? _subscription;

  void start(String householdId) {
    emit(const PetsListLoading());
    unawaited(_subscription?.cancel());
    _subscription = _repository.watchActive(householdId).listen(
      (pets) {
        if (pets.isEmpty) {
          emit(const PetsListEmpty());
          return;
        }
        emit(PetsListLoaded(pets));
      },
      onError: (Object error, StackTrace _) {
        emit(PetsListError(ServerFailure(message: error.toString())));
      },
    );
  }

  Future<Either<Failure, Unit>> archive(String householdId, String petId) {
    return _repository.archive(householdId, petId);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
