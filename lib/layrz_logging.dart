import 'package:flutter/foundation.dart';
import 'package:layrz_logging/src/models.dart';
import 'package:layrz_theme/layrz_theme.dart';

import 'src/database/database.dart';

export 'src/models.dart';
export 'src/preview.dart';

class Log {
  /// [initialized] is used to ensure that the logging system is initialized only once.
  static bool initialized = false;

  /// [_db] is used to store logs in the database.
  static LoggingDb? _db;

  /// [ensureInitialized] is used to initialize the logging system.
  static void ensureInitialized() {
    Log.initialized = true;
    FlutterError.onError = (FlutterErrorDetails details) {
      critical("${details.exceptionAsString()}\n${details.stack.toString()}");
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      critical("Platform error: $error\n$stackTrace");
      return true;
    };

    try {
      _db = LoggingDb();
    } catch (e) {
      _db = null;
      debugPrint("Error initializing database: $e");
    }
  }

  static bool get isWeb => ThemedPlatform.isWeb || ThemedPlatform.isWebWasm;

  static List<LogEntry> logs = [];

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

    final log = LogEntry(
      level: level,
      message: message,
      timestamp: DateTime.now(),
    );

    if (_db != null) {
      try {
        _db!
            .into(_db!.record)
            .insert(
              RecordCompanion.insert(
                logLevel: log.level.name.toUpperCase(),
                entry: log.message,
              ),
            );
      } catch (e) {
        logs.add(log);
      }
    } else {
      logs.add(log);
    }
  }

  static Future<List<String>> retreiveLogs() async {
    List<LogEntry> logList = [...logs];
    logs.clear();
    if (_db != null) {
      final rows = await _db!.select(_db!.record).get();
      await _db!.delete(_db!.record).go();
      logList.addAll(
        rows.map((e) {
          return LogEntry(
            level: LogLevel.values.firstWhere(
              (element) => element.name == e.logLevel.toLowerCase(),
              orElse: () => LogLevel.info,
            ),
            message: e.entry,
            timestamp: e.createdAt,
          );
        }),
      );
    }

    return compute(_sortAndFormat, logList);
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

typedef LayrzLogging = Log;
Future<List<String>> _sortAndFormat(List<LogEntry> logs) async {
  logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return logs.map((e) {
    final date = e.timestamp.toUtc();
    String timestamp = [
      '${date.year}',
      date.month.toString().padLeft(2, '0'),
      date.day.toString().padLeft(2, '0'),
    ].join('-');

    timestamp += ' ';

    timestamp += [
      date.hour.toString().padLeft(2, '0'),
      date.minute.toString().padLeft(2, '0'),
      date.second.toString().padLeft(2, '0'),
    ].join(':');

    return "[$timestamp] ${e.level.name.toUpperCase()}: ${e.message}";
  }).toList();
}
