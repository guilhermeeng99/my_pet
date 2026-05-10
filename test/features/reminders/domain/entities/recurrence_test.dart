import 'package:flutter_test/flutter_test.dart';
import 'package:my_pet/features/reminders/domain/entities/recurrence.dart';

void main() {
  group('Recurrence.nextAfter', () {
    test('oneShot returns null', () {
      final next = Recurrence.oneShot.nextAfter(DateTime.utc(2026, 5, 10));
      expect(next, isNull);
    });

    test('daily rolls forward at least to the next future day', () {
      // far in the past so the spec's "skip backlogged" edge case kicks in.
      final from = DateTime.now().toUtc().subtract(const Duration(days: 30));
      final next = Recurrence.daily.nextAfter(from);
      expect(next, isNotNull);
      expect(next!.isAfter(DateTime.now().toUtc()), isTrue);
    });

    test('weekly steps in 7-day increments', () {
      final from = DateTime.now().toUtc().add(const Duration(days: 1));
      final next = Recurrence.weekly.nextAfter(from);
      expect(next, isNotNull);
      expect(
        next!.difference(from).inDays,
        equals(7),
      );
    });

    test('custom respects the interval', () {
      final from = DateTime.now().toUtc().add(const Duration(days: 1));
      final next =
          Recurrence.custom.nextAfter(from, customIntervalDays: 90);
      expect(next, isNotNull);
      expect(next!.difference(from).inDays, equals(90));
    });
  });
}
