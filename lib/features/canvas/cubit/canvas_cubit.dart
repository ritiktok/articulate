import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/drawing_stroke.dart';
import '../../../data/models/drawing_point.dart';
import '../../../data/repositories/hybrid_canvas_repository.dart';
import '../services/ai_suggestion_service.dart';
import 'canvas_state.dart';

class CanvasCubit extends Cubit<CanvasState> {
  final HybridCanvasRepository _remoteRepository;
  final String _currentUserId;
  final AISuggestionService _aiService;
  GlobalKey? _canvasKey;

  StreamSubscription? _strokesSubscription;
  StreamSubscription? _hybridConnectivitySubscription;
  StreamSubscription? _syncStatusSubscription;

  CanvasCubit({
    required HybridCanvasRepository remoteRepository,
    required String currentUserId,
  }) : _remoteRepository = remoteRepository,
       _currentUserId = currentUserId,
       _aiService = AISuggestionService(),
       super(const CanvasState());

  void setCanvasKey(GlobalKey canvasKey) {
    _canvasKey = canvasKey;
  }

  String get currentUserId => _currentUserId;

  @override
  Future<void> close() async {
    _strokesSubscription?.cancel();
    _hybridConnectivitySubscription?.cancel();
    _syncStatusSubscription?.cancel();

    return super.close();
  }

  Future<void> connectToSession(
    String sessionId, {
    String? title,
    bool forceCreate = false,
  }) async {
    try {
      emit(
        state.copyWith(
          status: CanvasStatus.loading,
          currentSession: null,
          strokes: [],
          currentStroke: null,
          isConnected: false,
        ),
      );

      _clearSubscriptions();

      if (!forceCreate) {
        try {
          final existingSession = await _remoteRepository
              .getSession(sessionId)
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () {
                  throw Exception('Session fetch timed out');
                },
              );

          if (existingSession != null) {
            emit(
              state.copyWith(
                status: CanvasStatus.connected,
                currentSession: existingSession,
                isConnected: true,
              ),
            );
            _initializeSessionFeatures(existingSession.id);
            return;
          }
        } catch (e) {
          if (kDebugMode) {
            print('Failed to get session, will try to create: $e');
          }
        }
      }

      try {
        final session = await _remoteRepository
            .createSession(_currentUserId, sessionId, title: title)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw Exception('Session creation timed out');
              },
            );
        if (session == null) {
          throw Exception('Session creation failed');
        }
        emit(
          state.copyWith(
            status: CanvasStatus.connected,
            currentSession: session,
            isConnected: true,
          ),
        );

