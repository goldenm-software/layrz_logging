import './log_level.dart';

class LogEntry {
  String message;
  LogLevel level;
  DateTime timestamp;

  LogEntry({
    required this.message,
    required this.level,
    required this.timestamp,
  });

  @override
  String toString() {
    return "[$level] $timestamp => $message";
  }
}
