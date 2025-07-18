import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../constants/palette.dart';
import '../../../constants/styles.dart';
import '../cubit/tools_cubit.dart';
import '../cubit/tools_state.dart';
import '../../canvas/cubit/canvas_cubit.dart';

class ColorPickerWidget extends StatelessWidget {
  const ColorPickerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ToolsCubit, ToolsState>(
      builder: (context, state) {
        if (!state.isColorPickerOpen) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(Styles.spacingL),
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
                    'Select Color',
                    style: Styles.titleMedium.copyWith(
                      color: Palette.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        context.read<ToolsCubit>().closeColorPicker(),
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
                constraints: const BoxConstraints(
                  maxWidth: 320,
                  maxHeight: 240,
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: Styles.spacingS,
                    mainAxisSpacing: Styles.spacingS,
                    childAspectRatio: 1,
                  ),
                  itemCount: state.availableColors.length,
                  itemBuilder: (context, index) {
                    final color = state.availableColors[index];
                    final isSelected = state.selectedColor == color;

                    return GestureDetector(
                      onTap: () {
                        context.read<ToolsCubit>().selectColor(color);
                        context.read<CanvasCubit>().selectColor(color);
                        context.read<ToolsCubit>().closeColorPicker();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Palette.primary
                                : Palette.outline,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: _getContrastColor(color),
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: Styles.spacingM),

              Container(
                padding: const EdgeInsets.all(Styles.spacingM),
                decoration: BoxDecoration(
                  color: Palette.surfaceVariant,
                  borderRadius: BorderRadius.circular(Styles.radiusM),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: state.selectedColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Palette.outline, width: 2),
                      ),
                    ),
                    const SizedBox(width: Styles.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Color',
                            style: Styles.labelMedium.copyWith(
                              color: Palette.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '#${state.selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                            style: Styles.bodyMedium.copyWith(
                              color: Palette.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

  Color _getContrastColor(Color backgroundColor) {
    double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
