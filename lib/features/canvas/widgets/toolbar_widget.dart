import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import '../../../constants/palette.dart';
import '../../../constants/styles.dart';
import '../cubit/canvas_cubit.dart';
import '../cubit/canvas_state.dart';
import '../cubit/animation_cubit.dart';
import '../../tools/tools.dart';

class AnimatedToolbarWidget extends StatefulWidget {
  const AnimatedToolbarWidget({super.key});

  @override
  State<AnimatedToolbarWidget> createState() => _AnimatedToolbarWidgetState();
}

class _AnimatedToolbarWidgetState extends State<AnimatedToolbarWidget>
    with TickerProviderStateMixin {
  late AnimationCubit _animationCubit;

  @override
  void initState() {
    super.initState();
    _animationCubit = context.read<AnimationCubit>();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Styles.toolbarHeight,
      decoration: BoxDecoration(
        color: Palette.surface,
        border: Border(
          top: BorderSide(color: Palette.outlineVariant, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: BlocBuilder<ToolsCubit, ToolsState>(
              builder: (context, toolsState) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Styles.spacingM,
                    vertical: Styles.spacingXS,
                  ),
                  children: [
                    _AnimatedToolButton(
                      icon: Icons.brush_outlined,
                      label: 'Brush',
                      toolId: 'brush',
                      isSelected: toolsState.selectedTool == DrawingTool.brush,
                      onTap: () {
                        context.read<ToolsCubit>().selectBrush();
                        context.read<CanvasCubit>().selectTool(
                          DrawingTool.brush,
                        );
                        _animationCubit.triggerToolbarPulse('brush');
                      },
                    ),
                    const SizedBox(width: Styles.spacingS),
                    _AnimatedToolButton(
                      icon: Icons.auto_fix_high_outlined,
                      label: 'Eraser',
                      toolId: 'eraser',
                      isSelected: toolsState.selectedTool == DrawingTool.eraser,
                      onTap: () {
                        context.read<ToolsCubit>().selectEraser();
                        context.read<CanvasCubit>().selectTool(
                          DrawingTool.eraser,
                        );
                        _animationCubit.triggerToolbarPulse('eraser');
                      },
                    ),
                    const SizedBox(width: Styles.spacingS),
                    _AnimatedToolButton(
                      icon: Icons.crop_square_outlined,
                      label: 'Rectangle',
                      toolId: 'rectangle',
                      isSelected:
                          toolsState.selectedTool == DrawingTool.rectangle,
                      onTap: () {
                        context.read<ToolsCubit>().selectRectangle();
                        context.read<CanvasCubit>().selectTool(
                          DrawingTool.rectangle,
                        );
                        _animationCubit.triggerToolbarPulse('rectangle');
                      },
                    ),
                    const SizedBox(width: Styles.spacingS),
                    _AnimatedToolButton(
                      icon: Icons.circle_outlined,
                      label: 'Circle',
                      toolId: 'circle',
                      isSelected: toolsState.selectedTool == DrawingTool.circle,
                      onTap: () {
                        context.read<ToolsCubit>().selectCircle();
                        context.read<CanvasCubit>().selectTool(
                          DrawingTool.circle,
                        );
                        _animationCubit.triggerToolbarPulse('circle');
                      },
                    ),
                    const SizedBox(width: Styles.spacingS),
                    _AnimatedToolButton(
                      icon: Icons.show_chart_outlined,
                      label: 'Line',
                      toolId: 'line',
                      isSelected: toolsState.selectedTool == DrawingTool.line,
                      onTap: () {
                        context.read<ToolsCubit>().selectLine();
                        context.read<CanvasCubit>().selectTool(
                          DrawingTool.line,
                        );
                        _animationCubit.triggerToolbarPulse('line');
                      },
                    ),
                  ],
                );
              },
            ),
          ),

          BlocBuilder<ToolsCubit, ToolsState>(
            builder: (context, toolsState) {
              return Container(
                margin: const EdgeInsets.only(right: Styles.spacingM),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          context.read<ToolsCubit>().toggleColorPicker(),
                      child: Container(
                        width: Styles.colorPickerSize,
                        height: Styles.colorPickerSize,
                        decoration: BoxDecoration(
                          color: toolsState.selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Palette.outline, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: toolsState.selectedColor.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.palette_outlined,
                          color: _getContrastColor(toolsState.selectedColor),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: Styles.spacingM),

                    GestureDetector(
                      onTap: () =>
                          context.read<ToolsCubit>().toggleStrokeWidthSlider(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Palette.secondaryContainer,
                          borderRadius: BorderRadius.circular(Styles.radiusM),
                          border: Border.all(
                            color: Palette.outlineVariant,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.line_weight,
                              color: Palette.onSecondaryContainer,
                              size: 14,
                            ),
                            Text(
                              '${toolsState.strokeWidth.toInt()}',
                              style: Styles.labelSmall.copyWith(
                                color: Palette.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getContrastColor(Color backgroundColor) {
    double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

class _AnimatedToolButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String toolId;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimatedToolButton({
    required this.icon,
    required this.label,
    required this.toolId,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AnimatedToolButton> createState() => _AnimatedToolButtonState();
}

class _AnimatedToolButtonState extends State<_AnimatedToolButton>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationCubit _animationCubit;

  @override
  void initState() {
    super.initState();
    _animationCubit = context.read<AnimationCubit>();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationCubit.initializeToolbarPulse(widget.toolId, _animationController);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: Styles.toolButtonSize,
        height: Styles.toolButtonSize,
        decoration: BoxDecoration(
          color: widget.isSelected
              ? Palette.primaryContainer
              : Palette.surfaceVariant,
          borderRadius: BorderRadius.circular(Styles.radiusM),
          border: Border.all(
            color: widget.isSelected ? Palette.primary : Palette.outlineVariant,
            width: widget.isSelected ? 2 : 1,
          ),
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: Palette.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            if (widget.isSelected)
              Positioned.fill(
                child: Lottie.asset(
                  _animationCubit.getAnimationPathForTool(widget.toolId),
                  controller: _animationController,
                  fit: BoxFit.cover,
                  repeat: false,
                ),
              ),

            Center(
              child: Icon(
                widget.icon,
                color: widget.isSelected
                    ? Palette.onPrimaryContainer
                    : Palette.onSurfaceVariant,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
