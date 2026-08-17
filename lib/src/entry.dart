import 'level.dart';

/// A single log entry produced by the logging system.
///
/// Contains the message, log level, timestamp, and optional error/stack trace.
class LogEntry {
  /// The log message text.
  String message;

  /// The severity level of the log entry.
  LogLevel level;

  /// The timestamp when this entry was created.
  DateTime timestamp;

  /// Optional error object associated with this log entry.
  ///
  /// When present, represents the exception or error that caused the log.
  Object? error;

  /// Optional stack trace associated with this log entry.
  ///
  /// When present, represents the call stack at the time of the log.
  StackTrace? stackTrace;

  LogEntry({
    required this.message,
    required this.level,
    required this.timestamp,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    String result = "[$level] $timestamp => $message";

    if (error != null) {
      result += " | Error: $error";
    }

    if (stackTrace != null) {
      result += "\n$stackTrace";
    }

    return result;
  }
}
