import 'package:flutter_test/flutter_test.dart';

import 'package:my_pet/features/pets/domain/entities/age.dart';

void main() {
  group('Age.from', () {
    test('returns null when birthDate is null', () {
      expect(Age.from(null), isNull);
    });

    test('returns null when birthDate is in the future', () {
      final future = DateTime.utc(2030);
      final now = DateTime.utc(2026, 5, 9);
      expect(Age.from(future, now: now), isNull);
    });

    test('computes years and months for a 2y3m old', () {
      final birth = DateTime.utc(2024, 2, 9);
      final now = DateTime.utc(2026, 5, 9);
      final age = Age.from(birth, now: now);
      expect(age, isNotNull);
      expect(age!.years, 2);
      expect(age.months, 3);
    });

    test('an under-1-month-old is reported in days', () {
      final birth = DateTime.utc(2026, 5);
      final now = DateTime.utc(2026, 5, 9);
      final age = Age.from(birth, now: now)!;
      expect(age.isUnderOneMonth, isTrue);
      expect(age.days, 8);
    });

    test('an under-1-year-old reports months only', () {
      final birth = DateTime.utc(2025, 9, 9);
      final now = DateTime.utc(2026, 5, 9);
      final age = Age.from(birth, now: now)!;
      expect(age.isUnderOneYear, isTrue);
      expect(age.years, 0);
      expect(age.months, 8);
    });
  });
}
