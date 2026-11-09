import 'package:drift/drift.dart';

import 'epoch_day.dart';
import 'minute_of_day.dart';

/// Stores an [EpochDay] as an `INTEGER`.
///
/// ⚠️ **Declare this on the storage type, not on the semantic one**
/// ([KI-004](../../../../../../docs/known-issues.md#ki-004)):
///
/// ```dart
/// // RIGHT
/// IntColumn get dueDateDay =>
///     integer().nullable().map(const EpochDayConverter())();
///
/// // WRONG — a TypeConverter on dateTime() puts the day back into a value
/// // that carries a zone, which is the whole thing EpochDay exists to avoid.
/// DateTimeColumn get dueDateDay => dateTime().map(const EpochDayConverter())();
/// ```
///
/// ⚠️ The converter must also be imported into the **database library file**
/// (`core/database/app_database.dart`), not only into the file declaring the
/// column — otherwise codegen fails with
/// `Couldn't find constructor 'EpochDayConverter'`.
class EpochDayConverter extends TypeConverter<EpochDay, int> {
  const EpochDayConverter();

  @override
  EpochDay fromSql(int fromDb) => EpochDay(fromDb);

  @override
  int toSql(EpochDay value) => value.value;
}

/// Stores a [MinuteOfDay] as an `INTEGER`.
///
/// Same two rules as [EpochDayConverter]: declare it on `integer()`, and
/// import it into the database library file.
///
/// An out-of-range value read from storage is a corrupt row rather than a
/// user error, so [fromSql] throws — a `CHECK (x BETWEEN 0 AND 1439)`
/// constraint on the column is what prevents it from ever happening. Use
/// [MinuteOfDay.tryFrom] where a bad value must degrade instead.
class MinuteOfDayConverter extends TypeConverter<MinuteOfDay, int> {
  const MinuteOfDayConverter();

  @override
  MinuteOfDay fromSql(int fromDb) => MinuteOfDay(fromDb);

  @override
  int toSql(MinuteOfDay value) => value.value;
}
