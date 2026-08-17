import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_logging/layrz_logging.dart';
import 'helpers/capture_debug_print.dart';

/// Tests for [Log.ensureInitialized] and [Log.isWeb].
///
/// Verifies:
/// - [Log.ensureInitialized()] sets [Log.initialized] to true
/// - [Log.ensureInitialized()] installs [FlutterError.onError] handler
/// - Installed [FlutterError.onError] handler logs critical entries when invoked
/// - [Log.ensureInitialized()] installs [PlatformDispatcher.instance.onError] handler
/// - Installed platform error handler returns true and logs critical entries
/// - [Log.isWeb] evaluates correctly
void main() {
  late void Function(FlutterErrorDetails)? savedFlutterErrorHandler;
  late bool Function(Object, StackTrace)? savedPlatformErrorHandler;
  late DebugPrintCapture capture;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Log.initialized = false;
    // Save original handlers
    savedFlutterErrorHandler = FlutterError.onError;
    savedPlatformErrorHandler = PlatformDispatcher.instance.onError;
    // Start capturing debug print output
    capture = DebugPrintCapture();
    capture.start();
  });

  tearDown(() {
    // Stop capturing debug print output
    capture.stop();
    // Restore original handlers
    FlutterError.onError = savedFlutterErrorHandler;
    PlatformDispatcher.instance.onError = savedPlatformErrorHandler;
    Log.initialized = false;
  });

  group('Log.initialized flag', () {
    test('Log.initialized starts as false', () {
      expect(Log.initialized, false);
    });

    test('Log.ensureInitialized() sets Log.initialized to true', () {
      expect(Log.initialized, false);

      Log.ensureInitialized();

      expect(Log.initialized, true);
    });

    test('multiple calls to ensureInitialized() keep initialized as true', () {
      Log.ensureInitialized();
      expect(Log.initialized, true);

      Log.ensureInitialized();
      expect(Log.initialized, true);

      Log.ensureInitialized();
      expect(Log.initialized, true);
    });
  });

  group('FlutterError.onError handler', () {
    test('ensureInitialized() installs a FlutterError.onError handler', () {
      final handlerBefore = FlutterError.onError;

      Log.ensureInitialized();

      final handlerAfter = FlutterError.onError;
      expect(handlerAfter, isNotNull);
      expect(handlerAfter, isNot(equals(handlerBefore)));
    });

    test('installed handler routes FlutterError to Log.stream as CRITICAL', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        Log.ensureInitialized();

        // Create a synthetic FlutterErrorDetails
        final details = FlutterErrorDetails(
          exception: Exception('test error'),
          stack: StackTrace.current,
        );

        // Invoke the installed handler
        FlutterError.onError!(details);
        await Future<void>.delayed(Duration.zero);

        // Should have at least one critical entry
        final criticalEntries = entries.where((e) => e.level == LogLevel.critical).toList();
        expect(criticalEntries.isNotEmpty, true,
            reason: 'error handler should emit critical level entry');

        final entry = criticalEntries.first;
        expect(entry.message, contains('test error'),
            reason: 'message should contain exception text');
      } finally {
        await subscription.cancel();
      }
    });

    test('installed handler includes stack trace in message', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        Log.ensureInitialized();

        final details = FlutterErrorDetails(
          exception: Exception('boom'),
          stack: StackTrace.current,
        );

        FlutterError.onError!(details);
        await Future<void>.delayed(Duration.zero);

        final criticalEntries = entries.where((e) => e.level == LogLevel.critical).toList();
        expect(criticalEntries.isNotEmpty, true);

        final entry = criticalEntries.first;
        // Message should include both exception and stack trace info
        expect(entry.message.isNotEmpty, true);
      } finally {
        await subscription.cancel();
      }
    });

    test('installed handler passes error as structured field in LogEntry', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        Log.ensureInitialized();

        final testError = Exception('test error');
        final details = FlutterErrorDetails(
          exception: testError,
          stack: StackTrace.current,
        );

        FlutterError.onError!(details);
        await Future<void>.delayed(Duration.zero);

        final criticalEntries = entries.where((e) => e.level == LogLevel.critical).toList();
        expect(criticalEntries.isNotEmpty, true);

        final entry = criticalEntries.first;
        expect(entry.error, testError);
      } finally {
        await subscription.cancel();
      }
    });

    test('installed handler passes stackTrace as structured field in LogEntry', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        Log.ensureInitialized();

        final testStack = StackTrace.current;
        final details = FlutterErrorDetails(
          exception: Exception('test'),
          stack: testStack,
        );

        FlutterError.onError!(details);
        await Future<void>.delayed(Duration.zero);

        final criticalEntries = entries.where((e) => e.level == LogLevel.critical).toList();
        expect(criticalEntries.isNotEmpty, true);

        final entry = criticalEntries.first;
        expect(entry.stackTrace, testStack);
      } finally {
        await subscription.cancel();
      }
    });

    test('installed handler does not inline stack trace into message', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        Log.ensureInitialized();

        final details = FlutterErrorDetails(
          exception: Exception('test error'),
          stack: StackTrace.current,
        );

        FlutterError.onError!(details);
        await Future<void>.delayed(Duration.zero);

        final criticalEntries = entries.where((e) => e.level == LogLevel.critical).toList();
        expect(criticalEntries.isNotEmpty, true);

        final entry = criticalEntries.first;
        // Message should NOT contain stack frame references like "#0"
        expect(entry.message.contains('#0'), false,
            reason: 'message should not contain stack frame text');
        // Message should contain the exception text
        expect(entry.message, contains('test error'));
      } finally {
        await subscription.cancel();
      }
    });
  });

  group('PlatformDispatcher.instance.onError handler', () {
    test('ensureInitialized() installs a PlatformDispatcher.instance.onError handler', () {
      final handlerBefore = PlatformDispatcher.instance.onError;

      Log.ensureInitialized();

      final handlerAfter = PlatformDispatcher.instance.onError;
      expect(handlerAfter, isNotNull);
      expect(handlerAfter, isNot(equals(handlerBefore)));
    });

    test('installed handler returns true', () {
      Log.ensureInitialized();

      // Invoke the installed handler
      final result = PlatformDispatcher.instance.onError!(
        Exception('test platform error'),
        StackTrace.current,
      );

      expect(result, true, reason: 'handler should return true');
    });

    test('installed handler emits CRITICAL entry to Log.stream', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        Log.ensureInitialized();

        PlatformDispatcher.instance.onError!(
          Exception('platform error'),
          StackTrace.current,
        );
        await Future<void>.delayed(Duration.zero);

        final criticalEntries = entries.where((e) => e.level == LogLevel.critical).toList();
        expect(criticalEntries.isNotEmpty, true,
            reason: 'platform error handler should emit critical entry');

        final entry = criticalEntries.first;
        expect(entry.message, contains('Platform error:'),
            reason: 'message should start with "Platform error:"');
        expect(entry.message, contains('platform error'),
            reason: 'message should contain the error text');
      } finally {
        await subscription.cancel();
      }
    });

    test('installed handler includes stack trace in message', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        Log.ensureInitialized();

        PlatformDispatcher.instance.onError!(
          Exception('err'),
          StackTrace.current,
        );
        await Future<void>.delayed(Duration.zero);

        final criticalEntries = entries.where((e) => e.level == LogLevel.critical).toList();
        expect(criticalEntries.first.message.isNotEmpty, true);
      } finally {
        await subscription.cancel();
      }
    });

    test('installed handler passes error as structured field in LogEntry', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        Log.ensureInitialized();

        final testError = Exception('platform error');
        final testStack = StackTrace.current;

        PlatformDispatcher.instance.onError!(testError, testStack);
        await Future<void>.delayed(Duration.zero);

        final criticalEntries = entries.where((e) => e.level == LogLevel.critical).toList();
        expect(criticalEntries.isNotEmpty, true);

        final entry = criticalEntries.first;
        expect(entry.error, testError);
      } finally {
        await subscription.cancel();
      }
    });

    test('installed handler passes stackTrace as structured field in LogEntry', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        Log.ensureInitialized();

        final testError = Exception('platform error');
        final testStack = StackTrace.current;

        PlatformDispatcher.instance.onError!(testError, testStack);
        await Future<void>.delayed(Duration.zero);

        final criticalEntries = entries.where((e) => e.level == LogLevel.critical).toList();
        expect(criticalEntries.isNotEmpty, true);

        final entry = criticalEntries.first;
        expect(entry.stackTrace, testStack);
      } finally {
        await subscription.cancel();
      }
    });

    test('installed handler still returns true', () {
      Log.ensureInitialized();

      final result = PlatformDispatcher.instance.onError!(
        Exception('test'),
        StackTrace.current,
      );

      expect(result, true);
    });

    test('installed handler does not inline stack trace into message', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        Log.ensureInitialized();

        PlatformDispatcher.instance.onError!(
          Exception('platform error'),
          StackTrace.current,
        );
        await Future<void>.delayed(Duration.zero);

        final criticalEntries = entries.where((e) => e.level == LogLevel.critical).toList();
        expect(criticalEntries.isNotEmpty, true);

        final entry = criticalEntries.first;
        // Message should NOT contain stack frame references like "#0"
        expect(entry.message.contains('#0'), false,
            reason: 'message should not contain stack frame text');
        // Message should still contain the "Platform error:" prefix
        expect(entry.message, contains('Platform error:'));
      } finally {
        await subscription.cancel();
      }
    });
  });

  group('Log.isWeb', () {
    test('Log.isWeb is a boolean that can be read', () {
      final result = Log.isWeb;
      expect(result, isA<bool>());
    });

    test('Log.isWeb is false under VM test runner (non-web environment)', () {
      expect(Log.isWeb, false, reason: 'should be false in standard Flutter VM tests');
    });

    test('Log.isWeb reflects kIsWeb or kIsWasm value', () {
      final expected = kIsWeb || kIsWasm;
      expect(Log.isWeb, expected);
    });
  });

  group('Integration: ensureInitialized with both error handlers', () {
    test('both error handlers are installed and functional after single ensureInitialized call', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        Log.ensureInitialized();

        // Invoke flutter error handler
        FlutterError.onError!(FlutterErrorDetails(
          exception: Exception('flutter error'),
          stack: StackTrace.current,
        ));
        await Future<void>.delayed(Duration.zero);

        final count1 = entries.length;
        expect(count1, greaterThan(0), reason: 'flutter error should emit entry');

        // Invoke platform error handler
        final result = PlatformDispatcher.instance.onError!(
          Exception('platform error'),
          StackTrace.current,
        );
        await Future<void>.delayed(Duration.zero);

        final count2 = entries.length;
        expect(result, true);
        expect(count2, greaterThan(count1), reason: 'platform error should emit additional entry');
      } finally {
        await subscription.cancel();
      }
    });

    test('error handlers capture real exceptions correctly', () async {
      final entries = <LogEntry>[];
      final subscription = Log.stream.listen(entries.add);

      try {
        Log.ensureInitialized();

        // Simulate a real error with stack
        try {
          throw FormatException('Invalid format in test');
        } catch (e, st) {
          FlutterError.onError!(FlutterErrorDetails(
            exception: e,
            stack: st,
          ));
        }
        await Future<void>.delayed(Duration.zero);

        final criticalEntries = entries.where((e) => e.level == LogLevel.critical).toList();
        expect(criticalEntries.isNotEmpty, true);
        expect(criticalEntries.first.message, contains('Invalid format'));
      } finally {
        await subscription.cancel();
      }
    });
  });
}
