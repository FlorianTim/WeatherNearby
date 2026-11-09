import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/database/app_database.dart';

void main() {
  test('foreign key enforcement is ON for every connection', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // `beforeOpen` only runs when the database is actually opened, so touch
    // it first.
    await db.customSelect('SELECT 1').get();

    final rows = await db.customSelect('PRAGMA foreign_keys').get();

    // Without the pragma SQLite silently ignores every declared REFERENCES
    // clause — the constraints would be documentation, not enforcement.
    expect(rows.single.read<int>('foreign_keys'), 1);
  });

  test('a declared foreign key actually rejects an orphan row', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db.customStatement('CREATE TABLE parent (id TEXT PRIMARY KEY)');
    await db.customStatement(
      'CREATE TABLE child ('
      '  id TEXT PRIMARY KEY,'
      '  parent_id TEXT NOT NULL REFERENCES parent (id)'
      ')',
    );

    await expectLater(
      db.customStatement(
        "INSERT INTO child (id, parent_id) VALUES ('c1', 'missing')",
      ),
      throwsA(isA<SqliteException>()),
    );
  });
}
