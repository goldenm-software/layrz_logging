import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_logging/layrz_logging.dart';
import 'helpers/capture_debug_print.dart';

/// Tests for [Log.stream] broadcast stream behavior.
///
/// Verifies:
/// - Each of [Log.debug/info/warning/error/critical] emits one [LogEntry] with correct [LogLevel] and message
/// - [Log.log(level:, message:)] emits with the given level/message and timestamp close to now
/// - Broadcast semantics: two concurrent subscribers both receive the same entry
/// - Late subscriber does NOT receive entries emitted before subscription (broadcast, not replay)
/// - Subscriptions can be cancelled without affecting other listeners
void main() {
  late DebugPrintCapture capture;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    capture = DebugPrintCapture();
    capture.start();
  });

  tearDown(() {
    capture.stop();
  });

  group('Log.stream emission on convenience methods', () {
    test('Log.debug() emits one LogEntry with debug level', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        Log.debug('debug message');

        // Let the stream event propagate
        await Future<void>.delayed(Duration.zero);

        expect(entries.length, 1);
        expect(entries[0].level, LogLevel.debug);
        expect(entries[0].message, 'debug message');
      } finally {
        await subscription.cancel();
      }
    });

    test('Log.info() emits one LogEntry with info level', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        Log.info('info message');
        await Future<void>.delayed(Duration.zero);

        expect(entries.length, 1);
        expect(entries[0].level, LogLevel.info);
        expect(entries[0].message, 'info message');
      } finally {
        await subscription.cancel();
      }
    });

    test('Log.warning() emits one LogEntry with warning level', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        Log.warning('warning message');
        await Future<void>.delayed(Duration.zero);

        expect(entries.length, 1);
        expect(entries[0].level, LogLevel.warning);
        expect(entries[0].message, 'warning message');
      } finally {
        await subscription.cancel();
      }
    });

    test('Log.error() emits one LogEntry with error level', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        Log.error('error message');
        await Future<void>.delayed(Duration.zero);

        expect(entries.length, 1);
        expect(entries[0].level, LogLevel.error);
        expect(entries[0].message, 'error message');
      } finally {
        await subscription.cancel();
      }
    });

    test('Log.critical() emits one LogEntry with critical level', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        Log.critical('critical message');
        await Future<void>.delayed(Duration.zero);

        expect(entries.length, 1);
        expect(entries[0].level, LogLevel.critical);
        expect(entries[0].message, 'critical message');
      } finally {
        await subscription.cancel();
      }
    });

    test('Log.debug() forwards error and stackTrace', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        final testError = Exception('debug error');
        final testStack = StackTrace.current;
        Log.debug('debug message', error: testError, stackTrace: testStack);
        await Future<void>.delayed(Duration.zero);

        expect(entries.length, 1);
        expect(entries[0].error, testError);
        expect(entries[0].stackTrace, testStack);
      } finally {
        await subscription.cancel();
      }
    });

    test('Log.info() forwards error and stackTrace', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        final testError = Exception('info error');
        final testStack = StackTrace.current;
        Log.info('info message', error: testError, stackTrace: testStack);
        await Future<void>.delayed(Duration.zero);

        expect(entries.length, 1);
        expect(entries[0].error, testError);
        expect(entries[0].stackTrace, testStack);
      } finally {
        await subscription.cancel();
      }
    });

    test('Log.warning() forwards error and stackTrace', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        final testError = Exception('warning error');
        final testStack = StackTrace.current;
        Log.warning('warning message', error: testError, stackTrace: testStack);
        await Future<void>.delayed(Duration.zero);

        expect(entries.length, 1);
        expect(entries[0].error, testError);
        expect(entries[0].stackTrace, testStack);
      } finally {
        await subscription.cancel();
      }
    });

    test('Log.error() forwards error and stackTrace', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        final testError = Exception('error value');
        final testStack = StackTrace.current;
        Log.error('error message', error: testError, stackTrace: testStack);
        await Future<void>.delayed(Duration.zero);

        expect(entries.length, 1);
        expect(entries[0].error, testError);
        expect(entries[0].stackTrace, testStack);
      } finally {
        await subscription.cancel();
      }
    });

    test('Log.critical() forwards error and stackTrace', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        final testError = Exception('critical error');
        final testStack = StackTrace.current;
        Log.critical('critical message', error: testError, stackTrace: testStack);
        await Future<void>.delayed(Duration.zero);

        expect(entries.length, 1);
        expect(entries[0].error, testError);
        expect(entries[0].stackTrace, testStack);
      } finally {
        await subscription.cancel();
      }
    });
  });

  group('Log.stream emission on Log.log()', () {
    test('Log.log(level:, message:) emits with given level and message', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        Log.log(level: LogLevel.warning, message: 'test message');
        await Future<void>.delayed(Duration.zero);

        expect(entries.length, 1);
        expect(entries[0].level, LogLevel.warning);
        expect(entries[0].message, 'test message');
      } finally {
        await subscription.cancel();
      }
    });

    test('emitted entry has timestamp close to call time', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        final before = DateTime.now();
        Log.log(level: LogLevel.info, message: 'timed');
        final after = DateTime.now();
        await Future<void>.delayed(Duration.zero);

        expect(entries.length, 1);
        final ts = entries[0].timestamp;
        // Timestamp should be within a second of the call
        expect(ts.isAfter(before.subtract(const Duration(seconds: 1))), true);
        expect(ts.isBefore(after.add(const Duration(seconds: 1))), true);
      } finally {
        await subscription.cancel();
      }
    });

    test('all five LogLevel values emit correctly through Log.log()', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        for (final level in LogLevel.values) {
          entries.clear();
          Log.log(level: level, message: 'test');
          await Future<void>.delayed(Duration.zero);

          expect(entries.length, 1);
          expect(entries[0].level, level);
        }
      } finally {
        await subscription.cancel();
      }
    });

    test('Log.log() forwards error to LogEntry', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        final testError = Exception('test error');
        Log.log(level: LogLevel.error, message: 'error message', error: testError);
        await Future<void>.delayed(Duration.zero);

        expect(entries.length, 1);
        expect(entries[0].error, testError);
      } finally {
        await subscription.cancel();
      }
    });

    test('Log.log() forwards stackTrace to LogEntry', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        final testStack = StackTrace.current;
        Log.log(level: LogLevel.error, message: 'error message', stackTrace: testStack);
        await Future<void>.delayed(Duration.zero);

        expect(entries.length, 1);
        expect(entries[0].stackTrace, testStack);
      } finally {
        await subscription.cancel();
      }
    });

    test('Log.log() forwards both error and stackTrace to LogEntry', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        final testError = Exception('test error');
        final testStack = StackTrace.current;
        Log.log(
          level: LogLevel.critical,
          message: 'critical error',
          error: testError,
          stackTrace: testStack,
        );
        await Future<void>.delayed(Duration.zero);

        expect(entries.length, 1);
        expect(entries[0].error, testError);
        expect(entries[0].stackTrace, testStack);
      } finally {
        await subscription.cancel();
      }
    });
  });

  group('Broadcast semantics', () {
    test('two concurrent subscribers both receive the same entry', () async {
      final entries1 = <LogEntry>[];
      final entries2 = <LogEntry>[];
      final sub1 = Log.stream.listen(entries1.add);
      final sub2 = Log.stream.listen(entries2.add);

      try {
        Log.debug('broadcast test');
        await Future<void>.delayed(Duration.zero);

        expect(entries1.length, 1);
        expect(entries2.length, 1);
        expect(entries1[0].message, 'broadcast test');
        expect(entries2[0].message, 'broadcast test');
      } finally {
        await sub1.cancel();
        await sub2.cancel();
      }
    });

    test('three subscribers all receive entries', () async {
      final entries1 = <LogEntry>[];
      final entries2 = <LogEntry>[];
      final entries3 = <LogEntry>[];
      final sub1 = Log.stream.listen(entries1.add);
      final sub2 = Log.stream.listen(entries2.add);
      final sub3 = Log.stream.listen(entries3.add);

      try {
        Log.info('msg1');
        await Future<void>.delayed(Duration.zero);
        Log.warning('msg2');
        await Future<void>.delayed(Duration.zero);

        expect(entries1.length, 2);
        expect(entries2.length, 2);
        expect(entries3.length, 2);
        expect(entries1[0].message, 'msg1');
        expect(entries2[0].message, 'msg1');
        expect(entries3[0].message, 'msg1');
      } finally {
        await sub1.cancel();
        await sub2.cancel();
        await sub3.cancel();
      }
    });
  });

  group('Late subscriber (no replay)', () {
    test('subscriber created after emission does NOT receive prior entry', () async {
      Log.debug('before subscription');
      await Future<void>.delayed(Duration.zero);

      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        await Future<void>.delayed(Duration.zero);
        expect(entries.isEmpty, true, reason: 'late subscriber should not receive prior entries');

        Log.info('after subscription');
        await Future<void>.delayed(Duration.zero);

        expect(entries.length, 1);
        expect(entries[0].message, 'after subscription');
      } finally {
        await subscription.cancel();
      }
    });

    test('subscriber that misses entries sees only future ones', () async {
      Log.debug('missed 1');
      Log.info('missed 2');
      await Future<void>.delayed(Duration.zero);

      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        Log.warning('seen 1');
        Log.error('seen 2');
        await Future<void>.delayed(Duration.zero);

        expect(entries.length, 2);
        expect(entries[0].message, 'seen 1');
        expect(entries[1].message, 'seen 2');
      } finally {
        await subscription.cancel();
      }
    });
  });

  group('Subscription cancellation', () {
    test('cancelled subscription does not receive further entries', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      Log.debug('before cancel');
      await Future<void>.delayed(Duration.zero);
      expect(entries.length, 1);

      await subscription.cancel();

      Log.info('after cancel');
      await Future<void>.delayed(Duration.zero);

      expect(entries.length, 1, reason: 'cancelled subscriber should not receive new entry');
    });

    test('cancelling one subscription does not affect other subscribers', () async {
      final entries1 = <LogEntry>[];
      final entries2 = <LogEntry>[];
      final sub1 = Log.stream.listen(entries1.add);
      final sub2 = Log.stream.listen(entries2.add);

      try {
        Log.debug('msg1');
        await Future<void>.delayed(Duration.zero);
        expect(entries1.length, 1);
        expect(entries2.length, 1);

        await sub1.cancel();

        Log.info('msg2');
        await Future<void>.delayed(Duration.zero);

        expect(entries1.length, 1, reason: 'sub1 should not receive new entry');
        expect(entries2.length, 2, reason: 'sub2 should still receive new entry');
      } finally {
        await sub2.cancel();
      }
    });

    test('multiple subscriptions and cancellations work correctly', () async {
      final entries1 = <LogEntry>[];
      final entries2 = <LogEntry>[];
      final entries3 = <LogEntry>[];

      final sub1 = Log.stream.listen(entries1.add);
      final sub2 = Log.stream.listen(entries2.add);
      final sub3 = Log.stream.listen(entries3.add);

      try {
        Log.debug('initial');
        await Future<void>.delayed(Duration.zero);
        expect([entries1.length, entries2.length, entries3.length], [1, 1, 1]);

        await sub1.cancel();
        Log.info('after sub1 cancel');
        await Future<void>.delayed(Duration.zero);
        expect([entries1.length, entries2.length, entries3.length], [1, 2, 2]);

        await sub2.cancel();
        Log.warning('after sub2 cancel');
        await Future<void>.delayed(Duration.zero);
        expect([entries1.length, entries2.length, entries3.length], [1, 2, 3]);
      } finally {
        await sub3.cancel();
      }
    });
  });

  tearDown(() async {
    // Ensure all pending subscriptions are cleaned up to avoid listener leaks
    // (No active subscriptions should remain after each test)
  });
}
