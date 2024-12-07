# Changelog

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
