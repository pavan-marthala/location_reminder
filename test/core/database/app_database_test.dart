import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminders/core/database/app_database.dart';

void main() {
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
