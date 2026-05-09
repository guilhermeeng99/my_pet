import 'package:flutter_test/flutter_test.dart';

import 'package:my_pet/features/vaccinations/domain/entities/vaccination_status.dart';

void main() {
  const calculator = VaccinationStatusCalculator();
  final now = DateTime.utc(2026, 5, 9);

  group('VaccinationStatusCalculator', () {
    test('null nextDueDate -> noNextDose', () {
      expect(
        calculator.from(null, now: now),
        VaccinationStatus.noNextDose,
      );
    });

    test('past nextDueDate -> overdue', () {
      expect(
        calculator.from(DateTime.utc(2026, 4), now: now),
        VaccinationStatus.overdue,
      );
    });

    test('within 30d -> dueSoon', () {
      expect(
        calculator.from(DateTime.utc(2026, 5, 20), now: now),
        VaccinationStatus.dueSoon,
      );
    });

    test('exactly 30d ahead -> dueSoon (boundary inclusive)', () {
      expect(
        calculator.from(DateTime.utc(2026, 6, 8), now: now),
        VaccinationStatus.dueSoon,
      );
    });

    test('beyond 30d -> upToDate', () {
      expect(
        calculator.from(DateTime.utc(2026, 8), now: now),
        VaccinationStatus.upToDate,
      );
    });
  });
}
