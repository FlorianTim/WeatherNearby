import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/domain/time/minute_of_day.dart';

void main() {
  group('MinuteOfDay', () {
    test('accepts the whole valid range', () {
      expect(MinuteOfDay(0).value, 0);
      expect(MinuteOfDay(1439).value, 1439);

      for (var minutes = 0; minutes <= 1439; minutes++) {
        expect(MinuteOfDay(minutes).value, minutes);
      }
    });

    test('rejects values outside 0..1439', () {
      expect(() => MinuteOfDay(-1), throwsRangeError);
      // 1440 is not "midnight tomorrow" — it is a different day.
      expect(() => MinuteOfDay(1440), throwsRangeError);
      expect(() => MinuteOfDay(100000), throwsRangeError);
    });

    test('splits into hour and minute', () {
      expect(MinuteOfDay(0).hour, 0);
      expect(MinuteOfDay(0).minute, 0);
      expect(MinuteOfDay(600).hour, 10);
      expect(MinuteOfDay(600).minute, 0);
      expect(MinuteOfDay(1439).hour, 23);
      expect(MinuteOfDay(1439).minute, 59);
    });

    test('builds from clock components and rejects impossible ones', () {
      expect(MinuteOfDay.fromHm(10, 0).value, 600);
      expect(MinuteOfDay.fromHm(23, 59).value, 1439);

      expect(() => MinuteOfDay.fromHm(24, 0), throwsRangeError);
      expect(() => MinuteOfDay.fromHm(10, 60), throwsRangeError);
      expect(() => MinuteOfDay.fromHm(-1, 0), throwsRangeError);
    });

    test('tryFrom degrades instead of throwing', () {
      expect(MinuteOfDay.tryFrom(600)?.value, 600);
      expect(MinuteOfDay.tryFrom(null), isNull);
      expect(MinuteOfDay.tryFrom(-1), isNull);
      expect(MinuteOfDay.tryFrom(1440), isNull);
    });

    test('compares and sorts by clock order', () {
      final morning = MinuteOfDay.fromHm(9, 0);
      final evening = MinuteOfDay.fromHm(18, 30);

      expect(morning < evening, isTrue);
      expect(evening > morning, isTrue);
      expect(morning <= morning, isTrue);

      final times = [evening, morning]..sort(MinuteOfDay.compare);
      expect(times, [morning, evening]);
    });

    // A wall-clock time is not a moment and not a span. Both would drag a
    // date or a zone into a value that has neither.
    test('exposes no DateTime and no Duration anywhere in its API', () {
      final source = File(
        'lib/core/domain/time/minute_of_day.dart',
      ).readAsStringSync();
      final code = source
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('///'))
          .join('\n');

      expect(code.contains('DateTime'), isFalse);
      expect(code.contains('Duration'), isFalse);
    });
  });
}
