import 'dart:async';
import 'package:articulate/data/repositories/supabase_canvas_repository.dart';
import 'package:articulate/features/canvas/cubit/canvas_state.dart';
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
  bool _isInitialSyncComplete = false;
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();
  final StreamController<SyncStatus> _syncStatusController =
      StreamController<SyncStatus>.broadcast();

  StreamSubscription<List<DrawingStroke>>? _remoteToLocalSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  HybridCanvasRepository({
    required DriftCanvasRepository localRepository,
    required SupabaseCanvasRepository remoteRepository,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository {
    _initializeConnectivity();
  }

  Stream<bool> get connectivityStream => _connectivityController.stream;
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  bool get isOnline => _isOnline;

  void setActiveSession(String sessionId) {
    _activeSessionId = sessionId;
    _isInitialSyncComplete = false;
    if (_isOnline) {
      _handleOnlineTransition();
    }
  }

  void clearActiveSession() {
    _activeSessionId = null;
    _isInitialSyncComplete = false;
    _disposeRemoteToLocalSync();
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
          await _handleOnlineTransition();
        } else {
          _disposeRemoteToLocalSync();
          _isInitialSyncComplete = false;
        }
      }
    });
  }

  Future<void> _handleOnlineTransition() async {
    if (!_isOnline || _activeSessionId == null) return;

    try {
      await _syncOfflineStrokes();

      _isInitialSyncComplete = true;

      _setupRemoteToLocalSync();
    } catch (e) {
      if (kDebugMode) {
        print('Error during online transition: $e');
      }
    }
  }

  Future<List<DrawingStroke>> handleOnlineTransitionWithFetch(
    String sessionId,
  ) async {
    if (!_isOnline) return <DrawingStroke>[];

    try {
      await _syncOfflineStrokes();

      _isInitialSyncComplete = true;

      final allStrokes = await _remoteRepository.getAllStrokesForSession(
        sessionId,
      );

      _setupRemoteToLocalSync();

      return allStrokes;
    } catch (e) {
      if (kDebugMode) {
        print('Error during online transition with fetch: $e');
      }
      rethrow;
    }
  }

  void _setupRemoteToLocalSync() {
    if (!_isOnline || _activeSessionId == null || !_isInitialSyncComplete) {
      return;
    }

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
            },
            cancelOnError: false,
          );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to setup remote to local sync: $e');
      }
    }
  }

  void _disposeRemoteToLocalSync() {
    _remoteToLocalSubscription?.cancel();
    _remoteToLocalSubscription = null;
  }

  Future<void> _handleRemoteToLocalSync(
    List<DrawingStroke> remoteStrokes,
  ) async {
    if (!_isOnline || remoteStrokes.isEmpty || !_isInitialSyncComplete) return;

    try {
      await _localRepository.batchUpdateStrokesFromRemote(
        remoteStrokes.first.sessionId,
        remoteStrokes,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in remote to local sync: $e');
      }
    }
  }

  bool _isSyncing = false;

  Future<void> _syncOfflineStrokes() async {
    if (!_isOnline || _activeSessionId == null || _isSyncing) {
      return;
    }

    _isSyncing = true;
    try {
      _syncStatusController.add(SyncStatus.syncing);

      final offlineStrokes = await _localRepository.getOfflineStrokes(
        _activeSessionId!,
      );

      if (offlineStrokes.isEmpty) {
        _syncStatusController.add(SyncStatus.synced);
        return;
      }

      final strokesToSync = offlineStrokes
          .where((stroke) => stroke.version == null)
          .toList();

      if (strokesToSync.isEmpty) {
        _syncStatusController.add(SyncStatus.synced);
        return;
      }

      for (final stroke in strokesToSync) {
        try {
          final result = await _remoteRepository.addStroke(
            _activeSessionId!,
            stroke,
          );

          final serverVersion = result['version'] as int;
          final serverCreatedAt = DateTime.parse(result['created_at']);

          await _localRepository.updateStrokeSyncStatus(
            stroke.id,
            serverVersion,
            serverCreatedAt,
          );

          if (kDebugMode) {
            print('Synced offline stroke: ${stroke.id}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Failed to sync stroke ${stroke.id}: $e');
          }
        }
      }

      _syncStatusController.add(SyncStatus.synced);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to sync offline strokes: $e');
      }
      _syncStatusController.add(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> dispose() async {
    _disposeRemoteToLocalSync();
    _connectivitySubscription?.cancel();
    await _connectivityController.close();
    await _syncStatusController.close();
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
    return _localRepository.watchStrokes(sessionId);
  }

  Future<List<DrawingStroke>> getStrokesForSession(String sessionId) async {
    return await _localRepository.getActiveStrokes(sessionId);
  }

  Future<bool> canUndo(String sessionId) async {
    return await _localRepository.canUndo(sessionId);
  }

  Future<bool> canRedo(String sessionId) async {
    return await _localRepository.canRedo(sessionId);
  }
}
