import 'package:flutter/material.dart';
import '../../../constants/palette.dart';
import '../../../constants/styles.dart';
import '../../../data/models/drawing_stroke.dart';
import '../../../data/repositories/hybrid_canvas_repository.dart';

class ReplayPage extends StatefulWidget {
  final String sessionId;
  final String userId;
  final String? title;
  final HybridCanvasRepository repository;

  const ReplayPage({
    super.key,
    required this.sessionId,
    required this.userId,
    this.title,
    required this.repository,
  });

  @override
  State<ReplayPage> createState() => _ReplayPageState();
}

class _ReplayPageState extends State<ReplayPage> {
  final GlobalKey _canvasKey = GlobalKey();
  late final HybridCanvasRepository _repository;

  List<DrawingStroke> _allStrokes = [];
  List<DrawingStroke> _replayStrokes = [];
  int _currentStrokeIndex = 0;
  bool _isReplaying = false;
  bool _isLoading = true;
  String? _errorMessage;

  static const Duration _strokeDelay = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _repository = widget.repository;

    _loadStrokesForReplay();
  }

  Future<void> _loadStrokesForReplay() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final strokes = await _fetchAllStrokes();

      if (mounted) {
        setState(() {
          _allStrokes = strokes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load strokes: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<List<DrawingStroke>> _fetchAllStrokes() async {
    try {
      final remoteStrokes = await _repository.getStrokesForSession(
        widget.sessionId,
      );
      if (remoteStrokes.isNotEmpty) {
        return remoteStrokes;
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch strokes: $e');
    }
  }

  void _startReplay() {
    if (_allStrokes.isEmpty) return;

    setState(() {
      _isReplaying = true;
      _currentStrokeIndex = 0;
      _replayStrokes = [];
    });

    _replayNextStroke();
  }

  void _replayNextStroke() {
    if (_currentStrokeIndex >= _allStrokes.length) {
      setState(() {
        _isReplaying = false;
      });
      return;
    }

    final stroke = _allStrokes[_currentStrokeIndex];

    setState(() {
      _replayStrokes = _processStrokeOperation(_replayStrokes, stroke);
    });

    _currentStrokeIndex++;

    Future.delayed(_strokeDelay, () {
      if (mounted && _isReplaying) {
        _replayNextStroke();
      }
    });
  }

  List<DrawingStroke> _processStrokeOperation(
    List<DrawingStroke> currentStrokes,
    DrawingStroke newStroke,
  ) {
    switch (newStroke.operation) {
      case 'draw':
        if (newStroke.isActive) {
          return [...currentStrokes, newStroke];
        }
        return currentStrokes;

      default:
        return currentStrokes;
    }
  }

  void _pauseReplay() {
    setState(() {
      _isReplaying = false;
    });
  }

  void _resetReplay() {
    setState(() {
      _isReplaying = false;
      _currentStrokeIndex = 0;
      _replayStrokes = [];
    });
  }

  void _fastForward() {
    setState(() {
      _isReplaying = false;
      _currentStrokeIndex = _allStrokes.length;
      _replayStrokes = _processAllStrokes(_allStrokes);
    });
  }

  List<DrawingStroke> _processAllStrokes(List<DrawingStroke> allStrokes) {
    List<DrawingStroke> processedStrokes = [];

    for (final stroke in allStrokes) {
      processedStrokes = _processStrokeOperation(processedStrokes, stroke);
    }

    return processedStrokes;
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
            Text('Canvas Replay', style: Styles.titleLarge),
            Text(
              'Session: ${widget.sessionId.substring(0, 8)}...',
              style: Styles.labelMedium.copyWith(color: Palette.textSecondary),
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadStrokesForReplay,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload strokes',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(Styles.spacingM),
            decoration: BoxDecoration(
              color: Palette.surface,
              border: Border(
                bottom: BorderSide(color: Palette.outlineVariant, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stroke Progress',
                        style: Styles.labelMedium.copyWith(
                          color: Palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: _allStrokes.isEmpty
                            ? 0.0
                            : _currentStrokeIndex / _allStrokes.length,
                        backgroundColor: Palette.outlineVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Palette.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_currentStrokeIndex/${_allStrokes.length} total strokes',
                        style: Styles.bodySmall.copyWith(
                          color: Palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Styles.spacingM),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_allStrokes.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _isReplaying ? _pauseReplay : _startReplay,
                        icon: Icon(
                          _isReplaying ? Icons.pause : Icons.play_arrow,
                        ),
                        tooltip: _isReplaying ? 'Pause' : 'Start replay',
                        style: IconButton.styleFrom(
                          backgroundColor: Palette.primaryContainer,
                          foregroundColor: Palette.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _resetReplay,
                        icon: const Icon(Icons.replay),
                        tooltip: 'Reset replay',
                        style: IconButton.styleFrom(
                          backgroundColor: Palette.secondaryContainer,
                          foregroundColor: Palette.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _fastForward,
                        icon: const Icon(Icons.fast_forward),
                        tooltip: 'Show all strokes',
                        style: IconButton.styleFrom(
                          backgroundColor: Palette.secondaryContainer,
                          foregroundColor: Palette.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          Expanded(child: _buildCanvasArea()),
        ],
      ),
    );
  }

  Widget _buildCanvasArea() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Palette.primary, strokeWidth: 3),
            const SizedBox(height: Styles.spacingM),
            Text(
              'Loading strokes for replay...',
              style: Styles.bodyMedium.copyWith(color: Palette.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
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
              _errorMessage!,
              style: Styles.bodyLarge.copyWith(color: Palette.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Styles.spacingL),
            FilledButton.icon(
              onPressed: _loadStrokesForReplay,
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

    if (_allStrokes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(Styles.spacingL),
              decoration: BoxDecoration(
                color: Palette.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.brush_outlined,
                size: 48,
                color: Palette.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Styles.spacingL),
            Text(
              'No strokes found for this session',
              style: Styles.bodyLarge.copyWith(color: Palette.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Styles.spacingS),
            Text(
              'Start drawing on the canvas to see the replay',
              style: Styles.bodyMedium.copyWith(color: Palette.textSecondary),
              textAlign: TextAlign.center,
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
        borderRadius: const BorderRadius.all(Radius.circular(Styles.radiusL)),
        child: _ReplayCanvas(canvasKey: _canvasKey, strokes: _replayStrokes),
      ),
    );
  }
}

class _ReplayCanvas extends StatelessWidget {
  final GlobalKey canvasKey;
  final List<DrawingStroke> strokes;

  const _ReplayCanvas({required this.canvasKey, required this.strokes});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (_) {},
      onPanUpdate: (_) {},
      onPanEnd: (_) {},
      child: CustomPaint(
        painter: _ReplayPainter(strokes: strokes),
        size: Size.infinite,
      ),
    );
  }
}

class _ReplayPainter extends CustomPainter {
  final List<DrawingStroke> strokes;

  _ReplayPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final activeDrawStrokes = strokes
        .where((stroke) => stroke.operation == 'draw' && stroke.isActive)
        .toList();

    for (final stroke in activeDrawStrokes) {
      _drawStroke(canvas, stroke);
    }
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.color ?? Colors.black
      ..strokeWidth = stroke.strokeWidth ?? 5.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final toolType = stroke.points.first.toolType;

    switch (toolType) {
      case 'brush':
        _drawBrushStroke(canvas, stroke, paint);
        break;
      case 'eraser':
        _drawEraserStroke(canvas, stroke, paint);
        break;
      case 'rectangle':
        _drawRectangle(canvas, stroke, paint);
        break;
      case 'circle':
        _drawCircle(canvas, stroke, paint);
        break;
      case 'line':
        _drawLine(canvas, stroke, paint);
        break;
      default:
        _drawBrushStroke(canvas, stroke, paint);
    }
  }

  void _drawBrushStroke(Canvas canvas, DrawingStroke stroke, Paint paint) {
    final path = Path();
    final points = stroke.points;

    if (points.isNotEmpty) {
      path.moveTo(points.first.point.dx, points.first.point.dy);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].point.dx, points[i].point.dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawEraserStroke(Canvas canvas, DrawingStroke stroke, Paint paint) {
    paint.blendMode = BlendMode.clear;
    _drawBrushStroke(canvas, stroke, paint);
  }

  void _drawRectangle(Canvas canvas, DrawingStroke stroke, Paint paint) {
    if (stroke.points.length < 2) return;

    final startPoint = stroke.points.first.point;
    final endPoint = stroke.points.last.point;

    final rect = Rect.fromPoints(startPoint, endPoint);
    canvas.drawRect(rect, paint);
  }

  void _drawCircle(Canvas canvas, DrawingStroke stroke, Paint paint) {
    if (stroke.points.length < 2) return;

    final startPoint = stroke.points.first.point;
    final endPoint = stroke.points.last.point;

    final center = Offset(
      (startPoint.dx + endPoint.dx) / 2,
      (startPoint.dy + endPoint.dy) / 2,
    );

    final radius = (startPoint - endPoint).distance / 2;
    canvas.drawCircle(center, radius, paint);
  }

  void _drawLine(Canvas canvas, DrawingStroke stroke, Paint paint) {
    if (stroke.points.length < 2) return;

    final startPoint = stroke.points.first.point;
    final endPoint = stroke.points.last.point;

    canvas.drawLine(startPoint, endPoint, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
