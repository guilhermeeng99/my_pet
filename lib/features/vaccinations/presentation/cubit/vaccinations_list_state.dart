part of 'vaccinations_list_cubit.dart';

sealed class VaccinationsListState extends Equatable {
  const VaccinationsListState();
  @override
  List<Object?> get props => [];
}

class VaccinationsListInitial extends VaccinationsListState {
  const VaccinationsListInitial();
}

class VaccinationsListLoading extends VaccinationsListState {
  const VaccinationsListLoading();
}

class VaccinationsListLoaded extends VaccinationsListState {
  const VaccinationsListLoaded({required this.grouped});

  /// Pre-grouped per status so the UI just renders sections. Order:
  /// overdue → dueSoon → upToDate → noNextDose.
  final Map<VaccinationStatus, List<Vaccination>> grouped;

  bool get isEmpty => grouped.values.every((l) => l.isEmpty);

  @override
  List<Object?> get props => [grouped];
}

class VaccinationsListError extends VaccinationsListState {
  const VaccinationsListError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
