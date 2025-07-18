import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/canvas/cubit/canvas_state.dart';
import 'tools_state.dart';

class ToolsCubit extends Cubit<ToolsState> {
  ToolsCubit() : super(const ToolsState());

  void selectTool(DrawingTool tool) {
    emit(state.copyWith(selectedTool: tool));
  }

  void selectBrush() {
    selectTool(DrawingTool.brush);
  }

  void selectEraser() {
    selectTool(DrawingTool.eraser);
  }

  void selectRectangle() {
    selectTool(DrawingTool.rectangle);
  }

  void selectCircle() {
    selectTool(DrawingTool.circle);
  }

  void selectLine() {
    selectTool(DrawingTool.line);
  }

  void selectColor(Color color) {
    emit(state.copyWith(selectedColor: color));
  }

  void toggleColorPicker() {
    emit(state.copyWith(isColorPickerOpen: !state.isColorPickerOpen));
  }

  void closeColorPicker() {
    emit(state.copyWith(isColorPickerOpen: false));
  }

  void setStrokeWidth(double width) {
    emit(state.copyWith(strokeWidth: width));
  }

  void toggleStrokeWidthSlider() {
    emit(
      state.copyWith(isStrokeWidthSliderOpen: !state.isStrokeWidthSliderOpen),
    );
  }

  void closeStrokeWidthSlider() {
    emit(state.copyWith(isStrokeWidthSliderOpen: false));
  }

  void increaseStrokeWidth() {
    final currentIndex = state.availableStrokeWidths.indexOf(state.strokeWidth);
    if (currentIndex < state.availableStrokeWidths.length - 1) {
      final newWidth = state.availableStrokeWidths[currentIndex + 1];
      setStrokeWidth(newWidth);
    }
  }

  void decreaseStrokeWidth() {
    final currentIndex = state.availableStrokeWidths.indexOf(state.strokeWidth);
    if (currentIndex > 0) {
      final newWidth = state.availableStrokeWidths[currentIndex - 1];
      setStrokeWidth(newWidth);
    }
  }

  void selectBlack() => selectColor(Colors.black);
  void selectRed() => selectColor(Colors.red);
  void selectBlue() => selectColor(Colors.blue);
  void selectGreen() => selectColor(Colors.green);
  void selectYellow() => selectColor(Colors.yellow);
  void selectOrange() => selectColor(Colors.orange);
  void selectPurple() => selectColor(Colors.purple);
  void selectPink() => selectColor(Colors.pink);
  void selectBrown() => selectColor(Colors.brown);
  void selectGrey() => selectColor(Colors.grey);

  void resetToDefaults() {
    emit(const ToolsState());
  }
}
