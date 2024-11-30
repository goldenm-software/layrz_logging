import 'package:flutter/foundation.dart';
import 'package:layrz_logging/src/models.dart';
import 'package:layrz_theme/layrz_theme.dart';
import 'src/native.dart' if (dart.library.js_interop) 'src/web.dart';

export 'src/models.dart';
export 'src/preview.dart';

class LayrzLogging {
  static void ensureInitialized() {
    initLogFile().then((_) {
      FlutterError.onError = (FlutterErrorDetails details) {
        critical("${details.exceptionAsString()}\n${details.stack.toString()}");
      };

      PlatformDispatcher.instance.onError = (error, stackTrace) {
        critical("Platform error: $error\n$stackTrace");
        return true;
      };
    });
  }

  static bool get isWeb => kThemedPlatform == ThemedPlatform.web;

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
    if (kDebugMode || isWeb) debugPrint("[$level] $message");

    final log = Log(
      level: level,
      message: message,
      timestamp: DateTime.now(),
    );

    if (ThemedPlatform.isWeb) {
      logs.add(log);

      if (logs.length > 100) {
        logs.removeAt(0);
      }
    } else {
      saveIntoFile(log);
    }
  }

  static String export() {
    return logs.map((e) => e.toString()).join("\n");
  }

  static Future<String?> openLogfile() async {
    if (isWeb) throw UnsupportedError("This method is not supported on the web");
    return openLogFile();
  }

  static Future<List<String>> fetchLogs() async {
    if (isWeb) {
      return logs.map((e) => e.toString()).toList();
    }
    return fetchLogsFromFile();
  }

  static void clean() {
    logs.clear();
  }
}
