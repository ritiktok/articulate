import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../constants/palette.dart';
import '../../canvas/cubit/animation_cubit.dart';
import '../../canvas/cubit/canvas_cubit.dart';
import '../cubit/voice_cubit.dart';
import '../cubit/voice_state.dart';
import '../../tools/cubit/tools_cubit.dart';

class VoiceToolbarWidget extends StatelessWidget {
  final CanvasCubit canvasCubit;

  const VoiceToolbarWidget({super.key, required this.canvasCubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final toolsCubit = context.read<ToolsCubit>();
        final voiceCubit = VoiceCubit(
          canvasCubit: canvasCubit,
          toolsCubit: toolsCubit,
        );
        Future.delayed(const Duration(milliseconds: 500), () {});
        return voiceCubit;
      },
      child: const _VoiceToolbarContent(),
    );
  }
}

class _VoiceToolbarContent extends StatefulWidget {
  const _VoiceToolbarContent();

  @override
  State<_VoiceToolbarContent> createState() => _VoiceToolbarContentState();
}

class _VoiceToolbarContentState extends State<_VoiceToolbarContent> {
  late AnimationCubit _animationCubit;

  @override
  void initState() {
    super.initState();
    _animationCubit = context.read<AnimationCubit>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VoiceCubit, VoiceState>(
      listener: (context, state) {
        if (state.lastTranscription != null &&
            state.lastTranscription!.isNotEmpty) {
          _animationCubit.triggerCanvasRipple();
        }
      },
      child: BlocBuilder<VoiceCubit, VoiceState>(
        builder: (context, state) {
          return Container(
            height: 80,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildVoiceControlButton(context, state),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 64,
                      child: _buildMainContent(state),
                    ),
                  ),
                  _buildRightSideActions(context, state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVoiceControlButton(BuildContext context, VoiceState state) {
    return GestureDetector(
      onTap: () {
        if (state.canStartListening) {
          context.read<VoiceCubit>().startListening();
        } else if (state.canStopListening) {
          context.read<VoiceCubit>().stopListening();
        } else if (!state.hasPermission) {
          context.read<VoiceCubit>().showPermissionOverlay();
        }
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getButtonBackgroundColor(state),
          border: Border.all(color: _getButtonBorderColor(state), width: 2),
          boxShadow: [
            BoxShadow(
              color: _getButtonBorderColor(state).withValues(alpha: 0.3),
              blurRadius: state.isListening ? 12 : 8,
              spreadRadius: state.isListening ? 4 : 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _getButtonIcon(state),
                key: ValueKey('${state.status}_${state.isListening}'),
                size: 24,
                color: _getButtonIconColor(state),
              ),
            ),
            if (state.isListening && state.audioLevel > 0)
              _buildAudioLevelIndicator(state.audioLevel),
          ],
        ),
      ),
    );
  }

  Color _getButtonBackgroundColor(VoiceState state) {
    if (!state.hasPermission) return Colors.red.withValues(alpha: 0.1);
    if (state.isListening) return Colors.red.withValues(alpha: 0.2);
    if (state.isProcessing) return Colors.orange.withValues(alpha: 0.2);
    if (state.isSpeaking) return Colors.blue.withValues(alpha: 0.2);
    return Colors.grey.withValues(alpha: 0.1);
  }

  Color _getButtonBorderColor(VoiceState state) {
    if (!state.hasPermission) return Colors.red;
    if (state.isListening) return Colors.red;
    if (state.isProcessing) return Colors.orange;
    if (state.isSpeaking) return Colors.blue;
    return Colors.grey;
  }

  Color _getButtonIconColor(VoiceState state) {
    if (!state.hasPermission) return Colors.red;
    if (state.isListening) return Colors.red;
    if (state.isProcessing) return Colors.orange;
    if (state.isSpeaking) return Colors.blue;
    return Colors.grey;
  }

  IconData _getButtonIcon(VoiceState state) {
    if (!state.hasPermission) return Icons.mic_off;
    if (state.isListening) return Icons.mic;
    if (state.isProcessing) return Icons.hourglass_empty;
    if (state.isSpeaking) return Icons.volume_up;
    return Icons.mic;
  }

  Widget _buildAudioLevelIndicator(double audioLevel) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: 56 + (audioLevel / 10),
      height: 56 + (audioLevel / 10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.red.withValues(alpha: audioLevel / 100),
          width: 2,
        ),
      ),
    );
  }

  Widget _buildMainContent(VoiceState state) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatusIndicator(state),
          const SizedBox(height: 4),
          if (state.currentTranscription != null)
            _buildLiveTranscription(state.currentTranscription!),
          if (state.currentTranscription == null && state.lastCommand != null)
            _buildLastCommandDisplay(state.lastCommand!),
          if (state.currentTranscription == null &&
              state.lastCommand == null &&
              state.lastTranscription != null)
            _buildLastTranscription(state.lastTranscription!),
          if (state.currentTranscription == null &&
              state.lastCommand == null &&
              state.lastTranscription == null)
            _buildIdleMessage(state),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(VoiceState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusBackgroundColor(state),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusBorderColor(state), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(state), size: 12, color: _getStatusColor(state)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _getStatusText(state),
              style: TextStyle(
                color: _getStatusColor(state),
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusBackgroundColor(VoiceState state) {
    if (!state.hasPermission) return Colors.red.withValues(alpha: 0.1);
    if (state.isListening) return Colors.red.withValues(alpha: 0.1);
    if (state.isProcessing) return Colors.orange.withValues(alpha: 0.1);
    if (state.isSpeaking) return Colors.blue.withValues(alpha: 0.1);
    return Colors.grey.withValues(alpha: 0.1);
  }

  Color _getStatusBorderColor(VoiceState state) {
    if (!state.hasPermission) return Colors.red.withValues(alpha: 0.3);
    if (state.isListening) return Colors.red.withValues(alpha: 0.3);
    if (state.isProcessing) return Colors.orange.withValues(alpha: 0.3);
    if (state.isSpeaking) return Colors.blue.withValues(alpha: 0.3);
    return Colors.grey.withValues(alpha: 0.3);
  }

  Color _getStatusColor(VoiceState state) {
    if (!state.hasPermission) return Colors.red;
    if (state.isListening) return Colors.red;
    if (state.isProcessing) return Colors.orange;
    if (state.isSpeaking) return Colors.blue;
    return Colors.grey;
  }

  IconData _getStatusIcon(VoiceState state) {
    if (!state.hasPermission) return Icons.mic_off;
    if (state.isListening) return Icons.mic;
    if (state.isProcessing) return Icons.hourglass_empty;
    if (state.isSpeaking) return Icons.volume_up;
    return Icons.mic;
  }

  String _getStatusText(VoiceState state) {
    if (!state.hasPermission) return 'Microphone access needed';
    if (state.isListening) return 'Listening...';
    if (state.isProcessing) return 'Processing...';
    if (state.isSpeaking) return 'Speaking...';
    return 'Tap to start voice control';
  }

  Widget _buildLiveTranscription(String transcription) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.mic, color: Colors.blue, size: 12),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              transcription,
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastTranscription(String transcription) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 12),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              transcription,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleMessage(VoiceState state) {
    if (!state.hasPermission) {
      return Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 12),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Microphone permission required',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey, size: 12),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Say "draw a circle" or "change color to red"',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastCommandDisplay(VoiceCommand command) {
    Color commandColor;
    IconData commandIcon;

    switch (command.type) {
      case VoiceCommandType.toolSelection:
        commandColor = Colors.green;
        commandIcon = Icons.brush;
        break;
      case VoiceCommandType.colorChange:
        commandColor = Colors.orange;
        commandIcon = Icons.palette;
        break;
      case VoiceCommandType.strokeWidthChange:
        commandColor = Colors.purple;
        commandIcon = Icons.line_weight;
        break;
      case VoiceCommandType.shapeDrawing:
        commandColor = Colors.blue;
        commandIcon = Icons.shape_line;
        break;
      case VoiceCommandType.aiSuggestion:
        commandColor = Colors.pink;
        commandIcon = Icons.auto_awesome;
        break;
      case VoiceCommandType.undo:
      case VoiceCommandType.redo:
        commandColor = Colors.grey;
        commandIcon = Icons.history;
        break;
      case VoiceCommandType.clear:
        commandColor = Colors.red;
        commandIcon = Icons.clear_all;
        break;
      case VoiceCommandType.unknown:
        commandColor = Colors.grey;
        commandIcon = Icons.help_outline;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: commandColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: commandColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(commandIcon, color: commandColor, size: 12),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getCommandTypeText(command.type),
                  style: TextStyle(
                    color: commandColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                Text(
                  command.command,
                  style: TextStyle(
                    color: commandColor.withValues(alpha: 0.8),
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightSideActions(BuildContext context, VoiceState state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [if (!state.hasPermission) _buildPermissionButton(context)],
    );
  }

  Widget _buildPermissionButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<VoiceCubit>().openAppSettings(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.settings, color: Colors.red, size: 12),
            const SizedBox(width: 4),
            Text(
              'Settings',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCommandTypeText(VoiceCommandType type) {
    switch (type) {
      case VoiceCommandType.toolSelection:
        return 'Tool Selection';
      case VoiceCommandType.colorChange:
        return 'Color Change';
      case VoiceCommandType.strokeWidthChange:
        return 'Stroke Width';
      case VoiceCommandType.shapeDrawing:
        return 'Shape Drawing';
      case VoiceCommandType.aiSuggestion:
        return 'AI Suggestion';
      case VoiceCommandType.undo:
        return 'Undo';
      case VoiceCommandType.redo:
        return 'Redo';
      case VoiceCommandType.clear:
        return 'Clear Canvas';
      case VoiceCommandType.unknown:
        return 'Unknown Command';
    }
  }
}
