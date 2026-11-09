import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3_pkg;

/// Migration fixture tests.
///
/// Pattern: for EVERY released schema version, keep a raw-SQL snapshot of
/// that schema here. Each test builds an old database from the snapshot,
/// inserts data, opens [AppDatabase] on top (which runs the migrations) and
/// asserts the upgrade is lossless.
///
/// When bumping `schemaVersion`:
///  1. add `schemaVN` below (dump: SELECT sql FROM sqlite_master)
///  2. add a test `upgrades from vN losslessly`
///
/// Test gotcha (FakeAsync): `await someDriftStream.first` directly in a
/// `testWidgets` body deadlocks. Plain `test()` (as used here) is fine;
/// inside `testWidgets` wrap DB work in `tester.runAsync(() async { ... })`.

/// Raw snapshot of schema version 1 (todo_items only).
const schemaV1 = '''
CREATE TABLE "todo_items" (
  "id" TEXT NOT NULL,
  "title" TEXT NOT NULL,
  "description" TEXT NOT NULL DEFAULT '',
  "status" TEXT NOT NULL DEFAULT 'pending',
  "created_at" INTEGER NOT NULL,
  "completed_at" INTEGER NULL,
  PRIMARY KEY ("id")
);
''';

void main() {
  test('opens a v1 database losslessly', () async {
    // Build the "old" database from the raw v1 snapshot.
    final raw = sqlite3_pkg.sqlite3.openInMemory();
    raw
      ..execute(schemaV1)
      ..execute(
        "INSERT INTO todo_items (id, title, created_at) "
        "VALUES ('t1', 'migrate me', 1700000000)",
      )
      ..execute('PRAGMA user_version = 1');

    // Opening AppDatabase on top runs the migration chain.
    final database = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(database.close);

    final todos = await database.select(database.todoItems).get();
    expect(todos, hasLength(1));
    expect(todos.single.id, 't1');
    expect(todos.single.title, 'migrate me');

    final version = await database
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.read<int>('user_version'), database.schemaVersion);
  });

  test('addColumnIfMissing is idempotent', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    // Force open so the migrator can be used.
    await database.customSelect('SELECT 1').get();

    final migrator = database.createMigrator();
    // Column already exists — must be a no-op, not a crash.
    await database.addColumnIfMissing(
      migrator,
      database.todoItems,
      database.todoItems.title,
    );

    expect(await database.tableExists('todo_items'), isTrue);
    expect(await database.tableExists('nope'), isFalse);
  });
}
