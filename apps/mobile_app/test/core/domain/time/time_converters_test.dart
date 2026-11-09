import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/domain/time/epoch_day.dart';
import 'package:mobile_app/core/domain/time/minute_of_day.dart';
import 'package:mobile_app/core/domain/time/time_converters.dart';

/// Round-trips the converters through a real SQLite `INTEGER` column.
///
/// The table is created with raw SQL rather than a generated Drift table on
/// purpose: story 001 introduces the converters, and no domain table uses
/// them yet (spec 0001's slice 2 owns that). Codegen also does not run over
/// `test/` — see `build.yaml`. What matters here is that the values survive
/// the actual storage path, which raw SQL exercises just as well.
void main() {
  late QueryExecutor executor;

  setUp(() async {
    executor = NativeDatabase.memory();
    await executor.ensureOpen(_NoOpUser());
    await executor.runCustom(
      'CREATE TABLE probe ('
      '  id INTEGER PRIMARY KEY,'
      '  day INTEGER NULL,'
      '  minutes INTEGER NULL CHECK (minutes IS NULL OR minutes BETWEEN 0 AND 1439)'
      ')',
      const [],
    );
  });

  tearDown(() => executor.close());

  Future<void> insert(int id, int? day, int? minutes) => executor.runInsert(
    'INSERT INTO probe (id, day, minutes) VALUES (?, ?, ?)',
    [id, day, minutes],
  );

  Future<List<Map<String, Object?>>> readAll() =>
      executor.runSelect('SELECT id, day, minutes FROM probe ORDER BY id', []);

  group('EpochDayConverter', () {
    const converter = EpochDayConverter();

    test('stores and reads a day unchanged', () async {
      final day = EpochDay.fromYmd(2027, 3, 14);
      await insert(1, converter.toSql(day), null);

      final rows = await readAll();
      final read = converter.fromSql(rows.single['day']! as int);

      expect(read, day);
      expect(read.toLocalDate(), day.toLocalDate());
    });

    test(
      'survives a round trip for a range of days including leap days',
      () async {
        final days = [
          EpochDay.fromYmd(1970, 1, 1),
          EpochDay.fromYmd(2027, 3, 27),
          EpochDay.fromYmd(2027, 3, 28), // DST spring forward
          EpochDay.fromYmd(2027, 10, 31), // DST fall back
          EpochDay.fromYmd(2028, 2, 29), // leap day
          EpochDay.fromYmd(2200, 12, 31),
        ];

        for (var i = 0; i < days.length; i++) {
          await insert(i, converter.toSql(days[i]), null);
        }

        final rows = await readAll();
        for (var i = 0; i < days.length; i++) {
          expect(converter.fromSql(rows[i]['day']! as int), days[i]);
        }
      },
    );

    test('a NULL day stays absent rather than becoming a sentinel', () async {
      await insert(1, null, null);

      final rows = await readAll();
      expect(rows.single['day'], null);
    });
  });

  group('MinuteOfDayConverter', () {
    const converter = MinuteOfDayConverter();

    test('stores and reads a time unchanged', () async {
      final time = MinuteOfDay.fromHm(10, 30);
      await insert(1, null, converter.toSql(time));

      final rows = await readAll();
      final read = converter.fromSql(rows.single['minutes']! as int);

      expect(read, time);
      expect(read.hour, 10);
      expect(read.minute, 30);
    });

    test('survives a round trip at both ends of the range', () async {
      final times = [MinuteOfDay(0), MinuteOfDay(720), MinuteOfDay(1439)];

      for (var i = 0; i < times.length; i++) {
        await insert(i, null, converter.toSql(times[i]));
      }

      final rows = await readAll();
      for (var i = 0; i < times.length; i++) {
        expect(converter.fromSql(rows[i]['minutes']! as int), times[i]);
      }
    });

    test('a CHECK constraint is what keeps an impossible time out', () async {
      await expectLater(insert(1, null, 1440), throwsA(anything));
    });

    test(
      'reading a corrupt out-of-range value throws rather than degrading',
      () {
        // The column CHECK makes this unreachable in practice; the converter
        // still refuses, so a corrupt row fails loudly instead of silently
        // producing a nonsense time. MinuteOfDay.tryFrom is the degrading path.
        expect(() => converter.fromSql(1440), throwsRangeError);
      },
    );
  });
}

/// Minimal [QueryExecutorUser] for opening a bare executor without a
/// generated database class.
class _NoOpUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
