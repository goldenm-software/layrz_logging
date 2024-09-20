import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:layrz_logging/src/models.dart';
import 'package:open_file/open_file.dart';
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
    await OpenFile.open(directory.path);
  } catch (e) {
    debugPrint('Error opening log file: $e');
  }
}
