import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/canvas_session.dart';
import '../models/drawing_stroke.dart';

class SupabaseCanvasRepository {
  final SupabaseClient _supabase;

  SupabaseCanvasRepository(this._supabase);

  Future<CanvasSession?> getSession(String sessionId) async {
    try {
      final response = await _supabase
          .from('canvas_sessions')
          .select()
          .eq('id', sessionId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return CanvasSession.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get session: $e');
    }
  }

  Future<CanvasSession?> createSession(
    String userId,
    String sessionId, {
    String? title,
  }) async {
    try {
      final existingSession = await getSession(sessionId);
      if (existingSession != null) {
        return existingSession;
      }
      final session = CanvasSession(
        id: sessionId,
        createdAt: DateTime.now(),
        title: title,
        createdBy: userId,
      );

      final insertData = {
        'id': session.id,
        'created_at': session.createdAt.toIso8601String(),
        'title': session.title,
        'created_by': session.createdBy,
      };
      await _supabase.from('canvas_sessions').insert(insertData);
      return session;
    } catch (e) {
      throw Exception('Failed to create session: $e');
    }
  }

  Future<PostgrestMap> addStroke(String sessionId, DrawingStroke stroke) async {
    try {
      final strokeId = stroke.id;

      final insertData = {
        'id': strokeId,
        'session_id': sessionId,
        'user_id': stroke.userId,
        'points': jsonEncode(stroke.points.map((p) => p.toJson()).toList()),
        'created_at': stroke.createdAt.toIso8601String(),
        'operation': stroke.operation,
        'target_stroke_id': stroke.targetStrokeId,
        'is_active': stroke.isActive,
      };

      final result = await _supabase
          .from('drawing_strokes')
          .insert(insertData)
          .select('id, version, created_at')
          .single();

      return result;
    } catch (e) {
      throw Exception('Failed to create stroke: $e');
    }
  }

  Future<List<PostgrestMap>> batchAddStrokes(
    String sessionId,
    List<DrawingStroke> strokes,
  ) async {
    try {
      final insertData = strokes
          .map(
            (stroke) => {
              'id': stroke.id,
              'session_id': sessionId,
              'user_id': stroke.userId,
              'points': jsonEncode(
                stroke.points.map((p) => p.toJson()).toList(),
              ),
              'created_at': stroke.createdAt.toIso8601String(),
              'operation': stroke.operation,
              'target_stroke_id': stroke.targetStrokeId,
              'is_active': stroke.isActive,
            },
          )
          .toList();

      final result = await _supabase
          .from('drawing_strokes')
          .insert(insertData)
          .select('id, version, created_at');

      return result;
    } catch (e) {
      throw Exception('Failed to batch create strokes: $e');
    }
  }

  Stream<List<DrawingStroke>> watchStrokesForSession(String sessionId) async* {
    try {
      final initialStrokes = await getAllStrokesForSession(sessionId);
      yield initialStrokes;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to fetch initial strokes: $e');
      }
      yield <DrawingStroke>[];
    }

    yield* _supabase
        .from('drawing_strokes')
        .stream(primaryKey: ['id'])
        .map((event) {
          final strokes = event
              .where((json) => json['session_id'] == sessionId)
              .map((json) => DrawingStroke.fromJson(json))
              .toList();

          strokes.sort((a, b) {
            final aVersion = a.version ?? 0;
            final bVersion = b.version ?? 0;
            return aVersion.compareTo(bVersion);
          });

          return strokes;
        })
        .handleError((error) {
          return <DrawingStroke>[];
        });
  }

  Future<List<DrawingStroke>> getAllStrokesForSession(String sessionId) async {
    try {
      final response = await _supabase
          .from('drawing_strokes')
          .select()
          .eq('session_id', sessionId)
          .eq('is_active', true)
          .eq('operation', 'draw')
          .order('created_at');

      final strokes = response
          .map((json) => DrawingStroke.fromJson(json))
          .toList();

      strokes.sort((a, b) {
        final aVersion = a.version ?? 0;
        final bVersion = b.version ?? 0;
        return aVersion.compareTo(bVersion);
      });

      return strokes;
    } catch (e) {
      throw Exception('Failed to get strokes for session: $e');
    }
  }
}
