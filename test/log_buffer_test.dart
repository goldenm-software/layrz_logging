import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_logging/layrz_logging.dart';
import 'helpers/capture_debug_print.dart';

/// Tests for [Log] in-memory buffer and log entry storage.
///
/// Verifies:
/// - Log entries are added to [Log.logs] for each level
/// - Entries accumulate in call order
/// - [LogEntry.toString()] format is correct
/// - [retreiveLogs()] returns sorted, formatted entries and clears buffer
void main() {
  late DebugPrintCapture capture;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    capture = DebugPrintCapture();
    capture.start();
    Log.logs.clear();
  });

  tearDown(() {
    capture.stop();
    Log.logs.clear();
  });

  group('Log entry storage', () {
    test('debug() adds LogEntry to buffer with correct level and message', () {
      Log.debug('debug message');

      expect(Log.logs.length, 1);
      expect(Log.logs[0].level, LogLevel.debug);
      expect(Log.logs[0].message, 'debug message');
    });

    test('info() adds LogEntry to buffer', () {
      Log.info('info message');

      expect(Log.logs.length, 1);
      expect(Log.logs[0].level, LogLevel.info);
      expect(Log.logs[0].message, 'info message');
    });

    test('warning() adds LogEntry to buffer', () {
      Log.warning('warning message');

      expect(Log.logs.length, 1);
      expect(Log.logs[0].level, LogLevel.warning);
      expect(Log.logs[0].message, 'warning message');
    });

    test('error() adds LogEntry to buffer', () {
      Log.error('error message');

      expect(Log.logs.length, 1);
      expect(Log.logs[0].level, LogLevel.error);
      expect(Log.logs[0].message, 'error message');
    });

    test('critical() adds LogEntry to buffer', () {
      Log.critical('critical message');

      expect(Log.logs.length, 1);
      expect(Log.logs[0].level, LogLevel.critical);
      expect(Log.logs[0].message, 'critical message');
    });
  });

  group('Log entry accumulation', () {
    test('entries accumulate in call order', () {
      Log.debug('first');
      Log.info('second');
      Log.warning('third');

      expect(Log.logs.length, 3);
      expect(Log.logs[0].level, LogLevel.debug);
      expect(Log.logs[0].message, 'first');
      expect(Log.logs[1].level, LogLevel.info);
      expect(Log.logs[1].message, 'second');
      expect(Log.logs[2].level, LogLevel.warning);
      expect(Log.logs[2].message, 'third');
    });

    test('multiple calls to same level accumulate', () {
      Log.warning('warning 1');
      Log.warning('warning 2');
      Log.warning('warning 3');

      expect(Log.logs.length, 3);
      expect(Log.logs[0].message, 'warning 1');
      expect(Log.logs[1].message, 'warning 2');
      expect(Log.logs[2].message, 'warning 3');
    });
  });

  group('LogEntry.toString()', () {
    test('formats as [LEVEL] timestamp => message', () {
      Log.debug('test message');

      final entry = Log.logs[0];
      final formatted = entry.toString();

      expect(formatted.contains('[DEBUG]'), true);
      expect(formatted.contains('test message'), true);
      expect(formatted.contains('=>'), true);
    });

    test('toString includes full timestamp', () {
      Log.info('message');

      final entry = Log.logs[0];
      final formatted = entry.toString();

      // Format: "[INFO] 2026-08-02 HH:MM:SS.mmmuuuZ => message"
      expect(formatted, matches(RegExp(r'\[INFO\].*=>.*message')));
    });
  });

  group('retreiveLogs()', () {
    test('returns empty list when buffer is empty', () async {
      final result = await Log.retreiveLogs();

      expect(result.isEmpty, true);
    });

    test('returns single entry with correct format', () async {
      final now = DateTime.utc(2026, 8, 2, 10, 30, 45);
      final entry = LogEntry(
        level: LogLevel.debug,
        message: 'test message',
        timestamp: now,
      );
      Log.logs.add(entry);

      final result = await Log.retreiveLogs();

      expect(result.length, 1);
      expect(result[0], '[2026-08-02 10:30:45] DEBUG: test message');
    });

    test('returns entries in ascending timestamp order', () async {
      // Add entries with non-sequential timestamps
      final entry1 = LogEntry(
        level: LogLevel.info,
        message: 'third',
        timestamp: DateTime.utc(2026, 8, 2, 12, 0, 0),
      );
      final entry2 = LogEntry(
        level: LogLevel.warning,
        message: 'first',
        timestamp: DateTime.utc(2026, 8, 2, 10, 0, 0),
      );
      final entry3 = LogEntry(
        level: LogLevel.error,
        message: 'second',
        timestamp: DateTime.utc(2026, 8, 2, 11, 0, 0),
      );

      Log.logs.addAll([entry1, entry2, entry3]);

      final result = await Log.retreiveLogs();

      expect(result.length, 3);
      expect(result[0], '[2026-08-02 10:00:00] WARNING: first');
      expect(result[1], '[2026-08-02 11:00:00] ERROR: second');
      expect(result[2], '[2026-08-02 12:00:00] INFO: third');
    });

    test('formats timestamp using UTC timezone', () async {
      // Use explicit UTC timestamp to ensure formatting is UTC-based
      final entry = LogEntry(
        level: LogLevel.critical,
        message: 'utc test',
        timestamp: DateTime.utc(2026, 12, 31, 23, 59, 59),
      );
      Log.logs.add(entry);

      final result = await Log.retreiveLogs();

      expect(result[0], '[2026-12-31 23:59:59] CRITICAL: utc test');
    });

    test('formats timestamp with zero-padded month, day, and time', () async {
      // Test edge case: single-digit month/day/hour/minute/second
      final entry = LogEntry(
        level: LogLevel.debug,
        message: 'padding test',
        timestamp: DateTime.utc(2026, 1, 5, 3, 7, 9),
      );
      Log.logs.add(entry);

      final result = await Log.retreiveLogs();

      expect(result[0], '[2026-01-05 03:07:09] DEBUG: padding test');
    });

    test('clears buffer after retreiving', () async {
      Log.debug('message 1');
      Log.info('message 2');

      expect(Log.logs.length, 2);

      await Log.retreiveLogs();

      expect(Log.logs.isEmpty, true);
    });

    test('second call after clear returns empty list', () async {
      Log.debug('first call');
      await Log.retreiveLogs();

      final secondResult = await Log.retreiveLogs();

      expect(secondResult.isEmpty, true);
    });

    test('handles multiple entries with same timestamp', () async {
      final time = DateTime.utc(2026, 8, 2, 12, 0, 0);
      final entry1 = LogEntry(level: LogLevel.debug, message: 'msg1', timestamp: time);
      final entry2 = LogEntry(level: LogLevel.info, message: 'msg2', timestamp: time);
      final entry3 = LogEntry(level: LogLevel.warning, message: 'msg3', timestamp: time);

      Log.logs.addAll([entry1, entry2, entry3]);

      final result = await Log.retreiveLogs();

      expect(result.length, 3);
      // All should have same timestamp; order should be stable
      expect(result[0], '[2026-08-02 12:00:00] DEBUG: msg1');
      expect(result[1], '[2026-08-02 12:00:00] INFO: msg2');
      expect(result[2], '[2026-08-02 12:00:00] WARNING: msg3');
    });

    test('formats level name in uppercase', () async {
      for (final level in LogLevel.values) {
        Log.logs.clear();
        final entry = LogEntry(
          level: level,
          message: 'test',
          timestamp: DateTime.utc(2026, 8, 2, 10, 0, 0),
        );
        Log.logs.add(entry);

        final result = await Log.retreiveLogs();

        expect(
          result[0],
          '[2026-08-02 10:00:00] ${level.name.toUpperCase()}: test',
        );
      }
    });
  });

  group('Buffer isolation', () {
    test('does not cross-contaminate between test cases', () async {
      Log.debug('test 1');
      expect(Log.logs.length, 1);

      // Clear happens in setUp, so next test should start fresh
      await Log.retreiveLogs();
      expect(Log.logs.isEmpty, true);

      // Fresh log should add only one entry
      Log.info('test 2');
      expect(Log.logs.length, 1);
    });
  });
}
