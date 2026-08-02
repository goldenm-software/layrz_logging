import 'package:flutter/foundation.dart';

/// Helper for capturing debugPrint output in tests.
///
/// [DebugPrintCapture] provides a context manager pattern for temporarily
/// replacing the global [debugPrint] function and capturing all messages
/// emitted during test execution. This is essential for testing console-output
/// logging functionality.
///
/// Usage:
/// ```dart
/// final capture = DebugPrintCapture();
/// capture.start();
/// // ... code that calls debugPrint ...
/// final output = capture.getOutput();
/// capture.stop();
/// ```
class DebugPrintCapture {
  /// Original [debugPrint] function, saved on [start].
  late final void Function(String?, {int? wrapWidth}) _original;

  /// List of all messages captured since [start].
  final List<String> _captured = [];

  /// Start capturing [debugPrint] output.
  ///
  /// Saves the current [debugPrint] and replaces it with a capturing version.
  /// Must be paired with [stop].
  void start() {
    _original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      _captured.add(message ?? '');
    };
  }

  /// Stop capturing and restore the original [debugPrint].
  void stop() {
    debugPrint = _original;
  }

  /// Get all captured messages as a list.
  List<String> getOutput() => List<String>.from(_captured);

  /// Clear the captured messages.
  void clear() => _captured.clear();
}
