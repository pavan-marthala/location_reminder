import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:reminders/core/database/app_database.dart';

void main() {
  // Each test opens its own in-memory/file database; the warning is expected.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('Database starts with empty reminders', () async {
    final reminders = await database.select(database.reminders).get();
    expect(reminders, isEmpty);
  });

  test('Can insert and retrieve a reminder', () async {
    final now = DateTime.now();
    final reminderId = await database.into(database.reminders).insert(
          RemindersCompanion.insert(
            title: 'Test Reminder',
            description: const Value('Test Description'),
            latitude: 12.34,
            longitude: 56.78,
            radius: 100.0,
            isEnabled: const Value(true),
            isTriggered: const Value(false),
            createdAt: now,
          ),
        );

    expect(reminderId, isNotNull);

    final reminders = await database.select(database.reminders).get();
    expect(reminders, hasLength(1));

    final reminder = reminders.first;
    expect(reminder.id, reminderId);
    expect(reminder.title, 'Test Reminder');
    expect(reminder.description, 'Test Description');
    expect(reminder.latitude, 12.34);
    expect(reminder.longitude, 56.78);
    expect(reminder.radius, 100.0);
    expect(reminder.isEnabled, isTrue);
    expect(reminder.isTriggered, isFalse);
    expect(reminder.createdAt.difference(now).inSeconds, 0);
  });

  test('Upgrade from v5 normalises sub-150 m radii and is idempotent', () async {
    // A real file is needed so the v5 database can be closed and reopened as
    // v6, which is what actually exercises drift's migration path.
    final tempDir = await Directory.systemTemp.createTemp('reminders_migration');
    addTearDown(() => tempDir.delete(recursive: true));
    final file = File(p.join(tempDir.path, 'app_database.db'));

    final legacy = _AppDatabaseAtV5(NativeDatabase(file));
    await legacy.into(legacy.reminders).insert(
          RemindersCompanion.insert(
            title: 'Old reminder',
            latitude: 12.34,
            longitude: 56.78,
            radius: 100.0,
            createdAt: DateTime.now(),
          ),
        );
    await legacy.close();

    final migrated = AppDatabase(NativeDatabase(file));
    var rows = await migrated.select(migrated.reminders).get();
    expect(rows, hasLength(1));
    expect(rows.single.radius, 150.0);
    await migrated.close();

    // Reopening must leave normalised values untouched.
    final reopened = AppDatabase(NativeDatabase(file));
    rows = await reopened.select(reopened.reminders).get();
    expect(rows.single.radius, 150.0);
    await reopened.close();
  });

  test('Can update and delete a reminder', () async {
    final now = DateTime.now();
    final reminderId = await database.into(database.reminders).insert(
          RemindersCompanion.insert(
            title: 'Test Reminder',
            latitude: 12.34,
            longitude: 56.78,
            radius: 100.0,
            createdAt: now,
          ),
        );

    // Update isEnabled and isTriggered
    await (database.update(database.reminders)
          ..where((t) => t.id.equals(reminderId)))
        .write(
      const RemindersCompanion(
        isEnabled: Value(false),
        isTriggered: Value(true),
      ),
    );

    var reminder = await (database.select(database.reminders)
          ..where((t) => t.id.equals(reminderId)))
        .getSingle();

    expect(reminder.isEnabled, isFalse);
    expect(reminder.isTriggered, isTrue);

    // Delete
    await (database.delete(database.reminders)
          ..where((t) => t.id.equals(reminderId)))
        .go();

    final reminders = await database.select(database.reminders).get();
    expect(reminders, isEmpty);
  });
}

/// Mimics the schema shipped before the geofence radius change so the
/// migration can be exercised against a real v5 database file.
class _AppDatabaseAtV5 extends AppDatabase {
  _AppDatabaseAtV5(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy();
}
