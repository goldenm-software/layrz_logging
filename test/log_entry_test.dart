import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_logging/layrz_logging.dart';

/// Tests for [LogEntry] class.
///
/// Verifies:
/// - [LogEntry] can be constructed with required fields
/// - Field values are accessible
/// - Fields are mutable and reflect changes
/// - [toString()] returns the correct format: "[$level] $timestamp => $message"
void main() {
  group('LogEntry construction', () {
    test('LogEntry can be constructed with required fields', () {
      final timestamp = DateTime.utc(2026, 8, 17, 10, 30, 45);
      final entry = LogEntry(
        message: 'test message',
        level: LogLevel.info,
        timestamp: timestamp,
      );

      expect(entry, isNotNull);
      expect(entry.message, 'test message');
      expect(entry.level, LogLevel.info);
      expect(entry.timestamp, timestamp);
    });

    test('LogEntry can be constructed with all five log levels', () {
      final levels = [
        LogLevel.debug,
        LogLevel.info,
        LogLevel.warning,
        LogLevel.error,
        LogLevel.critical,
      ];

      for (final level in levels) {
        final entry = LogEntry(
          message: 'test',
          level: level,
          timestamp: DateTime.now(),
        );
        expect(entry.level, level);
      }
    });
  });

  group('LogEntry field access', () {
    test('message field is accessible after construction', () {
      final entry = LogEntry(
        message: 'hello world',
        level: LogLevel.debug,
        timestamp: DateTime.now(),
      );

      expect(entry.message, 'hello world');
    });

    test('level field is accessible after construction', () {
      final entry = LogEntry(
        message: 'test',
        level: LogLevel.warning,
        timestamp: DateTime.now(),
      );

      expect(entry.level, LogLevel.warning);
    });

    test('timestamp field is accessible after construction', () {
      final ts = DateTime.utc(2026, 8, 17, 12, 45, 30);
      final entry = LogEntry(
        message: 'test',
        level: LogLevel.info,
        timestamp: ts,
      );

      expect(entry.timestamp, ts);
    });
  });

  group('LogEntry mutability', () {
    test('message field can be reassigned', () {
      final entry = LogEntry(
        message: 'original',
        level: LogLevel.info,
        timestamp: DateTime.now(),
      );

      expect(entry.message, 'original');

      entry.message = 'modified';

      expect(entry.message, 'modified');
    });

    test('level field can be reassigned', () {
      final entry = LogEntry(
        message: 'test',
        level: LogLevel.debug,
        timestamp: DateTime.now(),
      );

      expect(entry.level, LogLevel.debug);

      entry.level = LogLevel.error;

      expect(entry.level, LogLevel.error);
    });

    test('timestamp field can be reassigned', () {
      final ts1 = DateTime.utc(2026, 8, 17, 10, 0, 0);
      final ts2 = DateTime.utc(2026, 8, 17, 11, 0, 0);
      final entry = LogEntry(
        message: 'test',
        level: LogLevel.info,
        timestamp: ts1,
      );

      expect(entry.timestamp, ts1);

      entry.timestamp = ts2;

      expect(entry.timestamp, ts2);
    });

    test('reassigning message affects toString() output', () {
      final ts = DateTime.utc(2026, 8, 17, 10, 30, 45);
      final entry = LogEntry(
        message: 'before',
        level: LogLevel.info,
        timestamp: ts,
      );

      final before = entry.toString();
      expect(before, contains('before'));

      entry.message = 'after';

      final after = entry.toString();
      expect(after, contains('after'));
      expect(after, isNot(equals(before)));
    });

    test('reassigning level affects toString() output', () {
      final ts = DateTime.utc(2026, 8, 17, 10, 30, 45);
      final entry = LogEntry(
        message: 'test',
        level: LogLevel.debug,
        timestamp: ts,
      );

      final before = entry.toString();
      expect(before, contains('DEBUG'));

      entry.level = LogLevel.critical;

      final after = entry.toString();
      expect(after, contains('CRITICAL'));
      expect(after, isNot(equals(before)));
    });

    test('reassigning timestamp affects toString() output', () {
      final ts1 = DateTime.utc(2026, 8, 17, 10, 30, 45);
      final ts2 = DateTime.utc(2026, 8, 17, 11, 30, 45);
      final entry = LogEntry(
        message: 'test',
        level: LogLevel.info,
        timestamp: ts1,
      );

      final before = entry.toString();
      expect(before, contains('10:30:45'));

      entry.timestamp = ts2;

      final after = entry.toString();
      expect(after, contains('11:30:45'));
      expect(after, isNot(equals(before)));
    });
  });

  group('LogEntry.toString()', () {
    test('toString() returns format: [LEVEL] timestamp => message', () {
      final ts = DateTime.utc(2026, 8, 17, 10, 30, 45);
      final entry = LogEntry(
        message: 'test message',
        level: LogLevel.warning,
        timestamp: ts,
      );

      final str = entry.toString();

      expect(str, contains('[WARNING]'));
      expect(str, contains('test message'));
      expect(str, contains('=>'));
      expect(str, contains('2026-08-17'));
    });

    test('toString() includes full timestamp with all components', () {
      final ts = DateTime.utc(2026, 8, 17, 14, 25, 33, 123);
      final entry = LogEntry(
        message: 'test',
        level: LogLevel.info,
        timestamp: ts,
      );

      final str = entry.toString();

      // Should contain ISO 8601 timestamp with date and time
      expect(str, contains('2026-08-17'));
      expect(str, contains('14:25:33'));
    });

    test('toString() includes exact log level uppercase name', () {
      final ts = DateTime.now();

      for (final level in LogLevel.values) {
        final entry = LogEntry(
          message: 'test',
          level: level,
          timestamp: ts,
        );

        final str = entry.toString();
        final expected = '[${level.toString().toUpperCase()}]';
        expect(str, contains(expected));
      }
    });

    test('toString() includes exact message text', () {
      final messages = [
        'simple message',
        'message with special chars !@#\$%^&*()',
        'multi\nline\nmessage',
        '',
        'very long message ${'x' * 100}',
      ];

      for (final msg in messages) {
        final entry = LogEntry(
          message: msg,
          level: LogLevel.info,
          timestamp: DateTime.now(),
        );

        final str = entry.toString();
        expect(str, contains(msg));
      }
    });

    test('toString() format is consistent: [LEVEL] timestamp => message', () {
      final ts = DateTime.utc(2026, 1, 1, 1, 1, 1);
      final entry = LogEntry(
        message: 'msg',
        level: LogLevel.debug,
        timestamp: ts,
      );

      final str = entry.toString();

      // Parse to verify structure
      expect(str, matches(RegExp(r'\[[A-Z]+\].*=>.*')));
    });

    test('toString() output after field mutations reflects new values', () {
      final ts1 = DateTime.utc(2026, 8, 17, 10, 0, 0);
      final entry = LogEntry(
        message: 'msg1',
        level: LogLevel.info,
        timestamp: ts1,
      );

      var str1 = entry.toString();
      expect(str1, contains('msg1'));
      expect(str1, contains('INFO'));

      entry.message = 'msg2';
      entry.level = LogLevel.error;
      final ts2 = DateTime.utc(2026, 8, 17, 11, 0, 0);
      entry.timestamp = ts2;

      var str2 = entry.toString();
      expect(str2, contains('msg2'));
      expect(str2, isNot(contains('msg1')));
      expect(str2, contains('ERROR'));
      expect(str2, isNot(contains('INFO')));
    });
  });
}
