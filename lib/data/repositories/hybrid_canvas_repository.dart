import 'dart:async';
import 'package:articulate/data/repositories/supabase_canvas_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/canvas_session.dart';
import '../models/drawing_stroke.dart';
import 'drift_canvas_repository.dart';

class HybridCanvasRepository {
  final DriftCanvasRepository _localRepository;
  final SupabaseCanvasRepository _remoteRepository;
  bool _isOnline = false;
  String? _activeSessionId;
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  StreamSubscription<List<DrawingStroke>>? _remoteToLocalSubscription;
  StreamSubscription<List<DrawingStroke>>? _localToRemoteSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  final Set<String> _pendingSyncStrokeIds = {};
  final Map<String, DateTime> _failedSyncStrokes = {};

  Timer? _localChangeDebounceTimer;
  Timer? _cleanupTimer;

  HybridCanvasRepository({
    required DriftCanvasRepository localRepository,
    required SupabaseCanvasRepository remoteRepository,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository {
    _initializeConnectivity();
    _startCleanupTimer();
  }

  Stream<bool> get connectivityStream => _connectivityController.stream;

  bool get isOnline => _isOnline;

  void setActiveSession(String sessionId) {
    _activeSessionId = sessionId;
    if (_isOnline) {
      _disposeBidirectionalSync();
      _setupBidirectionalSync();
    }
  }

  void clearActiveSession() {
    _activeSessionId = null;
    _disposeBidirectionalSync();
  }

  Future<void> deleteAllLocalData() async {
    await _localRepository.deleteAllLocalData();
  }

  void _initializeConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) async {
      final wasOnline = _isOnline;
      _isOnline =
          results.isNotEmpty &&
          results.any((result) => result != ConnectivityResult.none);

      if (wasOnline != _isOnline) {
        _connectivityController.add(_isOnline);
        if (_isOnline) {
          _setupBidirectionalSync();
          await _recoverOfflineStrokes();
        } else {
          _disposeBidirectionalSync();
        }
      }
    });
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _cleanupFailedSyncStrokes();
    });
  }

  void _cleanupFailedSyncStrokes() {
    final now = DateTime.now();
    final expiredStrokes = _failedSyncStrokes.entries
        .where((entry) => now.difference(entry.value).inMinutes > 10)
        .map((entry) => entry.key)
        .toList();

    for (final strokeId in expiredStrokes) {
      _failedSyncStrokes.remove(strokeId);
      _pendingSyncStrokeIds.remove(strokeId);
    }

    if (expiredStrokes.isNotEmpty) {
      if (kDebugMode) {
        print('Cleaned up ${expiredStrokes.length} failed sync strokes');
      }
    }
  }

  void _setupBidirectionalSync() {
    if (!_isOnline || _activeSessionId == null) return;

    try {
      _remoteToLocalSubscription = _remoteRepository
          .watchStrokesForSession(_activeSessionId!)
          .listen(
            (remoteStrokes) {
              _handleRemoteToLocalSync(remoteStrokes);
            },
            onError: (error) {
              if (kDebugMode) {
                print('Error in remote to local sync: $error');
              }
              _retryRemoteToLocalSync();
            },
            cancelOnError: false,
          );

      _localToRemoteSubscription = _localRepository
          .watchPendingStrokesForSession(_activeSessionId!)
          .listen(
            (localStrokes) {
              _handleLocalToRemoteSync(localStrokes);
            },
            onError: (error) {
              if (kDebugMode) {
                print('Error in local to remote sync: $error');
              }
              _retryLocalToRemoteSync();
            },
            cancelOnError: false,
          );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to setup bidirectional sync: $e');
      }
    }
  }

  void _disposeBidirectionalSync() {
    _remoteToLocalSubscription?.cancel();
    _remoteToLocalSubscription = null;

    _localToRemoteSubscription?.cancel();
    _localToRemoteSubscription = null;

    _pendingSyncStrokeIds.clear();
    _localChangeDebounceTimer?.cancel();
  }

  Future<void> _handleRemoteToLocalSync(
    List<DrawingStroke> remoteStrokes,
  ) async {
    if (!_isOnline) return;

    try {
      for (final stroke in remoteStrokes) {
        if (_pendingSyncStrokeIds.contains(stroke.id)) {
          continue;
        }

        try {
          await _localRepository.updateStrokeFromRemote(
            stroke.sessionId,
            stroke,
          );
          if (kDebugMode) {
            print('Synced remote stroke to local: ${stroke.id}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Failed to sync remote stroke to local: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in remote to local sync: $e');
      }
    }
  }

  Future<void> _handleLocalToRemoteSync(
    List<DrawingStroke> localStrokes,
  ) async {
    if (!_isOnline) return;

    try {
      for (final stroke in localStrokes) {
        if (_pendingSyncStrokeIds.contains(stroke.id) ||
            stroke.syncStatus == 'synced') {
          continue;
        }

        if (_failedSyncStrokes.containsKey(stroke.id)) {
          final lastFailure = _failedSyncStrokes[stroke.id]!;
          if (DateTime.now().difference(lastFailure).inMinutes < 5) {
            continue;
          }
        }

        _pendingSyncStrokeIds.add(stroke.id);

        try {
          final result = await _remoteRepository.addStroke(
            stroke.sessionId,
            stroke,
          );

          final serverId = result['id'] as String;
          final serverVersion = result['version'] as int;
          final serverCreatedAt = DateTime.parse(result['created_at']);

          await _localRepository.updateStrokeSyncStatus(
            stroke.id,
            serverId,
            serverVersion,
            serverCreatedAt,
          );

          _failedSyncStrokes.remove(stroke.id);

          if (kDebugMode) {
            print('Synced local stroke to remote: ${stroke.id}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Failed to sync local stroke to remote: $e');
          }
          _failedSyncStrokes[stroke.id] = DateTime.now();
        } finally {
          _pendingSyncStrokeIds.remove(stroke.id);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in local to remote sync: $e');
      }
    }
  }

  void _retryRemoteToLocalSync() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_isOnline) {
        _disposeBidirectionalSync();
        _setupBidirectionalSync();
      }
    });
  }

  void _retryLocalToRemoteSync() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_isOnline) {
        _disposeBidirectionalSync();
        _setupBidirectionalSync();
      }
    });
  }

  Future<void> dispose() async {
    _disposeBidirectionalSync();
    _connectivitySubscription?.cancel();
    _cleanupTimer?.cancel();
    await _connectivityController.close();
    await _localRepository.close();
  }

  Future<CanvasSession?> getSession(String sessionId) async {
    if (!_isOnline) {
      throw Exception(
        'No internet connection. Cannot join sessions while offline. Please check your connection and try again.',
      );
    }

    try {
      final remoteSession = await _remoteRepository.getSession(sessionId);
      return remoteSession;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get session from remote: $e');
      }
      rethrow;
    }
  }

  Future<CanvasSession?> createSession(
    String userId,
    String sessionId, {
    String? title,
  }) async {
    if (!_isOnline) {
      throw Exception(
        'No internet connection. Cannot create sessions while offline. Please check your connection and try again.',
      );
    }

    try {
      final remoteSession = await _remoteRepository.createSession(
        userId,
        sessionId,
        title: title,
      );

      return remoteSession;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to create session on remote: $e');
      }
      rethrow;
    }
  }

  Future<void> addStroke(String sessionId, DrawingStroke stroke) async {
    try {
      if (_isOnline) {
        final result = await _remoteRepository.addStroke(sessionId, stroke);
        final serverId = result['id'] as String;
        final serverVersion = result['version'] as int;
        final serverCreatedAt = DateTime.parse(result['created_at']);

        final onlineStroke = stroke.copyWith(
          id: serverId,
          version: serverVersion,
          createdAt: serverCreatedAt,
        );

        await _localRepository.addStroke(sessionId, onlineStroke);
      } else {
        await _localRepository.addStroke(sessionId, stroke);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to add stroke: $e');
      }
      rethrow;
    }
  }

  Stream<List<DrawingStroke>> watchStrokes(String sessionId) {
    if (_isOnline) {
      return _remoteRepository.watchStrokesForSession(sessionId);
    } else {
      return _localRepository.watchStrokes(sessionId);
    }
  }

  Future<List<DrawingStroke>> getStrokesForSession(String sessionId) async {
    try {
      if (_isOnline) {
        final remoteStrokes = await _remoteRepository.getStrokesForSession(
          sessionId,
        );
        return remoteStrokes;
      } else {
        final localStrokes = await _localRepository.getActiveStrokesForSession(
          sessionId,
        );
        return localStrokes
            .map((stroke) => DrawingStroke.fromJson(stroke.toJson()))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get strokes for session: $e');
      }

      try {
        final localStrokes = await _localRepository.getActiveStrokesForSession(
          sessionId,
        );
        return localStrokes
            .map((stroke) => DrawingStroke.fromJson(stroke.toJson()))
            .toList();
      } catch (localError) {
        if (kDebugMode) {
          print('Failed to get strokes from local: $localError');
        }
        return [];
      }
    }
  }

  Future<bool> canUndo(String sessionId) async {
    try {
      if (_isOnline) {
        return await _remoteRepository.canUndo(sessionId);
      } else {
        return await _localRepository.canUndo(sessionId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to check if can undo: $e');
      }

      try {
        return await _localRepository.canUndo(sessionId);
      } catch (localError) {
        if (kDebugMode) {
          print('Failed to check if can undo from local: $localError');
        }
        return false;
      }
    }
  }

  Future<bool> canRedo(String sessionId) async {
    try {
      if (_isOnline) {
        return await _remoteRepository.canRedo(sessionId);
      } else {
        return await _localRepository.canRedo(sessionId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to check if can redo: $e');
      }

      try {
        return await _localRepository.canRedo(sessionId);
      } catch (localError) {
        if (kDebugMode) {
          print('Failed to check if can redo from local: $localError');
        }
        return false;
      }
    }
  }

  Future<void> _recoverOfflineStrokes() async {
    if (!_isOnline || _activeSessionId == null) return;

    try {
      await _recoverSessionOfflineStrokes(_activeSessionId!);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to recover offline strokes: $e');
      }
    }
  }

  Future<void> _recoverSessionOfflineStrokes(String sessionId) async {
    try {
      final existingSession = await _remoteRepository.getSession(sessionId);
      if (existingSession == null) {
        if (kDebugMode) {
          print('Session $sessionId not found in remote, skipping recovery');
        }
        return;
      }

      final offlineStrokes = await _localRepository.getOfflineStrokes(
        sessionId,
      );

      if (offlineStrokes.isEmpty) {
        if (kDebugMode) {
          print('No offline strokes to recover for session $sessionId');
        }
        return;
      }

      if (kDebugMode) {
        print(
          'Recovering ${offlineStrokes.length} offline strokes for session $sessionId',
        );
      }

      for (final stroke in offlineStrokes) {
        try {
          final result = await _remoteRepository.addStroke(sessionId, stroke);
          final serverId = result['id'] as String;
          final serverVersion = result['version'] as int;
          final serverCreatedAt = DateTime.parse(result['created_at']);

          await _localRepository.updateStrokeSyncStatus(
            stroke.id,
            serverId,
            serverVersion,
            serverCreatedAt,
          );

          if (kDebugMode) {
            print('Recovered offline stroke: ${stroke.id}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Failed to recover stroke ${stroke.id}: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to recover offline strokes for session $sessionId: $e');
      }
    }
  }
}
