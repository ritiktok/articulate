import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../constants/assets.dart';

part 'animation_state.dart';

class AnimationCubit extends Cubit<AnimationState> {
  AnimationCubit() : super(const AnimationState());

  final Map<String, AnimationController> _toolbarControllers = {};
  AnimationController? _canvasRippleController;

  Map<String, AnimationController> get toolbarControllers =>
      _toolbarControllers;
  AnimationController? get canvasRippleController => _canvasRippleController;

  static const Map<String, String> _toolAnimations = {
    'brush': Assets.brushPulse,
    'eraser': Assets.eraserPulse,
    'rectangle': Assets.rectanglePulse,
    'circle': Assets.circlePulse,
    'line': Assets.linePulse,
  };

  String getAnimationPathForTool(String toolId) {
    return _toolAnimations[toolId] ?? Assets.toolbarPulse;
  }

  @override
  Future<void> close() {
    if (_canvasRippleController != null) {
      _canvasRippleController!.dispose();
    }
    for (final controller in _toolbarControllers.values) {
      controller.dispose();
    }
    _toolbarControllers.clear();
    return super.close();
  }

  void initializeCanvasRipple(AnimationController controller) {
    _canvasRippleController = controller;
    emit(state.copyWith(isCanvasRippleReady: true));
  }

  void initializeToolbarPulse(String toolId, AnimationController controller) {
    _toolbarControllers[toolId] = controller;
    emit(
      state.copyWith(
        toolbarAnimations: Map.from(state.toolbarAnimations)..[toolId] = true,
      ),
    );
  }

  void triggerToolbarPulse(String toolId) {
    final controller = _toolbarControllers[toolId];
    if (controller != null) {
      controller.repeat();
      emit(
        state.copyWith(
          activeToolbarAnimations: Set.from(state.activeToolbarAnimations)
            ..add(toolId),
        ),
      );
    }
  }

  void stopToolbarPulse(String toolId) {
    final controller = _toolbarControllers[toolId];
    if (controller != null) {
      controller.stop();
      emit(
        state.copyWith(
          activeToolbarAnimations: Set.from(state.activeToolbarAnimations)
            ..remove(toolId),
        ),
      );
    }
  }

  void triggerCanvasRipple() {
    if (_canvasRippleController != null) {
      _canvasRippleController!.reset();
      _canvasRippleController!.forward();
      emit(state.copyWith(isCanvasRippleActive: true));

      Future.delayed(_canvasRippleController!.duration!, () {
        emit(state.copyWith(isCanvasRippleActive: false));
      });
    }
  }

  void stopCanvasRipple() {
    if (_canvasRippleController != null) {
      _canvasRippleController!.stop();
      emit(state.copyWith(isCanvasRippleActive: false));
    }
  }

  void pauseCanvasRipple() {
    if (_canvasRippleController != null) {
      _canvasRippleController!.stop();
      emit(state.copyWith(isCanvasRippleActive: false));
    }
  }

  void resumeCanvasRipple() {
    if (_canvasRippleController != null) {
      _canvasRippleController!.forward();
      emit(state.copyWith(isCanvasRippleActive: true));
    }
  }
}
