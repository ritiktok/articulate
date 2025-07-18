import 'package:articulate/data/repositories/hybrid_canvas_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../constants/palette.dart';
import '../../../constants/styles.dart';
import '../cubit/canvas_cubit.dart';
import '../cubit/canvas_state.dart';
import '../cubit/animation_cubit.dart';
import '../../tools/tools.dart';
import '../../voice/voice.dart';
import 'drawing_canvas.dart';
import 'toolbar_widget.dart';
import 'status_bar_widget.dart';
import 'replay_page.dart';

class CanvasPage extends StatelessWidget {
  final String sessionId;
  final String userId;
  final String? title;

  const CanvasPage({
    super.key,
    required this.sessionId,
    required this.userId,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final cubit = CanvasCubit(
              remoteRepository: context.read<HybridCanvasRepository>(),
              currentUserId: userId,
            );

            Future.microtask(
              () => cubit.connectToSession(sessionId, title: title),
            );

            return cubit;
          },
        ),
        BlocProvider(create: (context) => ToolsCubit()),
        BlocProvider(create: (context) => AnimationCubit()),
      ],
      child: BlocProvider(
        create: (context) =>
            VoiceCubit(canvasCubit: context.read<CanvasCubit>()),
        child: _CanvasPageView(
          sessionId: sessionId,
          userId: userId,
          title: title,
        ),
      ),
    );
  }
}

class _CanvasPageView extends StatefulWidget {
  final String sessionId;
  final String userId;
  final String? title;

  const _CanvasPageView({
    required this.sessionId,
    required this.userId,
    this.title,
  });

  @override
  State<_CanvasPageView> createState() => _CanvasPageViewState();
}

class _CanvasPageViewState extends State<_CanvasPageView> {
  final GlobalKey _canvasKey = GlobalKey();
  late final CanvasCubit _canvasCubit;

