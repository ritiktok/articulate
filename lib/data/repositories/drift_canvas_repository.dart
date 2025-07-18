import 'dart:convert';
import 'package:drift/drift.dart';
import '../models/drawing_stroke.dart';
import '../models/drawing_point.dart';
import '../database/database.dart';

class DriftCanvasRepository {
  final CanvasDatabase _database;

  DriftCanvasRepository(this._database);

  Future<void> close() async {
    await _database.close();
  }

  Future<void> addStroke(String sessionId, DrawingStroke stroke) async {
    try {
      final nextLocalVersion = stroke.version == null
          ? await _database.getNextLocalVersion(sessionId)
          : null;

      switch (stroke.operation) {
        case 'undo':
          await _handleUndoOperation(sessionId, stroke, nextLocalVersion);
          break;
        case 'redo':
          await _handleRedoOperation(sessionId, stroke, nextLocalVersion);
          break;
        case 'clear':
          await _handleClearOperation(sessionId, stroke, nextLocalVersion);
          break;
        default:
          final strokeCompanion = StrokesCompanion.insert(
            id: stroke.id,
            sessionId: sessionId,
            userId: stroke.userId,
            points: jsonEncode(stroke.points.map((p) => p.toJson()).toList()),
            createdAt: stroke.createdAt,
            operation: Value(stroke.operation),
            targetStrokeId: Value(stroke.targetStrokeId),
            isActive: Value(stroke.isActive),
            version: stroke.version != null
                ? Value(stroke.version!)
                : const Value.absent(),
            localVersion: nextLocalVersion != null
                ? Value(nextLocalVersion)
                : const Value.absent(),
            syncStatus: stroke.version != null
                ? Value('synced')
                : const Value('pending'),
          );

          await _database.addStroke(strokeCompanion);
      }
    } catch (e) {
      if (e.toString().contains('connection was closed')) {
        throw Exception('Database connection was closed. Please try again.');
      }
      throw Exception('Failed to add stroke: $e');
    }
  }

  Future<void> _handleUndoOperation(
    String sessionId,
    DrawingStroke stroke,
    int? nextLocalVersion,
  ) async {
    await _database.transaction(() async {
      final activeStrokes = await _database.getActiveStrokesForSession(
        sessionId,
      );
      final drawStrokes = activeStrokes
          .where((s) => s.operation == 'draw')
          .toList();

      if (drawStrokes.isNotEmpty) {
        drawStrokes.sort((a, b) {
          if (a.localVersion != null && b.localVersion != null) {
            return a.localVersion!.compareTo(b.localVersion!);
          }

          if (a.version != null && b.version != null) {
            return b.version!.compareTo(a.version!);
          }

          if (a.localVersion != null && b.version != null) {
            return -1;
          }
          if (a.version != null && b.localVersion != null) {
            return 1;
          }

          if (a.localVersion != null) return -1;
          if (b.localVersion != null) return 1;

          if (a.version != null) return -1;
          if (b.version != null) return 1;

          return 0;
        });
        final targetStroke = drawStrokes.first;

        await _database.updateStrokeActiveStatus(
          sessionId,
          targetStroke.id,
          false,
        );

        final undoStrokeCompanion = StrokesCompanion.insert(
          id: stroke.id,
          sessionId: sessionId,
          userId: stroke.userId,
          points: jsonEncode(stroke.points.map((p) => p.toJson()).toList()),
          createdAt: stroke.createdAt,
          operation: const Value('undo'),
          targetStrokeId: Value(targetStroke.id),
          isActive: const Value(false),
          version: stroke.version != null
              ? Value(stroke.version!)
              : const Value.absent(),
          localVersion: nextLocalVersion != null
              ? Value(nextLocalVersion)
              : const Value.absent(),
          syncStatus: stroke.version != null
              ? Value('synced')
              : const Value('pending'),
        );

        await _database.addStroke(undoStrokeCompanion);
      }
    });
  }

  Future<void> _handleRedoOperation(
    String sessionId,
    DrawingStroke stroke,
    int? nextLocalVersion,
  ) async {
    await _database.transaction(() async {
      final allStrokes = await _database.getStrokesForSession(sessionId);
      final undoStrokes = allStrokes
          .where((s) => s.operation == 'undo' && s.targetStrokeId != null)
          .toList();

      if (undoStrokes.isNotEmpty) {
        undoStrokes.sort((a, b) {
          if (a.localVersion != null && b.localVersion != null) {
            return a.localVersion!.compareTo(b.localVersion!);
          }

          if (a.version != null && b.version != null) {
            return b.version!.compareTo(a.version!);
          }

          if (a.localVersion != null && b.version != null) {
            return -1;
          }
          if (a.version != null && b.localVersion != null) {
            return 1;
          }

          if (a.localVersion != null) return -1;
          if (b.localVersion != null) return 1;

          if (a.version != null) return -1;
          if (b.version != null) return 1;

          return 0;
        });
        final lastUndoStroke = undoStrokes.first;

        final targetStroke = allStrokes
            .where((s) => s.id == lastUndoStroke.targetStrokeId)
            .firstOrNull;

        if (targetStroke != null && !targetStroke.isActive) {
          await _database.updateStrokeActiveStatus(
            sessionId,
            targetStroke.id,
            true,
          );

          final redoStrokeCompanion = StrokesCompanion.insert(
            id: stroke.id,
            sessionId: sessionId,
            userId: stroke.userId,
            points: jsonEncode(stroke.points.map((p) => p.toJson()).toList()),
            createdAt: stroke.createdAt,
            operation: const Value('redo'),
            targetStrokeId: Value(targetStroke.id),
            isActive: const Value(true),
            version: stroke.version != null
                ? Value(stroke.version!)
                : const Value.absent(),
            localVersion: nextLocalVersion != null
                ? Value(nextLocalVersion)
                : const Value.absent(),
            syncStatus: stroke.version != null
                ? Value('synced')
                : const Value('pending'),
          );

          await _database.addStroke(redoStrokeCompanion);
        }
      }
    });
  }

