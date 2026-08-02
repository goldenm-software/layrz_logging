import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_logging/layrz_logging.dart';

/// Tests for [LogLevel] enum.
///
/// Verifies:
/// - [toString()] returns correct uppercase names
/// - [color] property maps to correct ANSI color codes
/// - [name] property works correctly
/// - All 5 levels exist in expected order
void main() {
  group('LogLevel', () {
    test('toString() returns correct uppercase names', () {
      expect(LogLevel.debug.toString(), 'DEBUG');
      expect(LogLevel.info.toString(), 'INFO');
      expect(LogLevel.warning.toString(), 'WARNING');
      expect(LogLevel.error.toString(), 'ERROR');
      expect(LogLevel.critical.toString(), 'CRITICAL');
    });

    test('color property maps to correct ANSI codes', () {
      expect(LogLevel.debug.color, AnsiColor.cyan);
      expect(LogLevel.info.color, AnsiColor.reset);
      expect(LogLevel.warning.color, AnsiColor.yellow);
      expect(LogLevel.error.color, AnsiColor.red);
      expect(LogLevel.critical.color, AnsiColor.magenta);
    });

    test('color property contains expected ANSI escape sequences', () {
      expect(LogLevel.debug.color, '\x1B[36m');
      expect(LogLevel.info.color, '\x1B[0m');
      expect(LogLevel.warning.color, '\x1B[33m');
      expect(LogLevel.error.color, '\x1B[31m');
      expect(LogLevel.critical.color, '\x1B[35m');
    });

    test('name property returns lowercase names', () {
      expect(LogLevel.debug.name, 'debug');
      expect(LogLevel.info.name, 'info');
      expect(LogLevel.warning.name, 'warning');
      expect(LogLevel.error.name, 'error');
      expect(LogLevel.critical.name, 'critical');
    });

    test('LogLevel.values has exactly 5 entries in expected order', () {
      expect(LogLevel.values.length, 5);
      expect(LogLevel.values[0], LogLevel.debug);
      expect(LogLevel.values[1], LogLevel.info);
      expect(LogLevel.values[2], LogLevel.warning);
      expect(LogLevel.values[3], LogLevel.error);
      expect(LogLevel.values[4], LogLevel.critical);
    });
  });
}