  @override
  void initState() {
    super.initState();
    _canvasCubit = context.read<CanvasCubit>();

    _canvasCubit.initializeAI();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _canvasCubit.setCanvasKey(_canvasKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        backgroundColor: Palette.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Palette.primaryContainer,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlocBuilder<CanvasCubit, CanvasState>(
              builder: (context, state) {
                return Row(
                  children: [
                    Text('Collaborative Canvas', style: Styles.titleLarge),
                  ],
                );
              },
            ),
            Text(
              'Session: ${widget.sessionId.substring(0, 8)}...',
              style: Styles.labelMedium.copyWith(color: Palette.textSecondary),
            ),
          ],
        ),
        actions: [
          BlocBuilder<CanvasCubit, CanvasState>(
            builder: (context, state) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: state.isConnected
                        ? 'Online - Connected to Supabase'
                        : 'Offline - Using local storage',
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: state.isConnected
                            ? Palette.success
                            : Palette.warning,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (state.isConnected
                                        ? Palette.success
                                        : Palette.warning)
                                    .withValues(alpha: 0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  IconButton(
                    onPressed: () {
                      _showMoreActionsMenu(context);
                    },
                    icon: const Icon(Icons.more_vert, size: 20),
                    tooltip: 'More Actions',
                    style: IconButton.styleFrom(
                      backgroundColor: Palette.surfaceVariant,
                      foregroundColor: Palette.onSurfaceVariant,
                      minimumSize: const Size(40, 40),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const StatusBarWidget(),
              const AnimatedToolbarWidget(),
              VoiceToolbarWidget(canvasCubit: _canvasCubit),
              Expanded(
                child: BlocBuilder<CanvasCubit, CanvasState>(
                  builder: (context, state) {
                    if (state.status == CanvasStatus.loading) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Palette.primary,
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: Styles.spacingM),
                            Text(
                              'Loading canvas...',
                              style: Styles.bodyMedium.copyWith(
                                color: Palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    if (state.status == CanvasStatus.error) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(Styles.spacingL),
                              decoration: BoxDecoration(
                                color: Palette.errorContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Palette.onErrorContainer,
                              ),
                            ),
                            const SizedBox(height: Styles.spacingL),
                            Text(
                              'Error: ${state.errorMessage}',
                              style: Styles.bodyLarge.copyWith(
                                color: Palette.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: Styles.spacingL),
                            FilledButton.icon(
                              onPressed: () {
                                _canvasCubit.connectToSession(
                                  state.currentSession?.id ?? '',
                                );
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Palette.primary,
                                foregroundColor: Palette.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Container(
                      margin: const EdgeInsets.all(Styles.spacingM),
                      decoration: BoxDecoration(
                        color: Palette.canvas,
                        borderRadius: BorderRadius.circular(Styles.radiusL),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(Styles.radiusL),
                        ),
                        child: DrawingCanvas(canvasKey: _canvasKey),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          BlocBuilder<ToolsCubit, ToolsState>(
            builder: (context, toolsState) {
              if (!toolsState.isColorPickerOpen) return const SizedBox.shrink();
              return Positioned.fill(
                child: GestureDetector(
                  onTap: () => context.read<ToolsCubit>().closeColorPicker(),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Center(
                      child: GestureDetector(
                        onTap: () {},
                        child: const ColorPickerWidget(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          BlocBuilder<ToolsCubit, ToolsState>(
            builder: (context, toolsState) {
              if (!toolsState.isStrokeWidthSliderOpen) {
                return const SizedBox.shrink();
              }
              return Positioned.fill(
                child: GestureDetector(
                  onTap: () =>
                      context.read<ToolsCubit>().closeStrokeWidthSlider(),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Center(
                      child: GestureDetector(
                        onTap: () {},
                        child: const StrokeWidthSliderWidget(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          BlocBuilder<VoiceCubit, VoiceState>(
            builder: (context, voiceState) {
              if (voiceState.hasPermission ||
                  !voiceState.showPermissionOverlay) {
                return const SizedBox.shrink();
              }
              return Positioned(
                bottom: 80,
                left: 16,
                right: 16,
                child: const VoicePermissionWidget(),
              );
            },
          ),
          BlocBuilder<CanvasCubit, CanvasState>(
            builder: (context, state) {
              if (state.aiError == null) return const SizedBox.shrink();
              return Positioned(
                top: 100,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Palette.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Palette.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.aiError!,
                          style: TextStyle(fontSize: 12, color: Palette.error),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Palette.error, size: 16),
                        onPressed: () => _canvasCubit.clearAIError(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 100,
            right: 16,
            child: BlocBuilder<CanvasCubit, CanvasState>(
              builder: (context, state) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.strokes.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: FloatingActionButton(
                          heroTag: 'ai_generate_button',
                          onPressed: () {
                            _canvasCubit.generateNewDrawing();
                          },
                          backgroundColor: Palette.primaryContainer,
                          foregroundColor: Palette.onPrimaryContainer,
                          child: state.isAnalyzing
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Palette.onPrimaryContainer,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.auto_awesome),
                        ),
                      ),

                    if (state.canUndo)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: FloatingActionButton.small(
                          heroTag: 'undo_button',
                          onPressed: () {
                            _canvasCubit.undo();
                          },
                          backgroundColor: Palette.secondaryContainer,
                          foregroundColor: Palette.onSecondaryContainer,
                          child: const Icon(Icons.undo),
                        ),
                      ),

                    if (state.canRedo)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: FloatingActionButton.small(
                          heroTag: 'redo_button',
                          onPressed: () {
                            _canvasCubit.redo();
                          },
                          backgroundColor: Palette.secondaryContainer,
                          foregroundColor: Palette.onSecondaryContainer,
                          child: const Icon(Icons.redo),
                        ),
                      ),

                    if (state.strokes.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: FloatingActionButton.small(
                          heroTag: 'clear_button',
                          onPressed: () {
                            _showClearCanvasDialog(context);
                          },
                          backgroundColor: Palette.errorContainer,
                          foregroundColor: Palette.onErrorContainer,
                          child: const Icon(Icons.clear),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCanvasDialog(BuildContext context) {
    final canvasCubit = _canvasCubit;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Palette.surface,
        surfaceTintColor: Palette.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Styles.radiusL),
        ),
        title: Text('Clear Canvas', style: Styles.titleLarge),
        content: Text(
          'Are you sure you want to clear the entire canvas? This action cannot be undone.',
          style: Styles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: Styles.labelLarge.copyWith(color: Palette.primary),
            ),
          ),
          FilledButton(
            onPressed: () {
              canvasCubit.clear();
              Navigator.of(dialogContext).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Palette.error,
              foregroundColor: Palette.onError,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Palette.surface,
        surfaceTintColor: Palette.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Styles.radiusL),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Palette.error, size: 24),
            const SizedBox(width: 8),
            Text('Delete Current Session Data', style: Styles.titleLarge),
          ],
        ),
        content: Text(
          'This will permanently delete all locally stored drawings for the current session. This action cannot be undone and will not affect data stored on the server.',
          style: Styles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: Styles.labelLarge.copyWith(color: Palette.primary),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _canvasCubit.deleteCurrentSessionData();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Palette.error,
              foregroundColor: Palette.onError,
            ),
            child: const Text('Delete Session Data'),
          ),
        ],
      ),
    );
  }

  void _showMoreActionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Palette.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Copy Session ID'),
              subtitle: Text('Share with others to join'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: widget.sessionId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Session ID copied to clipboard'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Palette.primaryContainer,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Styles.radiusM),
                    ),
                  ),
                );
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.replay),
              title: const Text('Replay Session'),
              subtitle: const Text('Watch drawing replay'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReplayPage(
                      sessionId: widget.sessionId,
                      userId: widget.userId,
                      title: widget.title,
                      repository: context.read<HybridCanvasRepository>(),
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Voice Commands Help'),
              subtitle: const Text('Learn voice controls'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => const VoiceHelpDialog(),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Delete Current Session Data'),
              subtitle: const Text('Clear stored drawings for this session'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteAllDataDialog(context);
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
