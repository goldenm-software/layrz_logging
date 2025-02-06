part of '../database.dart';

class Record extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get logLevel => text()();
  TextColumn get entry => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
