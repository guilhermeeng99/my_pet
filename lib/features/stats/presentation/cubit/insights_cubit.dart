import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_pet/features/pets/domain/entities/pet.dart';
import 'package:my_pet/features/pets/domain/entities/species.dart';
import 'package:my_pet/features/pets/domain/repositories/pet_repository.dart';
import 'package:my_pet/features/reminders/domain/entities/reminder.dart';
import 'package:my_pet/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:my_pet/features/stats/presentation/cubit/insights_state.dart';

/// Aggregates pet + reminder streams into the dashboard snapshot. Keeps a
/// snapshot of each upstream so any tick from either repo refreshes the
/// combined view without re-subscribing both.
class InsightsCubit extends Cubit<InsightsState> {
  InsightsCubit({
    required PetRepository pets,
    required ReminderRepository reminders,
  })  : _pets = pets,
        _reminders = reminders,
        super(const InsightsInitial());

  final PetRepository _pets;
  final ReminderRepository _reminders;
  StreamSubscription<List<Pet>>? _petsSub;
  StreamSubscription<List<Reminder>>? _remindersSub;
  List<Pet> _latestPets = const [];
  List<Reminder> _latestReminders = const [];
  bool _seenPets = false;
  bool _seenReminders = false;

  void start(String householdId) {
    emit(const InsightsLoading());
    unawaited(_petsSub?.cancel());
    unawaited(_remindersSub?.cancel());
    _petsSub = _pets.watchActive(householdId).listen(
      (pets) {
        _latestPets = pets;
        _seenPets = true;
        _emitSnapshot();
      },
      // Treat upstream errors as "no data yet" so the dashboard renders
      // an empty snapshot instead of leaving the page stuck on Loading
      // (e.g. a Firestore missing-index error on first run).
      onError: _onUpstreamError,
    );
    _remindersSub = _reminders.watchActive(householdId).listen(
      (reminders) {
        _latestReminders = reminders;
        _seenReminders = true;
        _emitSnapshot();
      },
      onError: _onUpstreamError,
    );
  }

  void _onUpstreamError(Object _, StackTrace _) {
    _seenPets = true;
    _seenReminders = true;
    _emitSnapshot();
  }

  void _emitSnapshot() {
    if (!_seenPets || !_seenReminders) return;
    final now = DateTime.now().toUtc();
    final weekFromNow = now.add(const Duration(days: 7));
    final bySpecies = <Species, int>{};
    for (final p in _latestPets) {
      bySpecies[p.species] = (bySpecies[p.species] ?? 0) + 1;
    }
    var overdue = 0;
    var dueThisWeek = 0;
    for (final r in _latestReminders) {
      if (r.dueAt.isBefore(now)) {
        overdue++;
      } else if (r.dueAt.isBefore(weekFromNow)) {
        dueThisWeek++;
      }
    }
    emit(InsightsLoaded(
      InsightsSnapshot(
        totalPets: _latestPets.length,
        bySpecies: bySpecies,
        activeReminders: _latestReminders.length,
        overdueReminders: overdue,
        dueThisWeek: dueThisWeek,
      ),
    ));
  }

  @override
  Future<void> close() async {
    await _petsSub?.cancel();
    await _remindersSub?.cancel();
    return super.close();
  }
}
