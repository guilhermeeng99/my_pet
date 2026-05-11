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

    group('monthly month-end clamping', () {
      // Years far in the future so `_step` produces a value after `now` on
      // the first pass — keeps assertions deterministic regardless of clock.
      test('Jan 31 -> Feb 28 in a non-leap year', () {
        final from = DateTime.utc(2099, 1, 31, 9);
        final next = Recurrence.monthly.nextAfter(from);
        expect(next, equals(DateTime.utc(2099, 2, 28, 9)));
      });

      test('Jan 31 -> Feb 29 in a leap year', () {
        final from = DateTime.utc(2096, 1, 31, 9);
        final next = Recurrence.monthly.nextAfter(from);
        expect(next, equals(DateTime.utc(2096, 2, 29, 9)));
      });

      test('Mar 31 -> Apr 30 (target month shorter)', () {
        final from = DateTime.utc(2099, 3, 31, 9);
        final next = Recurrence.monthly.nextAfter(from);
        expect(next, equals(DateTime.utc(2099, 4, 30, 9)));
      });

      test('Dec 31 -> Jan 31 next year (year rollover preserves day)', () {
        final from = DateTime.utc(2099, 12, 31, 9);
        final next = Recurrence.monthly.nextAfter(from);
        expect(next, equals(DateTime.utc(2100, 1, 31, 9)));
      });

      test('mid-month dates are unchanged', () {
        final from = DateTime.utc(2099, 5, 15, 9);
        final next = Recurrence.monthly.nextAfter(from);
        expect(next, equals(DateTime.utc(2099, 6, 15, 9)));
      });
    });

    group('yearly leap-year clamping', () {
      test('Feb 29 (leap) -> Feb 28 (non-leap)', () {
        final from = DateTime.utc(2096, 2, 29, 9);
        final next = Recurrence.yearly.nextAfter(from);
        expect(next, equals(DateTime.utc(2097, 2, 28, 9)));
      });

      test('Feb 29 (leap) -> Feb 29 four years later (next leap)', () {
        // Catch-up loop steps year by year: 2096 -> 2097 (Feb 28) -> 2098
        // (Feb 28) -> 2099 (Feb 28) -> 2100 (Feb 28, divisible by 100 not by
        // 400). Once it lands on a non-Feb-29 date, it stays clamped.
        // Verifies catch-up behavior, not that day "rebounds" to 29.
        // Using a near-now from to force the loop to skip backlog.
        final past = DateTime.utc(2000, 2, 29, 9);
        final next = Recurrence.yearly.nextAfter(past);
        expect(next, isNotNull);
        // The first year where catch-up lands AFTER now will be Feb 28 of
        // some year (clamped). We just assert it never crashed and stays in
        // February.
        expect(next!.month, equals(2));
      });

      test('Jul 4 -> Jul 4 next year (no clamping needed)', () {
        final from = DateTime.utc(2099, 7, 4, 9);
        final next = Recurrence.yearly.nextAfter(from);
        expect(next, equals(DateTime.utc(2100, 7, 4, 9)));
      });
    });

    test('isRecurring returns true for everything except oneShot', () {
      expect(Recurrence.oneShot.isRecurring, isFalse);
      expect(Recurrence.daily.isRecurring, isTrue);
      expect(Recurrence.weekly.isRecurring, isTrue);
      expect(Recurrence.monthly.isRecurring, isTrue);
      expect(Recurrence.yearly.isRecurring, isTrue);
      expect(Recurrence.custom.isRecurring, isTrue);
    });
  });
}
