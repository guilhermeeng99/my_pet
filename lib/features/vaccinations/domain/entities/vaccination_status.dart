/// Derived from `nextDueDate` per [`specs/vaccinations.md`](../../../../../specs/vaccinations.md).
enum VaccinationStatus { upToDate, dueSoon, overdue, noNextDose }

class VaccinationStatusCalculator {
  const VaccinationStatusCalculator({this.dueSoonWindowDays = 30});

  final int dueSoonWindowDays;

  VaccinationStatus from(DateTime? nextDueDate, {DateTime? now}) {
    if (nextDueDate == null) return VaccinationStatus.noNextDose;
    final today = (now ?? DateTime.now()).toUtc();
    if (nextDueDate.isBefore(today)) return VaccinationStatus.overdue;
    final window = today.add(Duration(days: dueSoonWindowDays));
    if (!nextDueDate.isAfter(window)) return VaccinationStatus.dueSoon;
    return VaccinationStatus.upToDate;
  }
}
