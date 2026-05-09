import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:my_pet/core/errors/failures.dart';
import 'package:my_pet/features/vaccinations/domain/entities/vaccination.dart';
import 'package:my_pet/features/vaccinations/domain/entities/vaccination_status.dart';
import 'package:my_pet/features/vaccinations/domain/repositories/vaccination_repository.dart';

part 'vaccinations_list_state.dart';

class VaccinationsListCubit extends Cubit<VaccinationsListState> {
  VaccinationsListCubit({
    required VaccinationRepository repository,
    VaccinationStatusCalculator calculator =
        const VaccinationStatusCalculator(),
  })  : _repository = repository,
        _calculator = calculator,
        super(const VaccinationsListInitial());

  final VaccinationRepository _repository;
  final VaccinationStatusCalculator _calculator;
  StreamSubscription<List<Vaccination>>? _subscription;

  void start(String householdId, String petId) {
    emit(const VaccinationsListLoading());
    unawaited(_subscription?.cancel());
    _subscription = _repository.watchByPet(householdId, petId).listen(
      (vaccinations) {
        emit(VaccinationsListLoaded(grouped: _group(vaccinations)));
      },
      onError: (Object error, StackTrace _) {
        emit(VaccinationsListError(ServerFailure(message: error.toString())));
      },
    );
  }

  Map<VaccinationStatus, List<Vaccination>> _group(List<Vaccination> all) {
    final grouped = <VaccinationStatus, List<Vaccination>>{
      VaccinationStatus.overdue: <Vaccination>[],
      VaccinationStatus.dueSoon: <Vaccination>[],
      VaccinationStatus.upToDate: <Vaccination>[],
      VaccinationStatus.noNextDose: <Vaccination>[],
    };
    for (final v in all) {
      final status = _calculator.from(v.nextDueDate);
      grouped[status]!.add(v);
    }
    return grouped;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
