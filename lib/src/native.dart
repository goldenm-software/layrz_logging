import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:layrz_logging/src/models.dart';
import 'package:layrz_logging/src/utils.dart';
import 'package:layrz_theme/layrz_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> initLogFile() async {
  // Ensure log file is initialized
  final Directory directory = await getApplicationSupportDirectory();
  File file = File('${directory.path}/latest.log');

  if (file.existsSync()) {
    final File previousFile = File('${directory.path}/previous.log');
    file.renameSync(previousFile.path);

    file = File('${directory.path}/latest.log');
    file.createSync();
  }
}

Future<void> saveIntoFile(Log log) async {
  if (!LayrzLoggingUtils.initialized) return;
  // Save log into a file
  final Directory directory = await getApplicationDocumentsDirectory();
  File file = File('${directory.path}/latest.log');

  file.writeAsStringSync(
    "${log.toString()}\n",
    mode: FileMode.append,
  );
}

Future<String?> openLogFile() async {
  if (!LayrzLoggingUtils.initialized) return null;
  try {
    final lines = await fetchLogsFromFile();

    final res = await Permission.storage.status;
    if (res == PermissionStatus.denied) {
      final status = await Permission.storage.request();

      if (status != PermissionStatus.granted) {
        return null;
      }
    } else if (res == PermissionStatus.permanentlyDenied) {
      return null;
    }

    final output = await saveFile(
      filename: 'export.log',
      bytes: utf8.encode(lines.join('\n')),
    );
    return output?.path;
  } catch (e) {
    debugPrint('Error opening log file: $e');
    return null;
  }
}

Future<List<String>> fetchLogsFromFile() async {
  if (!LayrzLoggingUtils.initialized) return [];
  List<String> lines = [];

  try {
    final Directory directory = await getApplicationDocumentsDirectory();
    File file = File('${directory.path}/latest.log');

    if (file.existsSync()) {
      lines.add("------- LATEST LOG ------");
      lines.addAll(file.readAsLinesSync());
    }

    file = File('${directory.path}/previous.log');
    if (file.existsSync()) {
      lines.add("------- PREVIOUS LOG ------");
      lines.addAll(file.readAsLinesSync());
    }
  } catch (e) {
    debugPrint('Error fetching logs from file: $e');
  }

  return lines;
}
