import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../constants/palette.dart';
import '../../../constants/styles.dart';
import '../cubit/tools_cubit.dart';
import '../cubit/tools_state.dart';
import '../../canvas/cubit/canvas_cubit.dart';

class StrokeWidthSliderWidget extends StatelessWidget {
  const StrokeWidthSliderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ToolsCubit, ToolsState>(
      builder: (context, state) {
        if (!state.isStrokeWidthSliderOpen) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(Styles.spacingM),
          decoration: BoxDecoration(
            color: Palette.surface,
            borderRadius: BorderRadius.circular(Styles.radiusL),
            border: Border.all(color: Palette.outlineVariant, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Stroke Width',
                    style: Styles.titleMedium.copyWith(
                      color: Palette.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        context.read<ToolsCubit>().closeStrokeWidthSlider(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Palette.surfaceVariant,
                      foregroundColor: Palette.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Styles.spacingM),
              Container(
                padding: const EdgeInsets.all(Styles.spacingM),
                decoration: BoxDecoration(
                  color: Palette.primaryContainer,
                  borderRadius: BorderRadius.circular(Styles.radiusM),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.line_weight,
                      color: Palette.onPrimaryContainer,
                      size: 24,
                    ),
                    const SizedBox(width: Styles.spacingS),
                    Text(
                      '${state.strokeWidth.toInt()}px',
                      style: Styles.titleMedium.copyWith(
                        color: Palette.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Styles.spacingM),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      context.read<ToolsCubit>().decreaseStrokeWidth();
                      final newWidth =
                          state.availableStrokeWidths[state
                                  .availableStrokeWidths
                                  .indexOf(state.strokeWidth) -
                              1];
                      context.read<CanvasCubit>().setStrokeWidth(newWidth);
                    },
                    icon: const Icon(Icons.remove),
                    style: IconButton.styleFrom(
                      backgroundColor: Palette.surfaceVariant,
                      foregroundColor: Palette.onSurfaceVariant,
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                  const SizedBox(width: Styles.spacingS),
                  SizedBox(
                    width: 200,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Palette.primary,
                        inactiveTrackColor: Palette.outlineVariant,
                        thumbColor: Palette.primary,
                        overlayColor: Palette.primary.withValues(alpha: 0.1),
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                          elevation: 2,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                      ),
                      child: Slider(
                        value: state.strokeWidth,
                        min: state.availableStrokeWidths.first,
                        max: state.availableStrokeWidths.last,
                        divisions: state.availableStrokeWidths.length - 1,
                        onChanged: (value) {
                          double closest = state.availableStrokeWidths.first;
                          double minDistance = double.infinity;

                          for (double width in state.availableStrokeWidths) {
                            double distance = (value - width).abs();
                            if (distance < minDistance) {
                              minDistance = distance;
                              closest = width;
                            }
                          }

                          context.read<ToolsCubit>().setStrokeWidth(closest);
                          context.read<CanvasCubit>().setStrokeWidth(closest);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: Styles.spacingS),

                  IconButton(
                    onPressed: () {
                      context.read<ToolsCubit>().increaseStrokeWidth();
                      final newWidth =
                          state.availableStrokeWidths[state
                                  .availableStrokeWidths
                                  .indexOf(state.strokeWidth) +
                              1];
                      context.read<CanvasCubit>().setStrokeWidth(newWidth);
                    },
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: Palette.surfaceVariant,
                      foregroundColor: Palette.onSurfaceVariant,
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Styles.spacingS),

              Container(
                padding: const EdgeInsets.all(Styles.spacingM),
                decoration: BoxDecoration(
                  color: Palette.surfaceVariant,
                  borderRadius: BorderRadius.circular(Styles.radiusM),
                ),
                child: Column(
                  children: [
                    Text(
                      'Preview',
                      style: Styles.labelMedium.copyWith(
                        color: Palette.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Styles.spacingS),
                    Container(
                      height: 40,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Palette.surface,
                        borderRadius: BorderRadius.circular(Styles.radiusS),
                        border: Border.all(
                          color: Palette.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          height: state.strokeWidth,
                          width: 200,
                          decoration: BoxDecoration(
                            color: state.selectedColor,
                            borderRadius: BorderRadius.circular(
                              state.strokeWidth / 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
