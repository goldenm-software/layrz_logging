// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $RecordTable extends Record with TableInfo<$RecordTable, RecordData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _logLevelMeta =
      const VerificationMeta('logLevel');
  @override
  late final GeneratedColumn<String> logLevel = GeneratedColumn<String>(
      'log_level', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entryMeta = const VerificationMeta('entry');
  @override
  late final GeneratedColumn<String> entry = GeneratedColumn<String>(
      'entry', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, logLevel, entry, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'record';
  @override
  VerificationContext validateIntegrity(Insertable<RecordData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('log_level')) {
      context.handle(_logLevelMeta,
          logLevel.isAcceptableOrUnknown(data['log_level']!, _logLevelMeta));
    } else if (isInserting) {
      context.missing(_logLevelMeta);
    }
    if (data.containsKey('entry')) {
      context.handle(
          _entryMeta, entry.isAcceptableOrUnknown(data['entry']!, _entryMeta));
    } else if (isInserting) {
      context.missing(_entryMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecordData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      logLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}log_level'])!,
      entry: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entry'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $RecordTable createAlias(String alias) {
    return $RecordTable(attachedDatabase, alias);
  }
}

class RecordData extends DataClass implements Insertable<RecordData> {
  final int id;
  final String logLevel;
  final String entry;
  final DateTime createdAt;
  const RecordData(
      {required this.id,
      required this.logLevel,
      required this.entry,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['log_level'] = Variable<String>(logLevel);
    map['entry'] = Variable<String>(entry);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RecordCompanion toCompanion(bool nullToAbsent) {
    return RecordCompanion(
      id: Value(id),
      logLevel: Value(logLevel),
      entry: Value(entry),
      createdAt: Value(createdAt),
    );
  }

  factory RecordData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordData(
      id: serializer.fromJson<int>(json['id']),
      logLevel: serializer.fromJson<String>(json['logLevel']),
      entry: serializer.fromJson<String>(json['entry']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'logLevel': serializer.toJson<String>(logLevel),
      'entry': serializer.toJson<String>(entry),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RecordData copyWith(
          {int? id, String? logLevel, String? entry, DateTime? createdAt}) =>
      RecordData(
        id: id ?? this.id,
        logLevel: logLevel ?? this.logLevel,
        entry: entry ?? this.entry,
        createdAt: createdAt ?? this.createdAt,
      );
  RecordData copyWithCompanion(RecordCompanion data) {
    return RecordData(
      id: data.id.present ? data.id.value : this.id,
      logLevel: data.logLevel.present ? data.logLevel.value : this.logLevel,
      entry: data.entry.present ? data.entry.value : this.entry,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordData(')
          ..write('id: $id, ')
          ..write('logLevel: $logLevel, ')
          ..write('entry: $entry, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, logLevel, entry, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordData &&
          other.id == this.id &&
          other.logLevel == this.logLevel &&
          other.entry == this.entry &&
          other.createdAt == this.createdAt);
}

class RecordCompanion extends UpdateCompanion<RecordData> {
  final Value<int> id;
  final Value<String> logLevel;
  final Value<String> entry;
  final Value<DateTime> createdAt;
  const RecordCompanion({
    this.id = const Value.absent(),
    this.logLevel = const Value.absent(),
    this.entry = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RecordCompanion.insert({
    this.id = const Value.absent(),
    required String logLevel,
    required String entry,
    this.createdAt = const Value.absent(),
  })  : logLevel = Value(logLevel),
        entry = Value(entry);
  static Insertable<RecordData> custom({
    Expression<int>? id,
    Expression<String>? logLevel,
    Expression<String>? entry,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (logLevel != null) 'log_level': logLevel,
      if (entry != null) 'entry': entry,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RecordCompanion copyWith(
      {Value<int>? id,
      Value<String>? logLevel,
      Value<String>? entry,
      Value<DateTime>? createdAt}) {
    return RecordCompanion(
      id: id ?? this.id,
      logLevel: logLevel ?? this.logLevel,
      entry: entry ?? this.entry,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (logLevel.present) {
      map['log_level'] = Variable<String>(logLevel.value);
    }
    if (entry.present) {
      map['entry'] = Variable<String>(entry.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordCompanion(')
          ..write('id: $id, ')
          ..write('logLevel: $logLevel, ')
          ..write('entry: $entry, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$LoggingDb extends GeneratedDatabase {
  _$LoggingDb(QueryExecutor e) : super(e);
  $LoggingDbManager get managers => $LoggingDbManager(this);
  late final $RecordTable record = $RecordTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [record];
}

typedef $$RecordTableCreateCompanionBuilder = RecordCompanion Function({
  Value<int> id,
  required String logLevel,
  required String entry,
  Value<DateTime> createdAt,
});
typedef $$RecordTableUpdateCompanionBuilder = RecordCompanion Function({
  Value<int> id,
  Value<String> logLevel,
  Value<String> entry,
  Value<DateTime> createdAt,
});

class $$RecordTableFilterComposer extends Composer<_$LoggingDb, $RecordTable> {
  $$RecordTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get logLevel => $composableBuilder(
      column: $table.logLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entry => $composableBuilder(
      column: $table.entry, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$RecordTableOrderingComposer
    extends Composer<_$LoggingDb, $RecordTable> {
  $$RecordTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get logLevel => $composableBuilder(
      column: $table.logLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entry => $composableBuilder(
      column: $table.entry, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$RecordTableAnnotationComposer
    extends Composer<_$LoggingDb, $RecordTable> {
  $$RecordTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get logLevel =>
      $composableBuilder(column: $table.logLevel, builder: (column) => column);

  GeneratedColumn<String> get entry =>
      $composableBuilder(column: $table.entry, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$RecordTableTableManager extends RootTableManager<
    _$LoggingDb,
    $RecordTable,
    RecordData,
    $$RecordTableFilterComposer,
    $$RecordTableOrderingComposer,
    $$RecordTableAnnotationComposer,
    $$RecordTableCreateCompanionBuilder,
    $$RecordTableUpdateCompanionBuilder,
    (RecordData, BaseReferences<_$LoggingDb, $RecordTable, RecordData>),
    RecordData,
    PrefetchHooks Function()> {
  $$RecordTableTableManager(_$LoggingDb db, $RecordTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecordTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecordTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> logLevel = const Value.absent(),
            Value<String> entry = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              RecordCompanion(
            id: id,
            logLevel: logLevel,
            entry: entry,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String logLevel,
            required String entry,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              RecordCompanion.insert(
            id: id,
            logLevel: logLevel,
            entry: entry,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecordTableProcessedTableManager = ProcessedTableManager<
    _$LoggingDb,
    $RecordTable,
    RecordData,
    $$RecordTableFilterComposer,
    $$RecordTableOrderingComposer,
    $$RecordTableAnnotationComposer,
    $$RecordTableCreateCompanionBuilder,
    $$RecordTableUpdateCompanionBuilder,
    (RecordData, BaseReferences<_$LoggingDb, $RecordTable, RecordData>),
    RecordData,
    PrefetchHooks Function()>;

class $LoggingDbManager {
  final _$LoggingDb _db;
  $LoggingDbManager(this._db);
  $$RecordTableTableManager get record =>
      $$RecordTableTableManager(_db, _db.record);
}
