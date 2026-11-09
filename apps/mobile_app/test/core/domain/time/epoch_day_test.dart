import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/domain/time/epoch_day.dart';
import 'package:time_machine2/time_machine2.dart';

void main() {
  group('EpochDay', () {
    test('round-trips every day from 1900 to 2200 losslessly', () {
      final start = LocalDate(1900, 1, 1).epochDay;
      final end = LocalDate(2200, 12, 31).epochDay;

      for (var day = start; day <= end; day++) {
        final epochDay = EpochDay(day);
        final date = epochDay.toLocalDate();
        expect(
          EpochDay.fromLocalDate(date).value,
          day,
          reason: 'round trip failed for $date',
        );
      }
    });

    test('reads its components back from the calendar', () {
      final day = EpochDay.fromYmd(2027, 3, 14);

      expect(day.year, 2027);
      expect(day.month, 3);
      expect(day.day, 14);
    });

    test('the Unix epoch is day zero', () {
      expect(EpochDay.fromYmd(1970, 1, 1).value, 0);
      expect(EpochDay(0).toLocalDate(), LocalDate(1970, 1, 1));
    });

    test('handles leap days as real calendar days', () {
      final leapDay = EpochDay.fromYmd(2028, 2, 29);

      expect(leapDay.day, 29);
      expect(leapDay.plusDays(1).toLocalDate(), LocalDate(2028, 3, 1));
      expect(leapDay.plusDays(-1).toLocalDate(), LocalDate(2028, 2, 28));
    });

    test('rejects a date that does not exist', () {
      // 2027 is not a leap year.
      expect(() => EpochDay.fromYmd(2027, 2, 29), throwsA(isA<Error>()));
      expect(() => EpochDay.fromYmd(2027, 4, 31), throwsA(isA<Error>()));
    });

    // The reason this type exists: a calendar day must not move when the
    // clock does. Europe/Berlin springs forward on 2027-03-28 and falls back
    // on 2027-10-31; both are ordinary days here.
    test('a DST transition does not shift the day', () {
      for (final (year, month, day) in const [
        (2027, 3, 27),
        (2027, 3, 28),
        (2027, 3, 29),
        (2027, 10, 30),
        (2027, 10, 31),
        (2027, 11, 1),
      ]) {
        final epochDay = EpochDay.fromYmd(year, month, day);
        final back = epochDay.toLocalDate();

        expect(back.year, year);
        expect(back.monthOfYear, month);
        expect(back.dayOfMonth, day);
      }
    });

    test('crossing a DST boundary is exactly one day', () {
      final before = EpochDay.fromYmd(2027, 3, 27);
      final after = EpochDay.fromYmd(2027, 3, 28);

      expect(after.daysSince(before), 1);
      expect(before.plusDays(1), after);
    });

    test('compares and sorts by calendar order', () {
      final earlier = EpochDay.fromYmd(2027, 3, 14);
      final later = EpochDay.fromYmd(2027, 3, 15);

      expect(earlier < later, isTrue);
      expect(later > earlier, isTrue);
      expect(earlier <= earlier, isTrue);
      expect(earlier.compareTo(later), lessThan(0));

      final days = [later, earlier]..sort(EpochDay.compare);
      expect(days, [earlier, later]);
    });

    // Guards the type's central promise. A DateTime carries a zone; an
    // EpochDay must not be constructible from one, or the guarantee is only
    // a convention.
    test('exposes no DateTime anywhere in its API', () {
      final source = File(
        'lib/core/domain/time/epoch_day.dart',
      ).readAsStringSync();
      final code = source
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('///'))
          .join('\n');

      expect(
        code.contains('DateTime'),
        isFalse,
        reason: 'EpochDay must not accept or return a DateTime',
      );
    });
  });
}
