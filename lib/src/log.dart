import 'dart:async';

import 'package:flutter/foundation.dart';

import 'ansi_colors.dart';
import 'entry.dart';
import 'level.dart';

class Log {
  /// [initialized] is used to ensure that the logging system is initialized only once.
  static bool initialized = false;

  /// [_stream] is a stream that allows users to listen to log events.
  static final StreamController<LogEntry> _stream = StreamController<LogEntry>.broadcast();

  /// [stream] emits every [LogEntry] produced by the logging system.
  ///
  /// Consumers subscribe to this to persist or forward logs; the package itself
  /// does not store anything.
  static Stream<LogEntry> get stream => _stream.stream;

  /// [ensureInitialized] is used to initialize the logging system.
  ///
  /// Installs handlers for [FlutterError.onError] and [PlatformDispatcher.instance.onError]
  /// to capture framework and platform errors and forward them to the logging system.
  static void ensureInitialized() {
    Log.initialized = true;
    FlutterError.onError = (FlutterErrorDetails details) {
      critical(
        details.exceptionAsString(),
        error: details.exception,
        stackTrace: details.stack,
      );
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      critical(
        'Platform error: $error',
        error: error,
        stackTrace: stackTrace,
      );
      return true;
    };
  }

  static bool get isWeb => kIsWeb || kIsWasm;

  /// Emit a debug-level log entry.
  ///
  /// Parameters:
  /// - [message]: The log message text.
  /// - [error]: Optional error object to associate with the log.
  /// - [stackTrace]: Optional stack trace to associate with the log.
  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    log(level: .debug, message: message, error: error, stackTrace: stackTrace);
  }

  /// Emit an info-level log entry.
  ///
  /// Parameters:
  /// - [message]: The log message text.
  /// - [error]: Optional error object to associate with the log.
  /// - [stackTrace]: Optional stack trace to associate with the log.
  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    log(level: .info, message: message, error: error, stackTrace: stackTrace);
  }

  /// Emit a warning-level log entry.
  ///
  /// Parameters:
  /// - [message]: The log message text.
  /// - [error]: Optional error object to associate with the log.
  /// - [stackTrace]: Optional stack trace to associate with the log.
  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    log(level: .warning, message: message, error: error, stackTrace: stackTrace);
  }

  /// Emit an error-level log entry.
  ///
  /// Parameters:
  /// - [message]: The log message text.
  /// - [error]: Optional error object to associate with the log.
  /// - [stackTrace]: Optional stack trace to associate with the log.
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    log(level: .error, message: message, error: error, stackTrace: stackTrace);
  }

  /// Emit a critical-level log entry.
  ///
  /// Parameters:
  /// - [message]: The log message text.
  /// - [error]: Optional error object to associate with the log.
  /// - [stackTrace]: Optional stack trace to associate with the log.
  static void critical(String message, {Object? error, StackTrace? stackTrace}) {
    log(level: .critical, message: message, error: error, stackTrace: stackTrace);
  }

  /// Emit a log entry with the specified level.
  ///
  /// Parameters:
  /// - [level]: The log level (debug, info, warning, error, critical).
  /// - [message]: The log message text.
  /// - [error]: Optional error object to associate with the log.
  /// - [stackTrace]: Optional stack trace to associate with the log.
  ///
  /// In debug mode or on web, also emits the message to [debugPrint] with ANSI colors.
  /// Error and stack trace are emitted as separate debug print lines if present.
  static void log({
    required LogLevel level,
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode || isWeb) _emitToConsole(level, message, error, stackTrace);

    final logEntry = LogEntry(
      level: level,
      message: message,
      timestamp: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );

    _stream.add(logEntry);
  }

  /// [_emitToConsole] writes [message] to the console, followed by [error] and
  /// [stackTrace] on their own lines when present.
  ///
  /// The `kDebugMode || isWeb` guard lives at the call site because both operands
  /// are compile-time constants; keeping the guard on the same line as this call
  /// ensures the branch is attributable in coverage output.
  static void _emitToConsole(
    LogLevel level,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    debugPrint("${level.color}[$level] $message${AnsiColor.reset}");

    if (error != null) {
      debugPrint("${level.color}Error: $error${AnsiColor.reset}");
    }

    if (stackTrace != null) {
      debugPrint("${level.color}$stackTrace${AnsiColor.reset}");
    }
  }

  /// [humanizeMicroseconds] is used to convert microseconds to a human-readable format.
  ///
  /// Examples:
  /// - 500 -> "500μs"
  /// - 1500 -> "1ms"
  static String humanizeMicroseconds(int elapsed) {
    if (elapsed < 1_000) {
      return '$elapsedμs';
    }
    elapsed = elapsed ~/ 1_000;
    if (elapsed < 1_000) {
      return '${elapsed}ms';
    }

    elapsed = elapsed ~/ 1_000;
    if (elapsed < 60) {
      return '${elapsed}s';
    }

    elapsed = elapsed ~/ 60;
    return '${elapsed}m';
  }
}