  Future<void> _handleClearOperation(
    String sessionId,
    DrawingStroke stroke,
    int? nextLocalVersion,
  ) async {
    await _database.transaction(() async {
      await _database.updateAllDrawStrokesActiveStatus(sessionId, false);

      final clearStrokeCompanion = StrokesCompanion.insert(
        id: stroke.id,
        sessionId: sessionId,
        userId: stroke.userId,
        points: jsonEncode(stroke.points.map((p) => p.toJson()).toList()),
        createdAt: stroke.createdAt,
        operation: const Value('clear'),
        targetStrokeId: const Value.absent(),
        isActive: const Value(false),
        version: stroke.version != null
            ? Value(stroke.version!)
            : const Value.absent(),
        localVersion: nextLocalVersion != null
            ? Value(nextLocalVersion)
            : const Value.absent(),
        syncStatus: stroke.version != null
            ? Value('synced')
            : const Value('pending'),
      );

      await _database.addStroke(clearStrokeCompanion);
    });
  }

  Future<bool> canUndo(String sessionId) async {
    return await _database.canUndo(sessionId);
  }

  Future<bool> canRedo(String sessionId) async {
    return await _database.canRedo(sessionId);
  }

  Stream<List<DrawingStroke>> watchStrokes(String sessionId) {
    return _database.watchStrokesForSession(sessionId).map((strokesData) {
      final strokes = strokesData
          .map((strokeData) => _convertToDrawingStroke(strokeData))
          .toList();

      return strokes;
    });
  }

  Future<List<DrawingStroke>> getOfflineStrokes(String sessionId) async {
    final pendingStrokesData = await _database.getPendingSyncStrokes(sessionId);
    return pendingStrokesData
        .map((strokeData) => _convertToDrawingStroke(strokeData))
        .toList();
  }

  Future<List<DrawingStroke>> getActiveStrokes(String sessionId) async {
    final allStrokesData = await _database.getStrokesForSession(sessionId);
    final drawStrokes = allStrokesData
        .where((s) => s.operation == 'draw' && s.isActive)
        .toList();

    return drawStrokes
        .map((strokeData) => _convertToDrawingStroke(strokeData))
        .toList();
  }

  Future<void> updateStrokeSyncStatus(
    String strokeId,

    int serverVersion,
    DateTime serverCreatedAt,
  ) async {
    try {
      await _database.updateStrokeSyncStatus(
        strokeId,
        serverVersion,
        serverCreatedAt,
      );
    } catch (e) {
      throw Exception('Failed to update stroke sync status: $e');
    }
  }

  Future<void> batchUpdateStrokesFromRemote(
    String sessionId,
    List<DrawingStroke> strokes,
  ) async {
    try {
      final companions = strokes
          .map(
            (stroke) => StrokesCompanion(
              id: Value(stroke.id),
              sessionId: Value(sessionId),
              userId: Value(stroke.userId),
              points: Value(
                jsonEncode(stroke.points.map((p) => p.toJson()).toList()),
              ),
              createdAt: Value(stroke.createdAt),
              operation: Value(stroke.operation),
              targetStrokeId: Value(stroke.targetStrokeId),
              isActive: Value(stroke.isActive),
              version: stroke.version != null
                  ? Value(stroke.version!)
                  : const Value.absent(),
              localVersion: const Value.absent(),
              syncStatus: Value('synced'),
            ),
          )
          .toList();
      await _database.batchAddOrUpdateStrokes(companions);
    } catch (e) {
      throw Exception('Failed to batch update strokes from remote: $e');
    }
  }

  DrawingStroke _convertToDrawingStroke(Stroke strokeData) {
    final pointsJson = jsonDecode(strokeData.points) as List;
    final points = pointsJson
        .map((pointJson) => DrawingPoint.fromJson(pointJson))
        .toList();

    return DrawingStroke(
      id: strokeData.id,
      sessionId: strokeData.sessionId,
      userId: strokeData.userId,
      points: points,
      createdAt: strokeData.createdAt,
      operation: strokeData.operation,
      targetStrokeId: strokeData.targetStrokeId,
      isActive: strokeData.isActive,
      version: strokeData.version,
    );
  }
}
