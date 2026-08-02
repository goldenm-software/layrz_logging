import './ansi_colors.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical;

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

  String get color {
    switch (this) {
      case LogLevel.debug:
        return AnsiColor.cyan;
      case LogLevel.info:
        return AnsiColor.reset;
      case LogLevel.warning:
        return AnsiColor.yellow;
      case LogLevel.error:
        return AnsiColor.red;
      case LogLevel.critical:
        return AnsiColor.magenta;
      default:
        return AnsiColor.reset;
    }
  }
}
