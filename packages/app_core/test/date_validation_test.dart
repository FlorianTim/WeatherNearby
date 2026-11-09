import 'package:app_core/app_core.dart';
import 'package:test/test.dart';

void main() {
  group('isValidDate', () {
    test('accepts an ordinary date', () {
      expect(DateValidation.isValidDate(2026, 7, 22), isTrue);
    });

    test('Feb 29 is valid in a leap year, invalid otherwise', () {
      expect(DateValidation.isValidDate(2024, 2, 29), isTrue); // leap year
      expect(DateValidation.isValidDate(2025, 2, 29), isFalse); // non-leap
    });

    test('rejects out-of-range month/day without throwing', () {
      expect(DateValidation.isValidDate(2026, 13, 1), isFalse);
      expect(DateValidation.isValidDate(2026, 4, 31), isFalse);
      expect(DateValidation.isValidDate(2026, 0, 10), isFalse);
    });
  });

  group('isValidAnnualDate', () {
    test('Feb 29 is a valid yearless date', () {
      expect(DateValidation.isValidAnnualDate(2, 29), isTrue);
    });

    test('rejects Feb 30', () {
      expect(DateValidation.isValidAnnualDate(2, 30), isFalse);
    });
  });

  group('annualDateOccursIn', () {
    test('Feb 29 only materializes in leap years', () {
      expect(DateValidation.annualDateOccursIn(2, 29, 2024), isTrue);
      expect(DateValidation.annualDateOccursIn(2, 29, 2025), isFalse);
    });

    test('a normal annual date occurs every year', () {
      expect(DateValidation.annualDateOccursIn(7, 22, 2025), isTrue);
    });
  });

  group('tryLocalDate', () {
    test('returns a value for valid input and null for invalid', () {
      expect(DateValidation.tryLocalDate(2026, 7, 22), isNotNull);
      expect(DateValidation.tryLocalDate(2026, 2, 30), isNull);
    });
  });
}
