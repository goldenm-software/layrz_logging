# Changelog

## 1.5.0

**Breaking:** this release removes public API. Applications on `^1.4.0` will
need changes before upgrading.

- Removed the drift/SQLite persistence layer. `LoggingDb`, `RecordData` and `RecordCompanion` are no longer exported — persisting logs is now the application's responsibility.
- Removed `Log.logs` and `Log.retreiveLogs()`. Subscribe to the new `Log.stream` and store entries yourself instead.
- Removed the `onLog` callback parameter from `Log.ensureInitialized()`. Subscribe to `Log.stream` instead.
- Removed `PreviewLogDialog`.
- Added `Log.stream`, a broadcast `Stream<LogEntry>` that emits every log entry. Note that broadcast streams do not replay: entries logged before you subscribe are not delivered, so subscribe during startup if you need early logs.
- Added optional `error` and `stackTrace` arguments to `Log.log()` and to `debug()`, `info()`, `warning()`, `error()` and `critical()`. `LogEntry` now carries both.
- The `FlutterError` and `PlatformDispatcher` error handlers now pass the error and stack trace structurally instead of concatenating them into the log message.
- Dropped the `drift`, `drift_flutter`, `path_provider`, `path`, `layrz_icons` and `layrz_i18n` dependencies. The Flutter SDK is now the only runtime dependency.

## 1.4.0

- Added `onLog` callback to `LayrzLogging` class to allow users to handle logs in their own way, bypassing the default database and in-memory storage.

## 1.3.0

- Added `AnsiColor` class to handle ANSI color codes for console output.
- Updated `LogLevel` enum to include a `color` property that returns the corresponding ANSI color code for each log level.
- Updated `Log` class to use the new `color` property when printing log messages to the console.

## 1.2.0

- Renamed `Log` class to `LogEntry` to avoid confusion with other packages.
- Renamed `LayrzLogging` class to `Log` for simplicity.
- Added an alias of `LayrzLogging` to `Log` for backward compatibility.
- Added `humanizeMicroseconds` on class to convert microseconds to a human readable format.
- Constraints updated to support Flutter 3.35.0 and Dart 3.9.0 as minimum versions.

## 1.1.0

- Migrated to use `drift` instead of classic files and lists to store logs.

## 1.0.14

- Added support for non-initalized `LayrzLogging` instance.

## 1.0.13

- Updated README.md with examples

## 1.0.12

- Removed all debugPrint messages of not supported on web platform.

## 1.0.11

- Replaced `dart.library.html` to `dart.library.js_interop` to fully support Web WASM.

## 1.0.9

- Prevent call of `saveIntoFile` when is in Web.fl

## 1.0.8

- Added new method to readLogs from the files created, and return a `List<String>`.
- Changed method `openLogfile` to use the same method that `readLogs`.
- Added `PreviewLogDialog` widget to show the logs in a dialog.
- Changed `openLogfile` to validate the permissions before trying to save a file.

## 1.0.7

- Added `openLogfile` method to open the log file in the default text editor.

## 1.0.6

- Removed `open_file` dependency to support WASM compilation.

## 1.0.5

- Lowered flutter version constraint to 3.22.0

## 1.0.4

- Added a conditional based on `kDebugMode` to prevent logs on console when is not in debug mode.
- Opening the directory instead of two files when `openLogfile()` is called.

## 1.0.3

- Fixes related to logfile handling.

## 1.0.2

- Handled latest and previous log files.

## 1.0.1

- Stack trace on FlutterError

## 1.0.0

- Initial release
