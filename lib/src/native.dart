import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:layrz_logging/src/models.dart';
import 'package:layrz_theme/layrz_theme.dart';
import 'package:path_provider/path_provider.dart';

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
  // Save log into a file
  final Directory directory = await getApplicationSupportDirectory();
  File file = File('${directory.path}/latest.log');

  file.writeAsStringSync(
    "${log.toString()}\n",
    mode: FileMode.append,
  );
}

Future<void> openLogFile() async {
  try {
    final Directory directory = await getApplicationSupportDirectory();

    List<String> lines = [];
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

    await saveFile(
      filename: 'latest.log',
      bytes: utf8.encode(lines.join('\n')),
    );
  } catch (e) {
    debugPrint('Error opening log file: $e');
  }
}
