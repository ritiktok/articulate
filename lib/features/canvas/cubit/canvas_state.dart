import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../data/models/drawing_stroke.dart';
import '../../../data/models/canvas_session.dart';

enum CanvasStatus { initial, loading, connected, disconnected, error }

enum DrawingTool { brush, eraser, rectangle, circle, line }

class CanvasState extends Equatable {
  final CanvasStatus status;
  final CanvasSession? currentSession;
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;
  final DrawingTool selectedTool;
  final Color selectedColor;
  final double strokeWidth;
  final bool isConnected;
  final String? errorMessage;
  final bool isAnalyzing;
  final String? aiError;
  final bool canUndo;
  final bool canRedo;

  const CanvasState({
    this.status = CanvasStatus.initial,
    this.currentSession,
    this.strokes = const [],
    this.currentStroke,
    this.selectedTool = DrawingTool.brush,
    this.selectedColor = Colors.black,
    this.strokeWidth = 5.0,
    this.isConnected = false,
    this.errorMessage,
    this.isAnalyzing = false,
    this.aiError,
    this.canUndo = false,
    this.canRedo = false,
  });

  @override
  List<Object?> get props => [
    status,
    currentSession,
    strokes,
    currentStroke,
    selectedTool,
    selectedColor,
    strokeWidth,
    isConnected,
    errorMessage,
    isAnalyzing,
    aiError,
    canUndo,
    canRedo,
  ];

  CanvasState copyWith({
    CanvasStatus? status,
    CanvasSession? currentSession,
    List<DrawingStroke>? strokes,
    DrawingStroke? currentStroke,
    DrawingTool? selectedTool,
    Color? selectedColor,
    double? strokeWidth,
    bool? isConnected,
    String? errorMessage,
    bool? isAnalyzing,
    String? aiError,
    bool? canUndo,
    bool? canRedo,
  }) {
    return CanvasState(
      status: status ?? this.status,
      currentSession: currentSession ?? this.currentSession,
      strokes: strokes ?? this.strokes,
      currentStroke: currentStroke ?? this.currentStroke,
      selectedTool: selectedTool ?? this.selectedTool,
      selectedColor: selectedColor ?? this.selectedColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isConnected: isConnected ?? this.isConnected,
      errorMessage: errorMessage ?? this.errorMessage,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      aiError: aiError ?? this.aiError,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
    );
  }

  List<String> get currentStrokeIds =>
      strokes.map((stroke) => stroke.id).toList();
}
