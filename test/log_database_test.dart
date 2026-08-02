import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_logging/layrz_logging.dart';

/// Tests for [Log] database persistence using Drift/SQLite.
///
/// Verifies:
/// - Log entries are written to the database, not the in-memory buffer
/// - All log levels persist with correct level strings
/// - [retreiveLogs()] reads from the database and clears table after retrieval
/// - Row -> [LogEntry] level mapping with orElse fallback for invalid levels
/// - Direct Drift table operations (insert, select, update, delete)
/// - Drift API generation (RecordCompanion, RecordData, serialization, equality)
void main() {
  late LoggingDb db;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Log.logs.clear();
    Log.initialized = false;
    db = LoggingDb(NativeDatabase.memory());
    Log.ensureInitialized(database: db);
  });

  tearDown(() async {
    await db.close();
    Log.logs.clear();
    Log.initialized = false;
    // Note: we don't reset Log._db directly because it's private
    // and Dart's test runner uses isolates per file, preventing cross-file leakage
  });

  group('writes go to the database, not the in-memory buffer', () {
    test('Log.warning writes to db, returns 1 row with correct level and entry', () async {
      Log.warning('to db');

      // Pump the event loop to ensure fire-and-forget insert completes
      await Future<void>.delayed(Duration.zero);

      final rows = await db.select(db.record).get();
      expect(rows.length, 1);
      expect(rows[0].logLevel, 'WARNING');
      expect(rows[0].entry, 'to db');
    });

    test('Log.logs stays EMPTY after db write (entries go to db, not buffer)', () async {
      Log.warning('message 1');
      Log.error('message 2');

      // Let the fire-and-forget inserts complete
      await Future<void>.delayed(Duration.zero);

      expect(Log.logs.isEmpty, true,
          reason: 'when _db is set, logs should not accumulate in the buffer');
    });

    test('database contains both messages after multiple logs', () async {
      Log.debug('msg1');
      Log.info('msg2');
      Log.warning('msg3');

      await Future<void>.delayed(Duration.zero);

      final rows = await db.select(db.record).get();
      expect(rows.length, 3);
      expect(rows[0].entry, 'msg1');
      expect(rows[1].entry, 'msg2');
      expect(rows[2].entry, 'msg3');
    });
  });

  group('all levels persist with correct level string', () {
    test('loop all LogLevel.values, each persists with uppercase name', () async {
      for (final level in LogLevel.values) {
        Log.log(level: level, message: 'test_${level.name}');
      }

      await Future<void>.delayed(Duration.zero);

      final rows = await db.select(db.record).get();
      expect(rows.length, LogLevel.values.length);

      for (int i = 0; i < rows.length; i++) {
        expect(
          rows[i].logLevel,
          LogLevel.values[i].name.toUpperCase(),
          reason: 'logLevel should be uppercase version of level.name',
        );
        expect(rows[i].entry, 'test_${LogLevel.values[i].name}');
      }
    });
  });

  group('retreiveLogs reads from database and empties table', () {
    test('retreiveLogs returns formatted entries, db table is emptied, second call returns empty',
        () async {
      Log.info('entry 1');
      Log.warning('entry 2');
      Log.error('entry 3');

      await Future<void>.delayed(Duration.zero);

      // First call to retreiveLogs
      final firstResult = await Log.retreiveLogs();
      expect(firstResult.length, 3);
      expect(firstResult[0], matches(RegExp(r'\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] INFO: entry 1')));
      expect(firstResult[1], matches(RegExp(r'\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] WARNING: entry 2')));
      expect(firstResult[2], matches(RegExp(r'\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] ERROR: entry 3')));

      // Verify table is emptied
      final rowsAfter = await db.select(db.record).get();
      expect(rowsAfter.isEmpty, true, reason: 'retreiveLogs should delete all rows');

      // Second call should return empty
      final secondResult = await Log.retreiveLogs();
      expect(secondResult.isEmpty, true, reason: 'second call on empty table should return empty list');
    });

    test('entries from Log.logs buffer and db are merged and sorted by timestamp ascending',
        () async {
      // Seed Log.logs with an old entry manually (simulating a prior buffered entry)
      final oldTime = DateTime.utc(2026, 8, 1, 10, 0, 0);
      final oldEntry = LogEntry(level: LogLevel.debug, message: 'from buffer', timestamp: oldTime);
      Log.logs.add(oldEntry);

      // Now log via the db
      Log.info('from db 1');
      Log.warning('from db 2');

      await Future<void>.delayed(Duration.zero);

      // Retrieve logs
      final result = await Log.retreiveLogs();
      expect(result.length, 3, reason: 'should have buffer entry + 2 db entries');

      // Check ordering: old buffer entry should come first
      expect(result[0], contains('from buffer'));
      expect(result[1], contains('from db 1'));
      expect(result[2], contains('from db 2'));
    });

    test('Log.logs is cleared after retreiveLogs', () async {
      Log.debug('msg1');
      await Future<void>.delayed(Duration.zero);

      // Logs should have gone to db, not buffer
      expect(Log.logs.isEmpty, true);

      // Manually add a buffer entry to test the clear behavior
      Log.logs.add(LogEntry(level: LogLevel.info, message: 'manual', timestamp: DateTime.now()));
      expect(Log.logs.length, 1);

      await Log.retreiveLogs();

      expect(Log.logs.isEmpty, true, reason: 'retreiveLogs should clear Log.logs');
    });
  });

  group('row -> LogEntry level mapping with orElse fallback', () {
    test('invalid logLevel maps to LogLevel.info via orElse', () async {
      // Insert a row directly with an invalid logLevel
      await db.into(db.record).insert(
            RecordCompanion.insert(
              logLevel: 'BOGUS_LEVEL',
              entry: 'weird entry',
            ),
          );

      final result = await Log.retreiveLogs();

      expect(result.length, 1);
      expect(result[0], contains('INFO: weird entry'), reason: 'invalid level should map to INFO');
    });

    test('lowercase logLevel is correctly mapped (case-insensitive)', () async {
      // Insert rows with lowercase levels
      await db.into(db.record).insert(
            RecordCompanion.insert(
              logLevel: 'warning',
              entry: 'lowercase warning',
            ),
          );
      await db.into(db.record).insert(
            RecordCompanion.insert(
              logLevel: 'error',
              entry: 'lowercase error',
            ),
          );

      final result = await Log.retreiveLogs();

      expect(result.length, 2);
      expect(result[0], contains('WARNING: lowercase warning'));
      expect(result[1], contains('ERROR: lowercase error'));
    });

    test('all valid LogLevel.values map correctly when inserted with wrong case', () async {
      for (final level in LogLevel.values) {
        await db.into(db.record).insert(
              RecordCompanion.insert(
                logLevel: level.name.toLowerCase(), // insert lowercase
                entry: 'test_${level.name}',
              ),
            );
      }

      final result = await Log.retreiveLogs();

      expect(result.length, LogLevel.values.length);
      for (int i = 0; i < result.length; i++) {
        final levelName = LogLevel.values[i].name.toUpperCase();
        expect(result[i], contains('$levelName:'),
            reason: 'lowercase insertion should still map to correct level');
      }
    });
  });

  group('direct Drift table exercise (execute generated code)', () {
    test('insert via RecordCompanion.insert', () async {
      await db.into(db.record).insert(
            RecordCompanion.insert(
              logLevel: 'DEBUG',
              entry: 'test message',
            ),
          );

      final rows = await db.select(db.record).get();
      expect(rows.length, 1);
      expect(rows[0].logLevel, 'DEBUG');
      expect(rows[0].entry, 'test message');
    });

    test('insert with explicit createdAt timestamp', () async {
      final customTime = DateTime.utc(2026, 8, 2, 12, 30, 45);
      await db.into(db.record).insert(
            RecordCompanion.insert(
              logLevel: 'INFO',
              entry: 'custom time',
              createdAt: Value(customTime),
            ),
          );

      final rows = await db.select(db.record).get();
      // Verify that a timestamp was stored (may be affected by timezone, so just check year/month/day)
      final retrieved = rows[0].createdAt;
      expect(retrieved.year, 2026, reason: 'year should match');
      expect(retrieved.month, 8, reason: 'month should match');
      expect(retrieved.day, 2, reason: 'day should match');
    });

    test('select returns RecordData with all fields', () async {
      await db.into(db.record).insert(
            RecordCompanion.insert(
              logLevel: 'WARNING',
              entry: 'full record test',
            ),
          );

      final rows = await db.select(db.record).get();
      final record = rows[0];

      expect(record, isA<RecordData>());
      expect(record.id, greaterThan(0), reason: 'id should be auto-incremented');
      expect(record.logLevel, 'WARNING');
      expect(record.entry, 'full record test');
      expect(record.createdAt.toString().isNotEmpty, true,
          reason: 'createdAt should have a default value');
    });

    test('RecordData.toCompanion() produces equivalent companion', () async {
      final originalTime = DateTime.utc(2026, 8, 2, 15, 45, 30);
      await db.into(db.record).insert(
            RecordCompanion.insert(
              logLevel: 'ERROR',
              entry: 'companion test',
              createdAt: Value(originalTime),
            ),
          );

      final rows = await db.select(db.record).get();
      final record = rows[0];

      final companion = record.toCompanion(false);
      expect(companion.logLevel.present, true, reason: 'logLevel should be present in companion');
      if (companion.logLevel.present) {
        expect(companion.logLevel.value, 'ERROR');
      }
      expect(companion.entry.present, true, reason: 'entry should be present');
      expect(companion.entry.value, 'companion test');
      // Check the date components (timezone-safe)
      final companionTime = companion.createdAt.value;
      expect(companionTime.year, 2026);
      expect(companionTime.month, 8);
      expect(companionTime.day, 2);
    });

    test('RecordData.copyWith() produces modified record', () async {
      await db.into(db.record).insert(
            RecordCompanion.insert(
              logLevel: 'DEBUG',
              entry: 'original',
            ),
          );

      final rows = await db.select(db.record).get();
      final record = rows[0];

      final modified = record.copyWith(logLevel: 'INFO', entry: 'modified');
      expect(modified.logLevel, 'INFO');
      expect(modified.entry, 'modified');
      expect(modified.id, record.id, reason: 'id should remain unchanged');
    });

    test('RecordData.toString() produces non-empty string', () async {
      await db.into(db.record).insert(
            RecordCompanion.insert(
              logLevel: 'CRITICAL',
              entry: 'toString test',
            ),
          );

      final rows = await db.select(db.record).get();
      final record = rows[0];

      final str = record.toString();
      expect(str.isNotEmpty, true);
      expect(str.contains('logLevel') || str.contains('entry'), true,
          reason: 'toString should contain field names or values');
    });

    test('RecordData equality: == and hashCode work correctly', () async {
      final time = DateTime.utc(2026, 8, 2, 10, 0, 0);
      await db.into(db.record).insert(
            RecordCompanion.insert(
              logLevel: 'INFO',
              entry: 'equality test',
              createdAt: Value(time),
            ),
          );

      final rows1 = await db.select(db.record).get();
      final record1 = rows1[0];

      final rows2 = await db.select(db.record).get();
      final record2 = rows2[0];

      expect(record1 == record2, true, reason: 'same db row should be equal');
      expect(record1.hashCode == record2.hashCode, true,
          reason: 'equal records should have same hashCode');
    });

    test('RecordData.toJson() and fromJson() round-trip', () async {
      final time = DateTime.utc(2026, 8, 2, 14, 0, 0);
      await db.into(db.record).insert(
            RecordCompanion.insert(
              logLevel: 'WARNING',
              entry: 'json test',
              createdAt: Value(time),
            ),
          );

      final rows = await db.select(db.record).get();
      final original = rows[0];

      final json = original.toJson();
      expect(json, isA<Map<String, dynamic>>());
      // Drift may use snake_case field names in JSON
      expect(json.containsKey('log_level') || json.containsKey('logLevel'), true);
      final logLevelValue = json['log_level'] ?? json['logLevel'];
      expect(logLevelValue, 'WARNING', reason: 'JSON should contain logLevel value');
      expect(json['entry'], 'json test');

      final restored = RecordData.fromJson(json);
      expect(restored.logLevel, original.logLevel);
      expect(restored.entry, original.entry);
      expect(restored.id, original.id);
    });

    test('delete with where clause removes matching row', () async {
      await db.into(db.record).insert(
            RecordCompanion.insert(logLevel: 'DEBUG', entry: 'keep me'),
          );
      await db.into(db.record).insert(
            RecordCompanion.insert(logLevel: 'ERROR', entry: 'delete me'),
          );

      final rowsBefore = await db.select(db.record).get();
      expect(rowsBefore.length, 2);

      // Delete rows with 'ERROR' level
      await (db.delete(db.record)..where((tbl) => tbl.logLevel.equals('ERROR'))).go();

      final rowsAfter = await db.select(db.record).get();
      expect(rowsAfter.length, 1);
      expect(rowsAfter[0].entry, 'keep me');
    });

    test('update via replace', () async {
      await db.into(db.record).insert(
            RecordCompanion.insert(
              logLevel: 'INFO',
              entry: 'original',
            ),
          );

      final rows = await db.select(db.record).get();
      final record = rows[0];

      final updated = record.copyWith(entry: 'updated');
      await db.update(db.record).replace(updated);

      final rowsAfter = await db.select(db.record).get();
      expect(rowsAfter.length, 1);
      expect(rowsAfter[0].entry, 'updated');
      expect(rowsAfter[0].logLevel, 'INFO', reason: 'other fields should remain unchanged');
    });

    test('db.schemaVersion returns 1', () async {
      expect(db.schemaVersion, 1);
    });

    test('db.allTables includes record table', () async {
      expect(db.allTables.contains(db.record), true,
          reason: 'record table should be in allTables');
    });

    test('db.allSchemaEntities is not empty', () async {
      expect(db.allSchemaEntities.isNotEmpty, true,
          reason: 'database should have at least one schema entity (the Record table)');
    });

    test('insert multiple rows and select without where returns all', () async {
      for (int i = 0; i < 5; i++) {
        await db.into(db.record).insert(
              RecordCompanion.insert(
                logLevel: 'INFO',
                entry: 'entry $i',
              ),
            );
      }

      final rows = await db.select(db.record).get();
      expect(rows.length, 5);

      for (int i = 0; i < 5; i++) {
        expect(rows[i].entry, 'entry $i');
      }
    });

    test('query with where clause returns only matching rows', () async {
      await db.into(db.record).insert(
            RecordCompanion.insert(logLevel: 'DEBUG', entry: 'msg1'),
          );
      await db.into(db.record).insert(
            RecordCompanion.insert(logLevel: 'INFO', entry: 'msg2'),
          );
      await db.into(db.record).insert(
            RecordCompanion.insert(logLevel: 'DEBUG', entry: 'msg3'),
          );

      final debugRows = await (db.select(db.record)
            ..where((tbl) => tbl.logLevel.equals('DEBUG')))
          .get();

      expect(debugRows.length, 2);
      expect(debugRows[0].entry, 'msg1');
      expect(debugRows[1].entry, 'msg3');
    });
  });
}