        _initializeSessionFeatures(session.id);
      } catch (e) {
        emit(
          state.copyWith(
            status: CanvasStatus.error,
            errorMessage: 'Failed to create session: $e',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: CanvasStatus.error,
          errorMessage: 'Failed to connect to session: $e',
        ),
      );
    }
  }

  void _clearSubscriptions() {
    _strokesSubscription?.cancel();
    _strokesSubscription = null;
    _hybridConnectivitySubscription?.cancel();
    _hybridConnectivitySubscription = null;
    _syncStatusSubscription?.cancel();
    _syncStatusSubscription = null;

    _remoteRepository.clearActiveSession();
  }

  void _initializeSessionFeatures(String sessionId) {
    Future.microtask(() async {
      try {
        _remoteRepository.setActiveSession(sessionId);
        _startRealTimeStrokeUpdates(sessionId);
        _startHybridConnectivityMonitoring();
        _startSyncStatusMonitoring();
        await _updateUndoRedoState();
      } catch (e) {
        if (kDebugMode) {
          print('Error initializing session features: $e');
        }
      }
    });
  }

  void startDrawing(Offset point) {
    if (state.currentSession == null ||
        state.syncStatus == SyncStatus.syncing) {
      return;
    }

    final stroke = DrawingStroke(
      id: const Uuid().v4(),
      sessionId: state.currentSession!.id,
      userId: _currentUserId,
      points: [
        DrawingPoint(
          point: point,
          color: state.selectedColor,
          strokeWidth: state.strokeWidth,
          toolType: state.selectedTool.name,
          userId: _currentUserId,
          timestamp: DateTime.now(),
        ),
      ],
      createdAt: DateTime.now(),
      operation: 'draw',
      version: null,
    );

    emit(state.copyWith(currentStroke: stroke));
  }

  void continueDrawing(Offset point) {
    if (state.currentStroke == null ||
        state.currentSession == null ||
        state.syncStatus == SyncStatus.syncing) {
      return;
    }

    final newPoint = DrawingPoint(
      point: point,
      color: state.selectedColor,
      strokeWidth: state.strokeWidth,
      toolType: state.selectedTool.name,
      userId: _currentUserId,
      timestamp: DateTime.now(),
    );

    final updatedPoints = [...state.currentStroke!.points, newPoint];
    final updatedStroke = state.currentStroke!.copyWith(points: updatedPoints);

    emit(state.copyWith(currentStroke: updatedStroke));
  }

  Future<void> endDrawing() async {
    if (state.currentStroke == null ||
        state.currentSession == null ||
        state.syncStatus == SyncStatus.syncing) {
      return;
    }

    final stroke = state.currentStroke!;
    final sessionId = state.currentSession!.id;

    final updatedStrokes = [...state.strokes, stroke];
    emit(state.copyWith(currentStroke: null, strokes: updatedStrokes));

    try {
      _addWithRetry(() => _remoteRepository.addStroke(sessionId, stroke));
      await _updateUndoRedoState();
    } catch (e) {
      if (kDebugMode) {
        print('Error saving stroke to remote repository: $e');
      }
    }
  }

  void _startRealTimeStrokeUpdates(String sessionId) {
    _strokesSubscription?.cancel();

    _strokesSubscription = _remoteRepository
        .watchStrokes(sessionId)
        .listen(
          (remoteStrokes) {
            try {
              _updateUndoRedoState();
              emit(state.copyWith(strokes: remoteStrokes));
            } catch (e) {
              if (kDebugMode) {
                print('Error processing real-time stroke updates: $e');
              }
            }
          },
          onError: (error) {
            if (kDebugMode) {
              print('Real-time stroke connection error: $error');
            }
          },
        );
  }

  Future<void> _handleOnlineTransition(String sessionId) async {
    try {
      await _remoteRepository.handleOnlineTransitionWithFetch(sessionId);
    } catch (e) {
      if (kDebugMode) {
        print('Error during online transition: $e');
      }
    }
  }

  Future<void> handleVoiceCommand(
    String command,
    Map<String, dynamic> parameters,
  ) async {
    switch (command) {
      case 'tool':
        _handleToolSelection(parameters['tool'] as String?);
        break;
      case 'color':
        _handleColorChange(parameters['color'] as String?);
        break;
      case 'strokeWidth':
        _handleStrokeWidthChange(parameters['action'] as String?);
        break;
      case 'undo':
        await undo();
        break;
      case 'redo':
        await redo();
        break;
      case 'clear':
        await clear();
        break;
    }
  }

  void selectTool(DrawingTool tool) {
    emit(state.copyWith(selectedTool: tool));
  }

  void selectColor(Color color) {
    emit(state.copyWith(selectedColor: color));
  }

  void setStrokeWidth(double width) {
    emit(state.copyWith(strokeWidth: width));
  }

  void _handleToolSelection(String? tool) {
    if (tool == null) return;

    DrawingTool selectedTool;
    switch (tool.toLowerCase()) {
      case 'brush':
      case 'pen':
        selectedTool = DrawingTool.brush;
        break;
      case 'eraser':
        selectedTool = DrawingTool.eraser;
        break;
      case 'rectangle':
      case 'square':
        selectedTool = DrawingTool.rectangle;
        break;
      case 'circle':
      case 'round':
        selectedTool = DrawingTool.circle;
        break;
      case 'line':
        selectedTool = DrawingTool.line;
        break;
      default:
        return;
    }

    selectTool(selectedTool);
  }

  void _handleColorChange(String? color) {
    if (color == null) return;

    Color selectedColor;
    switch (color.toLowerCase()) {
      case 'red':
        selectedColor = Colors.red;
        break;
      case 'blue':
        selectedColor = Colors.blue;
        break;
      case 'green':
        selectedColor = Colors.green;
        break;
      case 'black':
        selectedColor = Colors.black;
        break;
      case 'yellow':
        selectedColor = Colors.yellow;
        break;
      case 'orange':
        selectedColor = Colors.orange;
        break;
      case 'purple':
        selectedColor = Colors.purple;
        break;
      case 'pink':
        selectedColor = Colors.pink;
        break;
      default:
        return;
    }

    selectColor(selectedColor);
  }

  void _handleStrokeWidthChange(String? action) {
    if (action == null) return;

    double newWidth = state.strokeWidth;
    switch (action.toLowerCase()) {
      case 'increase':
      case 'thicker':
        newWidth = (state.strokeWidth + 2.0).clamp(1.0, 20.0);
        break;
      case 'decrease':
      case 'thinner':
        newWidth = (state.strokeWidth - 2.0).clamp(1.0, 20.0);
        break;
      default:
        return;
    }

    setStrokeWidth(newWidth);
  }

  void _addWithRetry(Future<void> Function() operation) async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 1);

    for (int i = 0; i < maxRetries; i++) {
      try {
        await operation();
        return;
      } catch (e) {
        if (kDebugMode) {
          print('Retry ${i + 1}/$maxRetries failed: $e');
        }

        if (e.toString().contains('connection was closed')) {
          if (kDebugMode) {
            print('Database connection was closed, attempting to reconnect...');
          }

          await Future.delayed(Duration(seconds: 2 * (i + 1)));
        } else if (i == maxRetries - 1) {
          rethrow;
        } else {
          await Future.delayed(retryDelay);
        }
      }
    }
  }

  Future<void> _createOperationStroke(
    String operation, {
    bool isActive = false,
  }) async {
    if (state.currentSession == null) return;

    try {
      String? targetStrokeId;

      final operationStroke = DrawingStroke(
        id: const Uuid().v4(),
        sessionId: state.currentSession!.id,
        userId: _currentUserId,
        points: [],
        createdAt: DateTime.now(),
        operation: operation,
        targetStrokeId: targetStrokeId,
        isActive: isActive,
        version: null,
      );

      await _remoteRepository.addStroke(
        state.currentSession!.id,
        operationStroke,
      );
    } catch (e) {
      throw Exception('Error during $operation operation: $e');
    }
  }

  Future<void> undo() async {
    await _createOperationStroke('undo', isActive: false);
    await _updateUndoRedoState();
  }

  Future<void> redo() async {
    await _createOperationStroke('redo', isActive: true);
    await _updateUndoRedoState();
  }

  Future<void> _updateUndoRedoState() async {
    if (state.currentSession == null) return;

    try {
      final canUndo = await _remoteRepository.canUndo(state.currentSession!.id);
      final canRedo = await _remoteRepository.canRedo(state.currentSession!.id);

      emit(state.copyWith(canUndo: canUndo, canRedo: canRedo));
    } catch (e) {
      if (kDebugMode) {
        print('Error updating undo/redo state: $e');
      }
    }
  }

  Future<void> clear() async {
    await _createOperationStroke('clear', isActive: false);
    await _updateUndoRedoState();
  }

  void _startHybridConnectivityMonitoring() {
    final hybridRepo = _remoteRepository;
    _hybridConnectivitySubscription = hybridRepo.connectivityStream.listen((
      isOnline,
    ) async {
      final wasOffline = !state.isConnected;
      final isNowOnline = isOnline;

      if (state.isConnected != isOnline) {
        emit(state.copyWith(isConnected: isOnline));
      }

      if (wasOffline && isNowOnline && state.currentSession != null) {
        await _handleOnlineTransition(state.currentSession!.id);
      }

      if (state.currentSession != null) {
        _startRealTimeStrokeUpdates(state.currentSession!.id);
      }

      if (isOnline && state.currentSession != null) {
        _attemptSessionRecovery();
      }
    });
  }

  void _startSyncStatusMonitoring() {
    _syncStatusSubscription = _remoteRepository.syncStatusStream.listen((
      syncStatus,
    ) {
      emit(state.copyWith(syncStatus: syncStatus));
    });
  }

  void _attemptSessionRecovery() {
    if (state.currentSession == null) return;

    if (state.status == CanvasStatus.disconnected ||
        state.status == CanvasStatus.error) {
      if (kDebugMode) {
        print(
          'Attempting session recovery for session: ${state.currentSession!.id}',
        );
      }

      Future.microtask(() async {
        try {
          await connectToSession(state.currentSession!.id);
        } catch (e) {
          if (kDebugMode) {
            print('Session recovery failed: $e');
          }
        }
      });
    }
  }

  Future<void> initializeAI() async {
    try {
      await _aiService.initialize();
    } catch (e) {
      emit(state.copyWith(aiError: 'Failed to initialize AI: $e'));
    }
  }

  void clearAIError() {
    emit(state.copyWith(aiError: null));
  }

  void generateNewDrawing() async {
    if (state.strokes.isEmpty) return;

    emit(state.copyWith(isAnalyzing: true, aiError: null));

    try {
      final newStrokes = await _aiService.requestCanvasCompletion(
        state.strokes,
        state.currentSession!.id,
        canvasKey: _canvasKey,
      );

      final updatedStrokes = [...state.strokes, ...newStrokes];
      emit(state.copyWith(strokes: updatedStrokes, isAnalyzing: false));

      for (final stroke in newStrokes) {
        if (state.currentSession != null) {
          final aiStroke = DrawingStroke(
            id: stroke.id,
            sessionId: state.currentSession!.id,
            userId: stroke.userId,
            points: stroke.points,
            createdAt: stroke.createdAt,
            operation: stroke.operation,
            targetStrokeId: stroke.targetStrokeId,
            isActive: stroke.isActive,
            version: null,
          );

          _addWithRetry(
            () =>
                _remoteRepository.addStroke(state.currentSession!.id, aiStroke),
          );
        }
      }

      await _updateUndoRedoState();
    } catch (e) {
      emit(
        state.copyWith(
          isAnalyzing: false,
          aiError: 'AI drawing generation failed: ${e.toString()}',
        ),
      );
    }
  }
}
