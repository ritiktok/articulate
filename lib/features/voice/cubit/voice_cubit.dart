import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:app_settings/app_settings.dart';

import '../../../features/canvas/cubit/canvas_cubit.dart';
import '../../../features/tools/cubit/tools_cubit.dart';
import 'voice_state.dart';
import 'dart:math';

class VoiceCubit extends Cubit<VoiceState> {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final CanvasCubit? _canvasCubit;
  final ToolsCubit? _toolsCubit;

  bool _speechRecognitionReady = false;

  VoiceCubit({CanvasCubit? canvasCubit, ToolsCubit? toolsCubit})
    : _canvasCubit = canvasCubit,
      _toolsCubit = toolsCubit,
      super(const VoiceState()) {
    Future.delayed(const Duration(seconds: 1), () => _initializeVoice());
  }

  @override
  Future<void> close() async {
    await _stopRecording();
    await _stopSpeaking();
    await _flutterTts.stop();
    super.close();
  }

  Future<void> _initializeVoice() async {
    try {
      await _initializeTTS().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw Exception('TTS initialization timed out');
        },
      );

      await _checkPermissions().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          throw Exception('Permission check timed out');
        },
      );

      if (state.hasPermission) {
        try {
          await _initializeSpeechRecognition().timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              throw Exception('Speech recognition initialization timed out');
            },
          );
        } catch (e) {
          _speechRecognitionReady = false;
        }
      } else {
        _speechRecognitionReady = false;
      }

      emit(state.copyWith(isVoiceEnabled: true));
    } catch (e) {
      emit(state.copyWith(isVoiceEnabled: false));
    }
  }

  Future<void> _initializeSpeechRecognition() async {
    try {
      _speechRecognitionReady = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (!state.isListening) {
              emit(
                state.copyWith(status: VoiceStatus.idle, isListening: false),
              );
            }
          } else if (status == 'listening') {
            emit(
              state.copyWith(status: VoiceStatus.listening, isListening: true),
            );
          }
        },
      );
    } catch (e) {
      _speechRecognitionReady = false;
    }
  }

  Future<void> _initializeTTS() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.8);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _flutterTts.setStartHandler(() {
        emit(state.copyWith(status: VoiceStatus.speaking, isSpeaking: true));
      });
      _flutterTts.setCompletionHandler(() {
        emit(state.copyWith(status: VoiceStatus.idle, isSpeaking: false));
      });
      _flutterTts.setErrorHandler((msg) {
        emit(
          state.copyWith(
            status: VoiceStatus.error,
            isSpeaking: false,
            errorMessage: 'TTS Error: $msg',
          ),
        );
      });
    } catch (e) {
      if (kDebugMode) {
        print('TTS initialization error: $e');
      }
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final microphoneStatus = await Permission.microphone.status;

      if (microphoneStatus.isDenied) {
        emit(state.copyWith(hasPermission: false));
      } else if (microphoneStatus.isPermanentlyDenied) {
        emit(
          state.copyWith(
            hasPermission: false,
            errorMessage:
                'Microphone permission is required. Please enable it in Settings > Privacy & Security > Microphone.',
          ),
        );
      } else {
        emit(state.copyWith(hasPermission: microphoneStatus.isGranted));
      }
    } catch (e) {
      emit(
        state.copyWith(
          hasPermission: false,
          errorMessage: 'Permission check failed: $e',
        ),
      );
    }
  }

  Future<void> openAppSettings() async {
    await AppSettings.openAppSettings();
  }

  Future<void> startListening() async {
    if (!state.canStartListening || !_speechRecognitionReady) return;
    try {
      emit(
        state.copyWith(
          status: VoiceStatus.listening,
          isListening: true,
          currentTranscription: null,
          errorMessage: null,
          audioLevel: 0.0,
        ),
      );

      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            final transcription = result.recognizedWords;
            if (transcription.isNotEmpty) {
              emit(
                state.copyWith(
                  lastTranscription: transcription,
                  currentTranscription: null,
                  audioLevel: 0.0,
                ),
              );
              _parseAndExecuteCommand(transcription);
            }
          } else {
            final audioLevel = (result.recognizedWords.length * 2.0).clamp(
              0.0,
              100.0,
            );
            emit(
              state.copyWith(
                currentTranscription: result.recognizedWords,
                audioLevel: audioLevel,
              ),
            );
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 10),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
        ),
        localeId: 'en_US',
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: VoiceStatus.error,
          isListening: false,
          errorMessage: 'Failed to start listening: $e',
          audioLevel: 0.0,
        ),
      );
    }
  }

  Future<void> stopListening() async {
    if (!state.canStopListening) return;
    try {
      await _speechToText.stop();
      emit(state.copyWith(status: VoiceStatus.idle, isListening: false));
    } catch (e) {
      emit(
        state.copyWith(
          status: VoiceStatus.error,
          isListening: false,
          errorMessage: 'Failed to stop listening: $e',
        ),
      );
    }
  }

  Future<void> _parseAndExecuteCommand(String transcription) async {
    if (transcription.isEmpty) {
      emit(state.copyWith(status: VoiceStatus.idle));
      return;
    }

    final command = _parseVoiceCommand(transcription);
    final updatedHistory = [command, ...state.commandHistory.take(9)];

    emit(state.copyWith(lastCommand: command, commandHistory: updatedHistory));

    await _executeVoiceCommand(command);

    await _speakCommandFeedback(command);
  }

  VoiceCommand _parseVoiceCommand(String transcription) {
    final lowerText = transcription.toLowerCase();

    final toolPatterns = {
      'brush': ['brush', 'pen'],
      'eraser': ['eraser', 'erase'],
      'rectangle': ['rectangle', 'square'],
      'circle': ['circle', 'round'],
      'line': ['line'],
    };

    final colorPatterns = {
      'red': ['red'],
      'blue': ['blue'],
      'green': ['green'],
      'black': ['black'],
      'yellow': ['yellow'],
      'orange': ['orange'],
      'purple': ['purple'],
      'pink': ['pink'],
    };

    final strokeWidthPatterns = {
      'increase': ['thick', 'thicker'],
      'decrease': ['thin', 'thinner'],
    };

    final shapePatterns = {
      'circle': ['circle'],
      'rectangle': ['rectangle', 'square'],
      'line': ['line'],
    };

    for (final entry in toolPatterns.entries) {
      if (entry.value.any((pattern) => lowerText.contains(pattern))) {
        return VoiceCommand(
          type: VoiceCommandType.toolSelection,
          command: transcription,
          parameters: {'tool': entry.key},
          timestamp: DateTime.now(),
        );
      }
    }

    for (final entry in colorPatterns.entries) {
      if (entry.value.any((pattern) => lowerText.contains(pattern))) {
        return VoiceCommand(
          type: VoiceCommandType.colorChange,
          command: transcription,
          parameters: {'color': entry.key},
          timestamp: DateTime.now(),
        );
      }
    }

    for (final entry in strokeWidthPatterns.entries) {
      if (entry.value.any((pattern) => lowerText.contains(pattern))) {
        return VoiceCommand(
          type: VoiceCommandType.strokeWidthChange,
          command: transcription,
          parameters: {'action': entry.key},
          timestamp: DateTime.now(),
        );
      }
    }

    if (lowerText.contains('draw')) {
      for (final entry in shapePatterns.entries) {
        if (entry.value.any((pattern) => lowerText.contains(pattern))) {
          return VoiceCommand(
            type: VoiceCommandType.shapeDrawing,
            command: transcription,
            parameters: {'shape': entry.key},
            timestamp: DateTime.now(),
          );
        }
      }
    }

    if (!lowerText.contains('tool')) {
      for (final entry in shapePatterns.entries) {
        if (entry.value.any((pattern) => lowerText.contains(pattern))) {
          return VoiceCommand(
            type: VoiceCommandType.shapeDrawing,
            command: transcription,
            parameters: {'shape': entry.key},
            timestamp: DateTime.now(),
          );
        }
      }
    }

    if (lowerText.contains('suggest') || lowerText.contains('idea')) {
      return VoiceCommand(
        type: VoiceCommandType.aiSuggestion,
        command: transcription,
        parameters: {},
        timestamp: DateTime.now(),
      );
    }

    final actionCommands = {
      'undo': VoiceCommandType.undo,
      'redo': VoiceCommandType.redo,
      'clear': VoiceCommandType.clear,
      'erase all': VoiceCommandType.clear,
    };

    for (final entry in actionCommands.entries) {
      if (lowerText.contains(entry.key)) {
        return VoiceCommand(
          type: entry.value,
          command: transcription,
          parameters: {},
          timestamp: DateTime.now(),
        );
      }
    }

    return VoiceCommand(
      type: VoiceCommandType.unknown,
      command: transcription,
      parameters: {},
      timestamp: DateTime.now(),
    );
  }

  Future<void> _executeVoiceCommand(VoiceCommand command) async {
    switch (command.type) {
      case VoiceCommandType.toolSelection:
        _executeToolSelection(command);
        break;
      case VoiceCommandType.colorChange:
        _executeColorChange(command);
        break;
      case VoiceCommandType.strokeWidthChange:
        _executeStrokeWidthChange(command);
        break;
      case VoiceCommandType.shapeDrawing:
        _executeShapeDrawing(command);
        break;
      case VoiceCommandType.aiSuggestion:
        await _executeAISuggestion(command);
        break;
      case VoiceCommandType.undo:
        await _executeUndo();
        break;
      case VoiceCommandType.redo:
        await _executeRedo();
        break;
      case VoiceCommandType.clear:
        await _executeClear();
        break;
      case VoiceCommandType.unknown:
        break;
    }
  }

  void _executeToolSelection(VoiceCommand command) {
    final tool = command.parameters['tool'] as String?;
    if (tool == null) return;

    if (_toolsCubit != null) {
      switch (tool) {
        case 'brush':
        case 'pen':
          _toolsCubit.selectBrush();
          break;
        case 'eraser':
          _toolsCubit.selectEraser();
          break;
        case 'rectangle':
        case 'square':
          _toolsCubit.selectRectangle();
          break;
        case 'circle':
        case 'round':
          _toolsCubit.selectCircle();
          break;
        case 'line':
          _toolsCubit.selectLine();
          break;
      }
    }

    if (_canvasCubit != null) {
      _canvasCubit.handleVoiceCommand('tool', {'tool': tool});
    }
  }

  void _executeColorChange(VoiceCommand command) {
    final color = command.parameters['color'] as String?;
    if (color == null) return;

    if (_toolsCubit != null) {
      switch (color.toLowerCase()) {
        case 'red':
          _toolsCubit.selectRed();
          break;
        case 'blue':
          _toolsCubit.selectBlue();
          break;
        case 'green':
          _toolsCubit.selectGreen();
          break;
        case 'black':
          _toolsCubit.selectBlack();
          break;
        case 'yellow':
          _toolsCubit.selectYellow();
          break;
        case 'orange':
          _toolsCubit.selectOrange();
          break;
        case 'purple':
          _toolsCubit.selectPurple();
          break;
        case 'pink':
          _toolsCubit.selectPink();
          break;
      }
    }

    if (_canvasCubit != null) {
      _canvasCubit.handleVoiceCommand('color', {'color': color});
    }
  }

  void _executeStrokeWidthChange(VoiceCommand command) {
    final action = command.parameters['action'] as String?;
    if (action == null) return;

    if (_toolsCubit != null) {
      switch (action.toLowerCase()) {
        case 'increase':
        case 'thicker':
          _toolsCubit.increaseStrokeWidth();
          break;
        case 'decrease':
        case 'thinner':
          _toolsCubit.decreaseStrokeWidth();
          break;
      }
    }

    if (_canvasCubit != null) {
      _canvasCubit.handleVoiceCommand('strokeWidth', {'action': action});
    }
  }

  void _executeShapeDrawing(VoiceCommand command) {
    final shape = command.parameters['shape'] as String?;
    if (shape == null || _canvasCubit == null) return;

    _canvasCubit.handleVoiceCommand('shape', {'shape': shape});
  }

  Future<void> _executeAISuggestion(VoiceCommand command) async {
    try {
      emit(state.copyWith(status: VoiceStatus.processing, isProcessing: true));

      await Future.delayed(const Duration(milliseconds: 1500));

      final suggestions = [
        'Try drawing a sunset with mountains in the background',
        'How about a simple flower or tree?',
        'You could draw a house with a garden',
        'Consider drawing geometric shapes like triangles and squares',
        'Try creating a landscape with hills and sky',
        'How about drawing some animals or birds?',
        'You could draw a cityscape with buildings',
        'Try abstract art with flowing lines and curves',
      ];

      final random = Random();
      final suggestion = suggestions[random.nextInt(suggestions.length)];

      emit(
        state.copyWith(
          status: VoiceStatus.speaking,
          isProcessing: false,
          isSpeaking: true,
        ),
      );

      await _speakText(suggestion);

      emit(state.copyWith(status: VoiceStatus.idle, isSpeaking: false));
    } catch (e) {
      emit(
        state.copyWith(
          status: VoiceStatus.error,
          isProcessing: false,
          errorMessage: 'Error generating AI suggestion: $e',
        ),
      );
    }
  }

  Future<void> _executeUndo() async {
    if (_canvasCubit == null) return;
    await _canvasCubit.handleVoiceCommand('undo', {});
  }

  Future<void> _executeRedo() async {
    if (_canvasCubit == null) return;
    await _canvasCubit.handleVoiceCommand('redo', {});
  }

  Future<void> _executeClear() async {
    if (_canvasCubit == null) return;
    await _canvasCubit.handleVoiceCommand('clear', {});
  }

  Future<void> _speakCommandFeedback(VoiceCommand command) async {
    String feedback = '';

    switch (command.type) {
      case VoiceCommandType.toolSelection:
        final tool = command.parameters['tool'] as String?;
        feedback = 'Switched to $tool tool';
        break;
      case VoiceCommandType.colorChange:
        final color = command.parameters['color'] as String?;
        feedback = 'Changed color to $color';
        break;
      case VoiceCommandType.strokeWidthChange:
        final action = command.parameters['action'] as String?;
        feedback = 'Made stroke $action';
        break;
      case VoiceCommandType.shapeDrawing:
        final shape = command.parameters['shape'] as String?;
        feedback = 'Drawing $shape';
        break;
      case VoiceCommandType.undo:
        feedback = 'Undone';
        break;
      case VoiceCommandType.redo:
        feedback = 'Redone';
        break;
      case VoiceCommandType.clear:
        feedback = 'Canvas cleared';
        break;
      case VoiceCommandType.aiSuggestion:
        return;
      case VoiceCommandType.unknown:
        feedback = 'Command not recognized';
        break;
    }

    await _speakText(feedback);
  }

  Future<void> _speakText(String text) async {
    if (text.isEmpty) return;
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      if (kDebugMode) {
        print('TTS error: $e');
      }
    }
  }

  Future<void> _stopSpeaking() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping TTS: $e');
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _speechToText.stop();
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping recording: $e');
      }
    }
  }

  Future<void> toggleVoiceControl() async {
    if (state.isListening) {
      await stopListening();
    } else {
      await startListening();
    }
  }

  Future<void> requestPermissions() async {
    try {
      final status = await Permission.microphone.request();

      if (status.isDenied) {
        final result = await Permission.microphone.request();

        emit(state.copyWith(hasPermission: result.isGranted));

        if (result.isGranted) {
          await _initializeVoice();
        }
      } else if (status.isPermanentlyDenied) {
        emit(
          state.copyWith(
            hasPermission: false,
            errorMessage:
                'Microphone permission is permanently denied. Please enable it in Settings > Privacy & Security > Microphone.',
          ),
        );
      } else if (status.isRestricted) {
        emit(
          state.copyWith(
            hasPermission: false,
            errorMessage: 'Microphone access is restricted by system settings.',
          ),
        );
      } else {
        emit(state.copyWith(hasPermission: status.isGranted));
      }
    } catch (e) {
      emit(
        state.copyWith(
          hasPermission: false,
          errorMessage: 'Failed to request permission: $e',
        ),
      );
    }
  }

  Future<void> speakStatus(String text) async {
    await _speakText(text);
  }

  Future<void> reinitializeVoice() async {
    await _initializeVoice();
  }

  Future<void> refreshPermissionStatus() async {
    await _checkPermissions();
  }

  void hidePermissionOverlay() {
    emit(state.copyWith(showPermissionOverlay: false));
  }

  void showPermissionOverlay() {
    emit(state.copyWith(showPermissionOverlay: true));
  }
}
