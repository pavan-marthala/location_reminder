import 'package:drift/drift.dart';
import 'package:reminders/generated/assets.dart';

part 'app_database.g.dart';

@DataClassName('ReminderData')
class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get radius => real()();
  TextColumn get alarmTone => text().withDefault(Constant(Assets.audioDaybreak))();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get isTriggered => boolean().withDefault(const Constant(false))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get triggeredAt => dateTime().nullable()();
  DateTimeColumn get lastTriggeredAt => dateTime().nullable()();
  DateTimeColumn get snoozedUntil => dateTime().nullable()();
  TextColumn get locationName => text().nullable()();
  TextColumn get locationAddress => text().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

@DriftDatabase(tables: [Reminders])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          Future<void> safeAddColumn(dynamic table, dynamic column) async {
            try {
              await migrator.addColumn(table, column);
            } catch (e) {
              final errStr = e.toString().toLowerCase();
              if (!errStr.contains('duplicate column name') && 
                  !errStr.contains('already exists')) {
                rethrow;
              }
            }
          }

          if (from < 2) {
            await safeAddColumn(reminders, reminders.alarmTone);
            await safeAddColumn(reminders, reminders.updatedAt);
          }
          if (from < 3) {
            await safeAddColumn(reminders, reminders.status);
            await safeAddColumn(reminders, reminders.triggeredAt);
            await safeAddColumn(reminders, reminders.lastTriggeredAt);
          }
          if (from < 4) {
            await safeAddColumn(reminders, reminders.snoozedUntil);
          }
          if (from < 5) {
            await safeAddColumn(reminders, reminders.locationName);
            await safeAddColumn(reminders, reminders.locationAddress);
            await safeAddColumn(reminders, reminders.completedAt);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
