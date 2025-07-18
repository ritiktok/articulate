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

  Future<bool> canUndo(String sessionId) async {
    final count =
        await (strokes.select()
              ..where((t) => t.sessionId.equals(sessionId))
              ..where((t) => t.isActive.equals(true)))
            .get()
            .then((rows) => rows.length);

    return count > 0;
  }

  Future<bool> canRedo(String sessionId) async {
    final count =
        await (strokes.select()
              ..where((t) => t.sessionId.equals(sessionId))
              ..where((t) => t.isActive.equals(false)))
            .get()
            .then((rows) => rows.length);

    return count > 0;
  }

  Future<int> getNextLocalVersion(String sessionId) async {
    return await transaction(() async {
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
    });
  }

  Future<int> addStroke(StrokesCompanion stroke) {
    return transaction(() async {
      return await into(strokes).insert(stroke);
    });
  }

  Future<void> batchAddOrUpdateStrokes(List<StrokesCompanion> strokes) {
    return transaction(() async {
      await batch((batch) {
        batch.insertAllOnConflictUpdate(this.strokes, strokes);
      });
    });
  }

  Stream<List<Stroke>> watchStrokesForSession(String sessionId) {
    final strokeAlias = alias(strokes, 's');

    final orderExpr = CustomExpression<int>(
      'COALESCE("version", "local_version")',
    );

    return (select(strokeAlias)
          ..where(
            (s) =>
                s.sessionId.equals(sessionId) &
                s.operation.equals('draw') &
                s.isActive.equals(true),
          )
          ..orderBy([(_) => OrderingTerm(expression: orderExpr)]))
        .watch();
  }

  Future<List<Stroke>> getPendingSyncStrokes(String sessionId) {
    return (select(strokes)..where(
          (s) => s.sessionId.equals(sessionId) & s.syncStatus.equals('pending'),
        ))
        .get();
  }

  Future<void> updateStrokeSyncStatus(
    String strokeId,
    int serverVersion,
    DateTime serverCreatedAt,
  ) async {
    await transaction(() async {
      final existingStroke = await (select(
        strokes,
      )..where((s) => s.id.equals(strokeId))).getSingleOrNull();

      if (existingStroke != null) {
        await (update(strokes)..where((s) => s.id.equals(strokeId))).write(
          StrokesCompanion(
            version: Value(serverVersion),
            createdAt: Value(serverCreatedAt),
            localVersion: const Value.absent(),
            syncStatus: Value('synced'),
          ),
        );
      } else {
        await (update(strokes)..where((s) => s.id.equals(strokeId))).write(
          StrokesCompanion(
            id: Value(strokeId),
            version: Value(serverVersion),
            createdAt: Value(serverCreatedAt),
            localVersion: const Value.absent(),
            syncStatus: Value('synced'),
          ),
        );
      }
    });
  }

  Future<void> updateStrokeActiveStatus(
    String sessionId,
    String strokeId,
    bool isActive,
  ) async {
    await transaction(() async {
      await (update(strokes)..where(
            (s) => s.sessionId.equals(sessionId) & s.id.equals(strokeId),
          ))
          .write(StrokesCompanion(isActive: Value(isActive)));
    });
  }

  Future<void> updateAllDrawStrokesActiveStatus(
    String sessionId,
    bool isActive,
  ) async {
    await transaction(() async {
      await (update(strokes)..where(
            (s) => s.sessionId.equals(sessionId) & s.operation.equals('draw'),
          ))
          .write(StrokesCompanion(isActive: Value(isActive)));
    });
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
