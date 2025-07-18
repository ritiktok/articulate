import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum VoiceStatus { idle, listening, processing, speaking, error }

enum VoiceCommandType {
  toolSelection,
  colorChange,
  strokeWidthChange,
  shapeDrawing,
  aiSuggestion,
  undo,
  redo,
  clear,
  unknown,
}

class VoiceCommand extends Equatable {
  final VoiceCommandType type;
  final String command;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;

  const VoiceCommand({
    required this.type,
    required this.command,
    this.parameters = const {},
    required this.timestamp,
  });

  @override
  List<Object?> get props => [type, command, parameters, timestamp];
}

class VoiceState extends Equatable {
  final VoiceStatus status;
  final bool isListening;
  final bool isProcessing;
  final bool isSpeaking;
  final String? currentTranscription;
  final String? lastTranscription;
  final VoiceCommand? lastCommand;
  final List<VoiceCommand> commandHistory;
  final String? errorMessage;
  final bool isVoiceEnabled;
  final bool hasPermission;
  final bool showPermissionOverlay;
  final double audioLevel;

  const VoiceState({
    this.status = VoiceStatus.idle,
    this.isListening = false,
    this.isProcessing = false,
    this.isSpeaking = false,
    this.currentTranscription,
    this.lastTranscription,
    this.lastCommand,
    this.commandHistory = const [],
    this.errorMessage,
    this.isVoiceEnabled = false,
    this.hasPermission = false,
    this.showPermissionOverlay = true,
    this.audioLevel = 0.0,
  });

  @override
  List<Object?> get props => [
    status,
    isListening,
    isProcessing,
    isSpeaking,
    currentTranscription,
    lastTranscription,
    lastCommand,
    commandHistory,
    errorMessage,
    isVoiceEnabled,
    hasPermission,
    showPermissionOverlay,
    audioLevel,
  ];

  VoiceState copyWith({
    VoiceStatus? status,
    bool? isListening,
    bool? isProcessing,
    bool? isSpeaking,
    String? currentTranscription,
    String? lastTranscription,
    VoiceCommand? lastCommand,
    List<VoiceCommand>? commandHistory,
    String? errorMessage,
    bool? isVoiceEnabled,
    bool? hasPermission,
    bool? showPermissionOverlay,
    double? audioLevel,
  }) {
    return VoiceState(
      status: status ?? this.status,
      isListening: isListening ?? this.isListening,
      isProcessing: isProcessing ?? this.isProcessing,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      currentTranscription: currentTranscription ?? this.currentTranscription,
      lastTranscription: lastTranscription ?? this.lastTranscription,
      lastCommand: lastCommand ?? this.lastCommand,
      commandHistory: commandHistory ?? this.commandHistory,
      errorMessage: errorMessage ?? this.errorMessage,
      isVoiceEnabled: isVoiceEnabled ?? this.isVoiceEnabled,
      hasPermission: hasPermission ?? this.hasPermission,
      showPermissionOverlay:
          showPermissionOverlay ?? this.showPermissionOverlay,
      audioLevel: audioLevel ?? this.audioLevel,
    );
  }

  bool get canStartListening =>
      isVoiceEnabled &&
      hasPermission &&
      !isListening &&
      !isProcessing &&
      !isSpeaking;

  bool get canStopListening => isListening;

  bool get isActive => isListening || isProcessing || isSpeaking;

  String get statusText {
    switch (status) {
      case VoiceStatus.idle:
        return 'Voice control ready';
      case VoiceStatus.listening:
        return 'Listening...';
      case VoiceStatus.processing:
        return 'Processing...';
      case VoiceStatus.speaking:
        return 'Speaking...';
      case VoiceStatus.error:
        return 'Error: ${errorMessage ?? "Unknown error"}';
    }
  }

  IconData get statusIcon {
    switch (status) {
      case VoiceStatus.idle:
        return Icons.mic;
      case VoiceStatus.listening:
        return Icons.mic;
      case VoiceStatus.processing:
        return Icons.hourglass_empty;
      case VoiceStatus.speaking:
        return Icons.volume_up;
      case VoiceStatus.error:
        return Icons.error;
    }
  }

  Color get statusColor {
    switch (status) {
      case VoiceStatus.idle:
        return Colors.grey;
      case VoiceStatus.listening:
        return Colors.red;
      case VoiceStatus.processing:
        return Colors.orange;
      case VoiceStatus.speaking:
        return Colors.blue;
      case VoiceStatus.error:
        return Colors.red;
    }
  }
}
