import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_logging/layrz_logging.dart';

/// Tests for [Log.humanizeMicroseconds].
///
/// Verifies conversion of microseconds to human-readable format with boundaries:
/// - < 1,000 μs: "NNNμs"
/// - >= 1,000, < 1,000,000 μs: "NNNms" (milliseconds)
/// - >= 1,000,000, < 60,000,000 μs: "NNNs" (seconds)
/// - >= 60,000,000 μs: "NNNm" (minutes)
///
/// NOTE: The docstring mentions "1500 -> '1ms'" but the actual algorithm
/// truncates via integer division (~/ 1000), not rounding. So:
/// - 1500 μs → divide by 1000 → 1 ms (matches doc)
/// - 999_999 μs → divide by 1000 → 999 ms
/// - 1_000_000 μs → divide by 1000 → 1000 ms → divide by 1000 again → 1 s
void main() {
  group('humanizeMicroseconds', () {
    group('microseconds range (< 1_000 μs)', () {
      test('500 microseconds returns "500μs"', () {
        expect(Log.humanizeMicroseconds(500), '500μs');
      });

      test('999 microseconds returns "999μs"', () {
        expect(Log.humanizeMicroseconds(999), '999μs');
      });

      test('1 microsecond returns "1μs"', () {
        expect(Log.humanizeMicroseconds(1), '1μs');
      });

      test('0 microseconds returns "0μs"', () {
        expect(Log.humanizeMicroseconds(0), '0μs');
      });
    });

    group('milliseconds range (1_000 to 999_999 μs)', () {
      test('1_000 microseconds returns "1ms"', () {
        expect(Log.humanizeMicroseconds(1_000), '1ms');
      });

      test('1_500 microseconds returns "1ms" (truncates via integer division)', () {
        expect(Log.humanizeMicroseconds(1_500), '1ms');
      });

      test('5_000 microseconds returns "5ms"', () {
        expect(Log.humanizeMicroseconds(5_000), '5ms');
      });

      test('999_000 microseconds returns "999ms"', () {
        expect(Log.humanizeMicroseconds(999_000), '999ms');
      });

      test('999_999 microseconds returns "999ms"', () {
        expect(Log.humanizeMicroseconds(999_999), '999ms');
      });
    });

    group('seconds range (1_000_000 to 59_999_999 μs)', () {
      test('1_000_000 microseconds returns "1s"', () {
        expect(Log.humanizeMicroseconds(1_000_000), '1s');
      });

      test('5_000_000 microseconds returns "5s"', () {
        expect(Log.humanizeMicroseconds(5_000_000), '5s');
      });

      test('30_000_000 microseconds returns "30s"', () {
        expect(Log.humanizeMicroseconds(30_000_000), '30s');
      });

      test('59_000_000 microseconds returns "59s"', () {
        expect(Log.humanizeMicroseconds(59_000_000), '59s');
      });

      test('59_999_999 microseconds returns "59s"', () {
        expect(Log.humanizeMicroseconds(59_999_999), '59s');
      });
    });

    group('minutes range (>= 60_000_000 μs)', () {
      test('60_000_000 microseconds returns "1m"', () {
        expect(Log.humanizeMicroseconds(60_000_000), '1m');
      });

      test('120_000_000 microseconds returns "2m"', () {
        expect(Log.humanizeMicroseconds(120_000_000), '2m');
      });

      test('300_000_000 microseconds returns "5m"', () {
        expect(Log.humanizeMicroseconds(300_000_000), '5m');
      });

      test('3_600_000_000 microseconds returns "60m" (1 hour)', () {
        expect(Log.humanizeMicroseconds(3_600_000_000), '60m');
      });

      test('7_200_000_000 microseconds returns "120m" (2 hours)', () {
        expect(Log.humanizeMicroseconds(7_200_000_000), '120m');
      });
    });

    group('boundary and edge cases', () {
      test('boundary at 999 → 1000 μs transitions from μs to ms', () {
        expect(Log.humanizeMicroseconds(999), '999μs');
        expect(Log.humanizeMicroseconds(1_000), '1ms');
      });

      test('boundary at 999_999 → 1_000_000 μs transitions from ms to s', () {
        expect(Log.humanizeMicroseconds(999_999), '999ms');
        expect(Log.humanizeMicroseconds(1_000_000), '1s');
      });

      test('boundary at 59_999_999 → 60_000_000 μs transitions from s to m', () {
        expect(Log.humanizeMicroseconds(59_999_999), '59s');
        expect(Log.humanizeMicroseconds(60_000_000), '1m');
      });

      test('very large values (many minutes)', () {
        // 24 hours = 86400 minutes
        expect(Log.humanizeMicroseconds(86_400 * 60 * 1_000_000), '86400m');
      });
    });

    group('consistency', () {
      test('same input always produces same output', () {
        final input = 12_345_678;
        final output1 = Log.humanizeMicroseconds(input);
        final output2 = Log.humanizeMicroseconds(input);

        expect(output1, output2);
      });

      test('output always ends with correct suffix', () {
        final testCases = [
          (500, 'μs'),
          (1_500, 'ms'),
          (5_000_000, 's'),
          (120_000_000, 'm'),
        ];

        for (final (input, expectedSuffix) in testCases) {
          final output = Log.humanizeMicroseconds(input);
          expect(output.endsWith(expectedSuffix), true, reason: 'output "$output" should end with "$expectedSuffix"');
        }
      });
    });
  });
}
