import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../features/canvas/cubit/canvas_state.dart';

class ToolsState extends Equatable {
  final DrawingTool selectedTool;
  final Color selectedColor;
  final double strokeWidth;
  final bool isColorPickerOpen;
  final bool isStrokeWidthSliderOpen;
  final List<Color> availableColors;
  final List<double> availableStrokeWidths;

  const ToolsState({
    this.selectedTool = DrawingTool.brush,
    this.selectedColor = Colors.black,
    this.strokeWidth = 5.0,
    this.isColorPickerOpen = false,
    this.isStrokeWidthSliderOpen = false,
    this.availableColors = const [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.brown,
      Colors.grey,
    ],
    this.availableStrokeWidths = const [1.0, 3.0, 5.0, 8.0, 12.0, 16.0, 20.0],
  });

  @override
  List<Object?> get props => [
    selectedTool,
    selectedColor,
    strokeWidth,
    isColorPickerOpen,
    isStrokeWidthSliderOpen,
    availableColors,
    availableStrokeWidths,
  ];

  ToolsState copyWith({
    DrawingTool? selectedTool,
    Color? selectedColor,
    double? strokeWidth,
    bool? isColorPickerOpen,
    bool? isStrokeWidthSliderOpen,
    List<Color>? availableColors,
    List<double>? availableStrokeWidths,
  }) {
    return ToolsState(
      selectedTool: selectedTool ?? this.selectedTool,
      selectedColor: selectedColor ?? this.selectedColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isColorPickerOpen: isColorPickerOpen ?? this.isColorPickerOpen,
      isStrokeWidthSliderOpen:
          isStrokeWidthSliderOpen ?? this.isStrokeWidthSliderOpen,
      availableColors: availableColors ?? this.availableColors,
      availableStrokeWidths:
          availableStrokeWidths ?? this.availableStrokeWidths,
    );
  }

  bool get isBrushSelected => selectedTool == DrawingTool.brush;
  bool get isEraserSelected => selectedTool == DrawingTool.eraser;
  bool get isShapeSelected =>
      selectedTool == DrawingTool.rectangle ||
      selectedTool == DrawingTool.circle ||
      selectedTool == DrawingTool.line;

  String get toolName {
    switch (selectedTool) {
      case DrawingTool.brush:
        return 'Brush';
      case DrawingTool.eraser:
        return 'Eraser';
      case DrawingTool.rectangle:
        return 'Rectangle';
      case DrawingTool.circle:
        return 'Circle';
      case DrawingTool.line:
        return 'Line';
    }
  }

  IconData get toolIcon {
    switch (selectedTool) {
      case DrawingTool.brush:
        return Icons.brush;
      case DrawingTool.eraser:
        return Icons.auto_fix_high;
      case DrawingTool.rectangle:
        return Icons.crop_square;
      case DrawingTool.circle:
        return Icons.circle;
      case DrawingTool.line:
        return Icons.show_chart;
    }
  }
}
