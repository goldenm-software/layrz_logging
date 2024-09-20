import 'package:flutter/foundation.dart';
import 'package:layrz_logging/src/models.dart';
import 'src/native.dart' if (dart.library.html) 'src/web.dart';

class LayrzLogging {
  static void ensureInitialized() {
    FlutterError.onError = (FlutterErrorDetails details) {
      critical("${details.exceptionAsString()}\n${details.stack.toString()}");
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      critical("Platform error: $error\n$stackTrace");
      return true;
    };
  }

  static List<Log> logs = [];

  static void debug(String message) {
    log(level: LogLevel.debug, message: message);
  }

  static void info(String message) {
    log(level: LogLevel.info, message: message);
  }

  static void warning(String message) {
    log(level: LogLevel.warning, message: message);
  }

  static void error(String message) {
    log(level: LogLevel.error, message: message);
  }

  static void critical(String message) {
    log(level: LogLevel.critical, message: message);
  }

  static void log({required LogLevel level, required String message}) {
    debugPrint("[$level] $message");
    final log = Log(
      level: level,
      message: message,
      timestamp: DateTime.now(),
    );

    logs.add(log);

    if (logs.length > 50) {
      logs.removeAt(0);
    }

    saveIntoFile(log);
  }

  static String export() {
    return logs.map((e) => e.toString()).join("\n");
  }

  static Future<void> openLogfile() async {
    await openLogFile();
  }

  static void clean() {
    logs.clear();
  }
}
