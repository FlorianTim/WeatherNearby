import 'package:app_core/app_core.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/todos/data/tables/todo_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [TodoItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  /// Additive migration scaffold.
  ///
  /// Rules (learned in production):
  ///  - Prefer purely additive migrations via [_addColumnIfMissing] — it is
  ///    idempotent, so re-running a partially applied upgrade cannot crash.
  ///  - ⚠️ If you ever rebuild a table with `m.alterTable(TableMigration(...))`,
  ///    you MUST list every column added by LATER migrations in `newColumns`,
  ///    otherwise upgrading an old database crashes because the rebuilt
  ///    table lacks those columns.
  ///  - For every schema bump, add a raw-SQL fixture of the OLD schema to
  ///    `test/core/database/migration_test.dart` and assert the upgrade is
  ///    lossless (data survives, user_version updated).
  ///
  /// See `docs/architecture/contracts/02-database.md` for the full contract.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Example for a future schema version 2:
      // if (from < 2) {
      //   await addColumnIfMissing(m, todoItems, todoItems.priority);
      // }
    },
    beforeOpen: (details) async {
      // A DOWNGRADE is undefined in drift: `onUpgrade` only ever covers
      // `from < to`. Installing an older build over a newer database would
      // otherwise run queries against columns that do not exist yet and fail
      // somewhere deep inside a feature. Failing here keeps the user's data
      // intact and makes the cause obvious.
      if (details.versionBefore != null &&
          details.versionBefore! > details.versionNow) {
        throw StateError(
          'Database schema v${details.versionBefore} is newer than this build '
          '(v${details.versionNow}). Downgrading is not supported — install '
          'the newer app version again, or clear the app data to start over.',
        );
      }
      // Declared references are only enforced when this pragma is set on
      // EVERY connection — it is not the SQLite default.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Deletes every row from every table, atomically.
  ///
  /// **Scope: the database only.** Settings live in the `KeyValueStore`
  /// (shared_preferences) and deliberately survive — language and appearance
  /// are UI preferences, not app content. Label the action accordingly: this
  /// is "delete all content", not a factory reset. An app that wants a full
  /// reset has to clear the settings store as well, and should say so.
  ///
  /// Tables are deleted in **reverse declaration order**, so children go
  /// before parents: with `PRAGMA foreign_keys = ON` a RESTRICT edge would
  /// otherwise abort the wipe. That means the order in `@DriftDatabase`
  /// matters — declare parent tables first.
  ///
  /// Never touches anything outside the app's own database: no device
  /// contacts, no calendars, no files.
  Future<void> wipeAllData() async {
    await transaction(() async {
      for (final table in allTables.toList().reversed) {
        await delete(table).go();
      }
    });
  }

  /// Adds [column] to [table] unless it already exists (idempotent).
  ///
  /// Missing table → no-op: `onCreate`/`createAll` owns that case.
  Future<void> addColumnIfMissing(
    Migrator m,
    TableInfo<Table, dynamic> table,
    GeneratedColumn<Object> column,
  ) async {
    if (!await tableExists(table.actualTableName)) return;
    final info = await customSelect(
      'PRAGMA table_info(${table.actualTableName})',
    ).get();
    final names = info.map((row) => row.read<String>('name')).toSet();
    if (!names.contains(column.name)) {
      await m.addColumn(table, column);
    }
  }

  Future<bool> tableExists(String name) async {
    final rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable<String>(name)],
    ).get();
    return rows.isNotEmpty;
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      // The flavor names its own file: a snapshot or pre-release installed
      // next to the release must not open the release's data
      // (AppFlavor.databaseName; `app_database` for prod and dev).
      name: AppFlavor.current.databaseName('app_database'),
      // Web has no filesystem: drift runs sqlite3 as WebAssembly inside a
      // worker, and both files have to be served next to `index.html`.
      // `drift_flutter` throws an ArgumentError when this is missing, which
      // surfaces as a fatal `database` startup task and a recovery screen
      // whose retry can never succeed.
      //
      // The two files are build outputs, not hand-written sources — refresh
      // them with `dart run tool/sync_web_database_assets.dart` after every
      // drift upgrade (see `docs/operations/build-web.md`).
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}
