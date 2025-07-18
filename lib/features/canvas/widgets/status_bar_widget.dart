import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../constants/palette.dart';
import '../../../constants/styles.dart';
import '../cubit/canvas_cubit.dart';
import '../cubit/canvas_state.dart';

class StatusBarWidget extends StatelessWidget {
  const StatusBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CanvasCubit, CanvasState>(
      builder: (context, state) {
        return Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: Styles.spacingM),
          decoration: BoxDecoration(
            color: Palette.surfaceVariant,
            border: Border(
              bottom: BorderSide(color: Palette.outlineVariant, width: 1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Styles.spacingS,
                  vertical: Styles.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: state.isConnected
                      ? Palette.successContainer
                      : Palette.errorContainer,
                  borderRadius: BorderRadius.circular(Styles.radiusS),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: state.isConnected
                            ? Palette.onSuccessContainer
                            : Palette.onErrorContainer,
                      ),
                    ),
                    const SizedBox(width: Styles.spacingXS),
                    Text(
                      state.isConnected ? 'Connected' : 'Disconnected',
                      style: Styles.labelSmall.copyWith(
                        color: state.isConnected
                            ? Palette.onSuccessContainer
                            : Palette.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Styles.spacingM),
              if (state.status == CanvasStatus.error)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Styles.spacingS,
                      vertical: Styles.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: Palette.errorContainer,
                      borderRadius: BorderRadius.circular(Styles.radiusS),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 16,
                          color: Palette.onErrorContainer,
                        ),
                        const SizedBox(width: Styles.spacingS),
                        Expanded(
                          child: Text(
                            'Error: ${state.errorMessage}',
                            style: Styles.labelSmall.copyWith(
                              color: Palette.onErrorContainer,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const Spacer(),
              if (state.strokes.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Styles.spacingS,
                    vertical: Styles.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: Palette.secondaryContainer,
                    borderRadius: BorderRadius.circular(Styles.radiusS),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history,
                        size: 16,
                        color: Palette.onSecondaryContainer,
                      ),
                      const SizedBox(width: Styles.spacingXS),
                      Text(
                        '${state.strokes.length} snapshots',
                        style: Styles.labelSmall.copyWith(
                          color: Palette.onSecondaryContainer,
                          fontWeight: FontWeight.w500,
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
