import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/database/app_database.dart';
import 'package:mobile_app/core/utils/id_generator.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> insertTodo(String title) {
    return db
        .into(db.todoItems)
        .insert(
          TodoItemsCompanion.insert(
            id: generateId(),
            title: title,
            createdAt: DateTime(2026, 1, 1),
          ),
        );
  }

  test('removes every row from every table', () async {
    await insertTodo('one');
    await insertTodo('two');
    expect(await db.select(db.todoItems).get(), hasLength(2));

    await db.wipeAllData();

    expect(await db.select(db.todoItems).get(), isEmpty);
  });

  test('is safe on an already empty database', () async {
    await db.wipeAllData();
    await db.wipeAllData();

    expect(await db.select(db.todoItems).get(), isEmpty);
  });

  test('the database stays usable afterwards', () async {
    await insertTodo('before');
    await db.wipeAllData();

    await insertTodo('after');

    final rows = await db.select(db.todoItems).get();
    expect(rows.map((r) => r.title), ['after']);
  });

  test('foreign keys stay enforced across the wipe', () async {
    // The wipe runs in a transaction with FK enforcement on; it must not
    // disable the pragma to get its work done.
    await db.wipeAllData();

    final rows = await db.customSelect('PRAGMA foreign_keys').get();
    expect(rows.single.read<int>('foreign_keys'), 1);
  });
}
