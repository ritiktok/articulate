import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class Strokes extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get userId => text()();
  TextColumn get points => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get operation => text().withDefault(const Constant('draw'))();
  TextColumn get targetStrokeId => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get version => integer().nullable()();
  IntColumn get localVersion => integer().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Strokes])
class CanvasDatabase extends _$CanvasDatabase {
  CanvasDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 17;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 13) {
        await m.deleteTable('strokes');
        await m.deleteTable('sessions');
        await m.createAll();
      }
      if (from < 14) {
        await m.deleteTable('strokes');
        await m.createAll();
      }
      if (from < 15) {
        await m.deleteTable('strokes');
        await m.createAll();
      }
      if (from < 16) {
        await m.deleteTable('strokes');
        await m.createAll();
      }
      if (from < 17) {
        await m.deleteTable('strokes');
        await m.createAll();
      }
    },
  );

  Future<List<Stroke>> getStrokesForSession(String sessionId) {
    return (select(strokes)..where((s) => s.sessionId.equals(sessionId))).get();
  }

  Future<List<Stroke>> getActiveStrokesForSession(String sessionId) {
    return (select(strokes)..where(
          (s) => s.sessionId.equals(sessionId) & s.isActive.equals(true),
        ))
        .get();
  }

  Future<int> getNextLocalVersion(String sessionId) async {
    final result =
        await (select(strokes)
              ..where(
                (tbl) =>
                    tbl.sessionId.equals(sessionId) &
                    tbl.localVersion.isNotNull(),
              )
              ..orderBy([(s) => OrderingTerm.asc(s.localVersion)])
              ..limit(1))
            .getSingleOrNull();

    return (result?.localVersion ?? -0) - 1;
  }

  Future<int> addStroke(StrokesCompanion stroke) {
    return into(strokes).insert(stroke);
  }

  Future<int> addOrUpdateStroke(StrokesCompanion stroke) {
    return into(strokes).insertOnConflictUpdate(stroke);
  }

  Stream<List<Stroke>> watchStrokesForSession(String sessionId) {
    final strokeAlias = alias(strokes, 's');

    final orderExpr = CustomExpression<int>(
      'COALESCE("version", "local_version")',
    );

    return (select(strokeAlias)
          ..where(
            (s) => s.sessionId.equals(sessionId) & s.operation.equals('draw'),
          )
          ..orderBy([(_) => OrderingTerm(expression: orderExpr)]))
        .watch();
  }

  Stream<List<Stroke>> watchAllPendingStrokes() {
    return (select(strokes)
          ..where((s) => s.syncStatus.equals('pending'))
          ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
        .watch();
  }

  Stream<List<Stroke>> watchPendingStrokesForSession(String sessionId) {
    return (select(strokes)
          ..where(
            (s) =>
                s.sessionId.equals(sessionId) & s.syncStatus.equals('pending'),
          )
          ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
        .watch();
  }

  Future<List<Stroke>> getPendingSyncStrokes(String sessionId) {
    return (select(strokes)..where(
          (s) => s.sessionId.equals(sessionId) & s.syncStatus.equals('pending'),
        ))
        .get();
  }

  Future<List<String>> getSessionIdsWithPendingSync() {
    return (select(strokes)..where((s) => s.syncStatus.equals('pending')))
        .map((row) => row.sessionId)
        .get()
        .then((sessionIds) => sessionIds.toSet().toList());
  }

  Future<void> updateStrokeSyncStatus(
    String strokeId,
    String serverId,
    int serverVersion,
    DateTime serverCreatedAt,
  ) async {
    if (kDebugMode) {
      print('Updating stroke sync status: $strokeId');
    }

    await (update(strokes)..where((s) => s.id.equals(strokeId))).write(
      StrokesCompanion(
        id: Value(serverId),
        version: Value(serverVersion),
        createdAt: Value(serverCreatedAt),
        localVersion: const Value.absent(),
        syncStatus: Value('synced'),
      ),
    );
  }

  Future<void> updateStrokeActiveStatus(
    String sessionId,
    String strokeId,
    bool isActive,
  ) async {
    await (update(strokes)
          ..where((s) => s.sessionId.equals(sessionId) & s.id.equals(strokeId)))
        .write(StrokesCompanion(isActive: Value(isActive)));
  }

  Future<void> updateAllDrawStrokesActiveStatus(
    String sessionId,
    bool isActive,
  ) async {
    await (update(strokes)..where(
          (s) => s.sessionId.equals(sessionId) & s.operation.equals('draw'),
        ))
        .write(StrokesCompanion(isActive: Value(isActive)));
  }

  Future<void> deleteAllLocalData() async {
    await delete(strokes).go();
  }

  Future<void> deleteLocalDataForSession(String sessionId) async {
    await (delete(strokes)..where((s) => s.sessionId.equals(sessionId))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'canvas.db'));

      await dbFolder.create(recursive: true);

      return NativeDatabase.createInBackground(file);
    } catch (e) {
      if (kDebugMode) {
        print('Error opening database connection: $e');
      }
      rethrow;
    }
  });
}
