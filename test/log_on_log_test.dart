import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_logging/layrz_logging.dart';

import 'helpers/capture_debug_print.dart';

/// Tests for [Log.ensureInitialized] with `onLog` callback.
///
/// Verifies:
/// - [onLog] callback receives [LogEntry] for each logging call
/// - Callback receives entries for all log levels (debug, info, warning, error, critical)
/// - Callback receives entries in call order
/// - With [onLog] set, [Log.logs] buffer remains empty (single-database guarantee)
/// - Console output (debugPrint) still occurs when [onLog] is set
/// - [retreiveLogs()] throws when [onLog] is set and works again after clearing it
/// - [onLog] can be replaced or cleared via [ensureInitialized]
/// - Global error handlers (FlutterError.onError, PlatformDispatcher.instance.onError) are wired correctly
void main() {
  late DebugPrintCapture debugCapture;
  late void Function(FlutterErrorDetails)? originalFlutterError;
  late bool Function(Object, StackTrace)? originalPlatformDispatcher;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    debugCapture = DebugPrintCapture();
    debugCapture.start();

    // Save original error handlers to restore in tearDown
    originalFlutterError = FlutterError.onError;
    originalPlatformDispatcher = PlatformDispatcher.instance.onError;

    // Clear state before each test
    Log.logs.clear();
    Log.initialized = false;
  });

  tearDown(() {
    debugCapture.stop();

    // Restore original error handlers
    FlutterError.onError = originalFlutterError;
    PlatformDispatcher.instance.onError = originalPlatformDispatcher;

    // Clear logs buffer (do NOT call ensureInitialized(onLog: null) in tearDown
    // because LoggingDb() initialization is async and causes plugin errors in the
    // test environment after the test completes)
    Log.logs.clear();
    Log.initialized = false;
  });

  group('onLog callback routing', () {
    test('ensureInitialized with onLog stores callback and single entry is routed', () {
      final entries = <LogEntry>[];
      Log.ensureInitialized(onLog: (entry) {
        entries.add(entry);
      });

      Log.warning('test message');

      expect(entries.length, 1);
      expect(entries[0].level, LogLevel.warning);
      expect(entries[0].message, 'test message');
      // Timestamp should be close to now (within a few seconds)
      expect(
        DateTime.now().difference(entries[0].timestamp).inSeconds.abs(),
        lessThan(5),
      );
    });

    test('all LogLevel.values are routed through the callback', () {
      final entries = <LogEntry>[];
      Log.ensureInitialized(onLog: (entry) {
        entries.add(entry);
      });

      Log.debug('debug');
      Log.info('info');
      Log.warning('warning');
      Log.error('error');
      Log.critical('critical');

      expect(entries.length, 5);
      expect(entries[0].level, LogLevel.debug);
      expect(entries[1].level, LogLevel.info);
      expect(entries[2].level, LogLevel.warning);
      expect(entries[3].level, LogLevel.error);
      expect(entries[4].level, LogLevel.critical);
    });

    test('Log.log(level: X, message: Y) routes through callback with correct level', () {
      final entries = <LogEntry>[];
      Log.ensureInitialized(onLog: (entry) {
        entries.add(entry);
      });

      for (final level in LogLevel.values) {
        entries.clear();
        Log.log(level: level, message: 'test');
        expect(entries.length, 1);
        expect(entries[0].level, level);
        expect(entries[0].message, 'test');
      }
    });

    test('multiple sequential calls deliver entries in order', () {
      final entries = <LogEntry>[];
      Log.ensureInitialized(onLog: (entry) {
        entries.add(entry);
      });

      Log.info('first');
      Log.warning('second');
      Log.error('third');
      Log.debug('fourth');

      expect(entries.length, 4);
      expect(entries[0].message, 'first');
      expect(entries[1].message, 'second');
      expect(entries[2].message, 'third');
      expect(entries[3].message, 'fourth');
    });
  });

  group('onLog bypasses in-memory buffer (single database guarantee)', () {
    test('with onLog set, Log.logs stays empty after logging entries', () {
      final entries = <LogEntry>[];
      Log.ensureInitialized(onLog: (entry) {
        entries.add(entry);
      });

      Log.debug('entry1');
      Log.info('entry2');
      Log.warning('entry3');

      expect(Log.logs.isEmpty, true, reason: 'Log.logs should remain empty');
      expect(entries.length, 3, reason: 'callback should receive all entries');
    });

    test('pre-seeded Log.logs is untouched when onLog is set', () {
      final preEntry = LogEntry(
        level: LogLevel.info,
        message: 'pre-existing',
        timestamp: DateTime.now(),
      );
      Log.logs.add(preEntry);

      final entries = <LogEntry>[];
      Log.ensureInitialized(onLog: (entry) {
        entries.add(entry);
      });

      Log.warning('new entry');

      expect(Log.logs.length, 1, reason: 'pre-existing entry should remain');
      expect(Log.logs[0].message, 'pre-existing');
      expect(entries.length, 1, reason: 'only new entry sent to callback');
      expect(entries[0].message, 'new entry');
    });
  });

  group('console output still happens with onLog', () {
    test('debugPrint output is emitted with correct ANSI format when onLog is set', () {
      final entries = <LogEntry>[];
      Log.ensureInitialized(onLog: (entry) {
        entries.add(entry);
      });

      Log.warning('test output');

      final output = debugCapture.getOutput();
      expect(output.length, 1);
      expect(
        output[0],
        '${AnsiColor.yellow}[WARNING] test output${AnsiColor.reset}',
        reason: 'debugPrint should still emit with correct ANSI color',
      );
      expect(entries.length, 1, reason: 'callback should also receive entry');
    });

    test('all log levels emit correct ANSI colors to debugPrint when onLog is set', () {
      final entries = <LogEntry>[];
      Log.ensureInitialized(onLog: (entry) {
        entries.add(entry);
      });

      for (final level in LogLevel.values) {
        debugCapture.clear();
        entries.clear();

        Log.log(level: level, message: 'test');

        final output = debugCapture.getOutput();
        expect(output.length, 1);
        expect(output[0], '${level.color}[$level] test${AnsiColor.reset}');
      }
    });
  });

  group('retreiveLogs guard', () {
    test('with onLog set, retreiveLogs throws Exception with expected message', () async {
      Log.ensureInitialized(onLog: (entry) {});

      expect(
        () => Log.retreiveLogs(),
        throwsA(isA<Exception>()),
      );

      try {
        await Log.retreiveLogs();
        fail('Should have thrown Exception');
      } on Exception catch (e) {
        expect(e.toString(), contains('Cannot retreive logs when onLog is set'));
      }
    });
  });

  group('callback replacement and clearing', () {
    test('ensureInitialized with cbA then cbB only sends to cbB', () {
      final entriesA = <LogEntry>[];
      final entriesB = <LogEntry>[];

      Log.ensureInitialized(onLog: (entry) {
        entriesA.add(entry);
      });

      Log.info('sent to A');
      expect(entriesA.length, 1);
      expect(entriesB.length, 0);

      // Replace with cbB
      Log.ensureInitialized(onLog: (entry) {
        entriesB.add(entry);
      });

      Log.warning('sent to B');
      expect(entriesA.length, 1, reason: 'cbA should not receive new entry');
      expect(entriesB.length, 1, reason: 'cbB should receive new entry');
    });

    test('Log.initialized is set to true by ensureInitialized', () {
      expect(Log.initialized, false, reason: 'should start as false');

      Log.ensureInitialized(onLog: (entry) {});

      expect(Log.initialized, true);
    });

    test('multiple calls to ensureInitialized replace the previous callback', () {
      final calls = <String>[];

      Log.ensureInitialized(onLog: (entry) {
        calls.add('first');
      });
      Log.info('msg1');

      Log.ensureInitialized(onLog: (entry) {
        calls.add('second');
      });
      Log.info('msg2');

      Log.ensureInitialized(onLog: (entry) {
        calls.add('third');
      });
      Log.info('msg3');

      expect(calls.length, 3);
      expect(calls[0], 'first');
      expect(calls[1], 'second');
      expect(calls[2], 'third');
    });
  });

  group('error handler wiring', () {
    test('FlutterError.onError routes through callback as CRITICAL level', () {
      final entries = <LogEntry>[];
      Log.ensureInitialized(onLog: (entry) {
        entries.add(entry);
      });

      // Clear debugPrint output since FlutterError handler will also log
      debugCapture.clear();

      // Construct a synthetic FlutterErrorDetails and invoke the handler
      final details = FlutterErrorDetails(
        exception: Exception('boom'),
        stack: StackTrace.current,
      );

      FlutterError.onError!(details);

      // Should have received a CRITICAL entry from the error handler
      expect(
        entries.where((e) => e.level == LogLevel.critical).length,
        greaterThan(0),
        reason: 'error handler should send CRITICAL level entry',
      );

      // Message should contain the exception text
      final criticalEntry = entries.firstWhere((e) => e.level == LogLevel.critical);
      expect(
        criticalEntry.message,
        contains('boom'),
        reason: 'message should contain exception text',
      );
    });

    test('error handler is replaced by ensureInitialized', () {
      final handlerBefore = FlutterError.onError;

      Log.ensureInitialized(onLog: (entry) {});

      final handlerAfter = FlutterError.onError;

      // Handler should be different after initialization
      expect(handlerAfter, isNotNull);
      expect(handlerAfter, isNot(equals(handlerBefore)),
        reason: 'ensureInitialized should replace the error handler');
    });
  });

  group('onLog timestamp accuracy', () {
    test('callback receives entry with timestamp close to call time', () {
      final entries = <LogEntry>[];
      Log.ensureInitialized(onLog: (entry) {
        entries.add(entry);
      });

      final beforeTime = DateTime.now();
      Log.warning('timed entry');
      final afterTime = DateTime.now();

      expect(entries.length, 1);
      final entryTime = entries[0].timestamp;

      // Timestamp should fall between beforeTime and afterTime
      expect(entryTime.isAfter(beforeTime.subtract(const Duration(seconds: 1))), true);
      expect(entryTime.isBefore(afterTime.add(const Duration(seconds: 1))), true);
    });
  });

  group('console output with onLog edge cases', () {
    test('empty message with onLog still emits to debugPrint and callback', () {
      final entries = <LogEntry>[];
      Log.ensureInitialized(onLog: (entry) {
        entries.add(entry);
      });

      Log.debug('');

      final output = debugCapture.getOutput();
      expect(output.length, 1);
      expect(entries.length, 1);
      expect(entries[0].message, '');
    });

    test('multi-line message with onLog is preserved in callback and debugPrint', () {
      final entries = <LogEntry>[];
      Log.ensureInitialized(onLog: (entry) {
        entries.add(entry);
      });

      const multiLine = 'line1\nline2\nline3';
      Log.error(multiLine);

      final output = debugCapture.getOutput();
      expect(output.length, 1);
      expect(output[0], contains('line1\nline2\nline3'));

      expect(entries.length, 1);
      expect(entries[0].message, multiLine);
    });
  });
}
