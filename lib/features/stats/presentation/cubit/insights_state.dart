import 'package:equatable/equatable.dart';
import 'package:my_pet/features/pets/domain/entities/species.dart';

class InsightsSnapshot extends Equatable {
  const InsightsSnapshot({
    required this.totalPets,
    required this.bySpecies,
    required this.activeReminders,
    required this.overdueReminders,
    required this.dueThisWeek,
  });

  final int totalPets;
  final Map<Species, int> bySpecies;
  final int activeReminders;
  final int overdueReminders;
  final int dueThisWeek;

  @override
  List<Object?> get props => [
        totalPets,
        bySpecies,
        activeReminders,
        overdueReminders,
        dueThisWeek,
      ];
}

sealed class InsightsState extends Equatable {
  const InsightsState();
  @override
  List<Object?> get props => const [];
}

class InsightsInitial extends InsightsState {
  const InsightsInitial();
}

class InsightsLoading extends InsightsState {
  const InsightsLoading();
}

class InsightsLoaded extends InsightsState {
  const InsightsLoaded(this.snapshot);
  final InsightsSnapshot snapshot;
  @override
  List<Object?> get props => [snapshot];
}
