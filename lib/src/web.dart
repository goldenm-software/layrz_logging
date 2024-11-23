import 'package:flutter/foundation.dart';
import 'package:layrz_logging/src/models.dart';

Future<void> initLogFile() async {
  debugPrint("[layrz_logging] initLogFile(): This method is not supported on the web");
}

Future<void> saveIntoFile(Log log) async {
  debugPrint("[layrz_logging] saveIntoFile(): This method is not supported on the web");
}

Future<String?> openLogFile() async {
  debugPrint("[layrz_logging] openLogFile(): This method is not supported on the web");

  return null;
}

Future<List<String>> fetchLogsFromFile() async {
  debugPrint("[layrz_logging] fetchLogsFromFile(): This method is not supported on the web");

  return [];
}
