class Log {
  String message;
  LogLevel level;
  DateTime timestamp;

  Log({
    required this.message,
    required this.level,
    required this.timestamp,
  });

  @override
  String toString() {
    return "[$level] $timestamp => $message";
  }
}

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
  ;

  @override
  String toString() {
    switch (this) {
      case LogLevel.debug:
        return "DEBUG";
      case LogLevel.info:
        return "INFO";
      case LogLevel.warning:
        return "WARNING";
      case LogLevel.error:
        return "ERROR";
      case LogLevel.critical:
        return "CRITICAL";
      default:
        return "UNKNOWN";
    }
  }
}
