import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_logging/layrz_logging.dart';
import 'helpers/capture_debug_print.dart';

/// Tests for [Log] console output and ANSI color formatting.
///
/// Verifies:
/// - Each log level method produces correct formatted output with ANSI colors
/// - Output format is: `${color}[LEVEL] message${reset}`
/// - Generic [Log.log()] method produces same output for all levels
/// - Empty and multi-line messages are handled correctly
void main() {
  late DebugPrintCapture capture;

  setUp(() {
    capture = DebugPrintCapture();
    capture.start();
    Log.logs.clear();
  });

  tearDown(() {
    capture.stop();
  });

  group('Log.debug()', () {
    test('emits message with cyan color and reset code', () {
      Log.debug('debug message');

      final output = capture.getOutput();
      expect(output.length, 1);
      expect(
        output[0],
        '${AnsiColor.cyan}[DEBUG] debug message${AnsiColor.reset}',
      );
    });

    test('emits message with exact ANSI escape sequences', () {
      Log.debug('test');

      final output = capture.getOutput();
      expect(output[0], '\x1B[36m[DEBUG] test\x1B[0m');
    });
  });

  group('Log.info()', () {
    test('emits message with reset color and reset code', () {
      Log.info('info message');

      final output = capture.getOutput();
      expect(output.length, 1);
      expect(
        output[0],
        '${AnsiColor.reset}[INFO] info message${AnsiColor.reset}',
      );
    });

    test('emits message with exact ANSI escape sequences', () {
      Log.info('test');

      final output = capture.getOutput();
      expect(output[0], '\x1B[0m[INFO] test\x1B[0m');
    });
  });

  group('Log.warning()', () {
    test('emits message with yellow color and reset code', () {
      Log.warning('warning message');

      final output = capture.getOutput();
      expect(output.length, 1);
      expect(
        output[0],
        '${AnsiColor.yellow}[WARNING] warning message${AnsiColor.reset}',
      );
    });

    test('emits message with exact ANSI escape sequences', () {
      Log.warning('test');

      final output = capture.getOutput();
      expect(output[0], '\x1B[33m[WARNING] test\x1B[0m');
    });
  });

  group('Log.error()', () {
    test('emits message with red color and reset code', () {
      Log.error('error message');

      final output = capture.getOutput();
      expect(output.length, 1);
      expect(
        output[0],
        '${AnsiColor.red}[ERROR] error message${AnsiColor.reset}',
      );
    });

    test('emits message with exact ANSI escape sequences', () {
      Log.error('test');

      final output = capture.getOutput();
      expect(output[0], '\x1B[31m[ERROR] test\x1B[0m');
    });
  });

  group('Log.critical()', () {
    test('emits message with magenta color and reset code', () {
      Log.critical('critical message');

      final output = capture.getOutput();
      expect(output.length, 1);
      expect(
        output[0],
        '${AnsiColor.magenta}[CRITICAL] critical message${AnsiColor.reset}',
      );
    });

    test('emits message with exact ANSI escape sequences', () {
      Log.critical('test');

      final output = capture.getOutput();
      expect(output[0], '\x1B[35m[CRITICAL] test\x1B[0m');
    });
  });

  group('Log.log() with explicit level', () {
    test('produces same output as convenience methods for each level', () {
      // Test that generic log() method works the same as convenience wrappers
      for (final level in LogLevel.values) {
        capture.clear();

        Log.log(level: level, message: 'test message');
        final output = capture.getOutput();

        expect(output.length, 1);
        expect(
          output[0],
          '${level.color}[$level] test message${AnsiColor.reset}',
        );
      }
    });
  });

  group('Output format correctness', () {
    test('each emitted line starts with level color and ends with reset', () {
      Log.debug('debug');
      Log.info('info');
      Log.warning('warning');
      Log.error('error');
      Log.critical('critical');

      final output = capture.getOutput();
      expect(output.length, 5);

      for (final line in output) {
        expect(line.startsWith('\x1B['), true, reason: 'should start with ANSI code');
        expect(line.endsWith('\x1B[0m'), true, reason: 'should end with reset code');
      }
    });

    test('output contains exactly one line per log call', () {
      Log.debug('first');
      Log.info('second');
      Log.warning('third');

      final output = capture.getOutput();
      expect(output.length, 3);
    });
  });

  group('Edge cases', () {
    test('handles empty message', () {
      Log.debug('');

      final output = capture.getOutput();
      expect(output.length, 1);
      expect(output[0], '${AnsiColor.cyan}[DEBUG] ${AnsiColor.reset}');
    });

    test('handles multi-line message (preserves newlines as-is)', () {
      Log.warning('line1\nline2');

      final output = capture.getOutput();
      expect(output.length, 1);
      expect(
        output[0],
        '${AnsiColor.yellow}[WARNING] line1\nline2${AnsiColor.reset}',
      );
    });

    test('handles message with special characters', () {
      Log.info(r'special: !@#$%^&*()');

      final output = capture.getOutput();
      expect(output.length, 1);
      expect(
        output[0],
        '${AnsiColor.reset}[INFO] special: !@#\$%^&*()${AnsiColor.reset}',
      );
    });

    test('handles very long message', () {
      final longMessage = 'a' * 1000;
      Log.error(longMessage);

      final output = capture.getOutput();
      expect(output.length, 1);
      expect(
        output[0],
        '${AnsiColor.red}[ERROR] $longMessage${AnsiColor.reset}',
      );
    });
  });
}
