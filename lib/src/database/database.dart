library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

part 'src/message.dart';

@DriftDatabase(tables: [Record])
class LoggingDb extends _$LoggingDb {
  LoggingDb([QueryExecutor? e])
      : super(e ??
            driftDatabase(
              name: 'logging.db',
              native: const DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory),
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('https://cdn.layrz.com/utils/sqlite3.wasm'),
                driftWorker: Uri.parse('https://cdn.layrz.com/utils/drift_worker.js'),
                onResult: (result) {
                  if (result.missingFeatures.isNotEmpty) {
                    debugPrint('Missing features: ${result.missingFeatures}');
                  }
                },
              ),
            ));

  @override
  int get schemaVersion => 1;
}
