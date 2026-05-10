import 'package:flutter_test/flutter_test.dart';
import 'package:my_pet/features/weight/domain/entities/weight_stats.dart';

import '../../../../harness/factories/weight_entry_factory.dart';

void main() {
  const calculator = WeightStatsCalculator();

  group('WeightStatsCalculator', () {
    test('returns an empty stats object when there are no entries', () {
      final stats = calculator.from(const []);
      expect(stats.latest, isNull);
      expect(stats.change30dPercent, isNull);
      expect(stats.hasWarning, isFalse);
    });

    test('reports latest, min/max/avg, and 30-day change', () {
      final base = DateTime.utc(2026, 5, 10);
      final entries = [
        WeightEntryFactory.build(
          id: 'a',
          date: base.subtract(const Duration(days: 60)),
          weightKg: 4,
        ),
        WeightEntryFactory.build(
          id: 'b',
          date: base.subtract(const Duration(days: 30)),
          weightKg: 5,
        ),
        WeightEntryFactory.build(id: 'c', date: base, weightKg: 6),
      ];

      final stats = calculator.from(entries);

      expect(stats.latest?.id, 'c');
      expect(stats.min, 4);
      expect(stats.max, 6);
      // (4 + 5 + 6) / 3 = 5
      expect(stats.avg, 5);
      // (6 - 5) / 5 * 100 = 20%
      expect(stats.change30dPercent, closeTo(20, 0.01));
      expect(stats.hasDanger, isTrue);
    });

    test('hasWarning flags 10..20% swings', () {
      final base = DateTime.utc(2026, 5, 10);
      final stats = calculator.from([
        WeightEntryFactory.build(
          id: 'a',
          date: base.subtract(const Duration(days: 30)),
          weightKg: 4,
        ),
        WeightEntryFactory.build(),
      ]);
      // (4.5 - 4) / 4 * 100 = 12.5%
      expect(stats.change30dPercent, closeTo(12.5, 0.01));
      expect(stats.hasWarning, isTrue);
      expect(stats.hasDanger, isFalse);
    });
  });
}
