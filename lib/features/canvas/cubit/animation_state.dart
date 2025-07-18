part of 'animation_cubit.dart';

class AnimationState extends Equatable {
  final bool isCanvasRippleReady;
  final Map<String, bool> toolbarAnimations;
  final Set<String> activeToolbarAnimations;
  final bool isCanvasRippleActive;

  const AnimationState({
    this.isCanvasRippleReady = false,
    this.toolbarAnimations = const {},
    this.activeToolbarAnimations = const {},
    this.isCanvasRippleActive = false,
  });

  AnimationState copyWith({
    bool? isCanvasRippleReady,
    Map<String, bool>? toolbarAnimations,
    Set<String>? activeToolbarAnimations,
    bool? isCanvasRippleActive,
  }) {
    return AnimationState(
      isCanvasRippleReady: isCanvasRippleReady ?? this.isCanvasRippleReady,
      toolbarAnimations: toolbarAnimations ?? this.toolbarAnimations,
      activeToolbarAnimations:
          activeToolbarAnimations ?? this.activeToolbarAnimations,
      isCanvasRippleActive: isCanvasRippleActive ?? this.isCanvasRippleActive,
    );
  }

  @override
  List<Object?> get props => [
    isCanvasRippleReady,
    toolbarAnimations,
    activeToolbarAnimations,
    isCanvasRippleActive,
  ];
}
