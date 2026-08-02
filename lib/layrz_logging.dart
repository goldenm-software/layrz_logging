import 'package:flutter/foundation.dart';
import 'package:layrz_logging/src/log_level.dart';
import 'package:layrz_logging/src/log_entry.dart';
import 'package:layrz_theme/layrz_theme.dart';

import 'src/database/database.dart';

export 'src/log_entry.dart';
export 'src/log_level.dart';
export 'src/preview.dart';

import 'src/ansi_colors.dart';
export 'src/ansi_colors.dart';

class Log {
  /// [initialized] is used to ensure that the logging system is initialized only once.
  static bool initialized = false;

  /// [_onLog] is a callback that is called whenever a log is created.
  static ValueChanged<LogEntry>? _onLog;

  /// [_db] is used to store logs in the database.
  static LoggingDb? _db;

  /// [ensureInitialized] is used to initialize the logging system.
  static void ensureInitialized({
    /// [onLog] is a callback that is called whenever a log is created.
    ///
    /// This callback repalces the default behavior of storing logs in the database or in memory.
    ///
    /// If you provide this callback, logs will not be stored in the database or in memory,
    /// and you will be responsible for handling them.
    ///
    /// In case that you want to store the logs in your own database, you can use
    /// the `Record` class on `layrz_logging` to use it as new table on your `drift` database
    ValueChanged<LogEntry>? onLog,
  }) {
    Log.initialized = true;
    FlutterError.onError = (FlutterErrorDetails details) {
      critical("${details.exceptionAsString()}\n${details.stack.toString()}");
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      critical("Platform error: $error\n$stackTrace");
      return true;
    };

    _onLog = onLog;

    if (_onLog != null) return;

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
    log(level: .debug, message: message);
  }

  static void info(String message) {
    log(level: .info, message: message);
  }

  static void warning(String message) {
    log(level: .warning, message: message);
  }

  static void error(String message) {
    log(level: .error, message: message);
  }

  static void critical(String message) {
    log(level: .critical, message: message);
  }

  static void log({required LogLevel level, required String message}) {
    if (kDebugMode || isWeb) debugPrint("${level.color}[$level] $message${AnsiColor.reset}");

    final log = LogEntry(
      level: level,
      message: message,
      timestamp: DateTime.now(),
    );

    if (_onLog != null) {
      _onLog!(log);
      return;
    }

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
    if (_onLog != null) {
      throw Exception("Cannot retreive logs when onLog is set.");
    }

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
