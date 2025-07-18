import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../constants/palette.dart';
import '../../../data/models/drawing_stroke.dart';
import '../cubit/canvas_cubit.dart';
import '../cubit/canvas_state.dart';

class DrawingCanvas extends StatelessWidget {
  final GlobalKey canvasKey;

  const DrawingCanvas({super.key, required this.canvasKey});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CanvasCubit, CanvasState>(
      builder: (context, state) {
        return GestureDetector(
          onPanStart: (details) {
            context.read<CanvasCubit>().startDrawing(details.localPosition);
          },
          onPanUpdate: (details) {
            context.read<CanvasCubit>().continueDrawing(details.localPosition);
          },
          onPanEnd: (details) {
            context.read<CanvasCubit>().endDrawing();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Palette.canvas,
              border: Border.all(color: Palette.textHint, width: 1),
            ),
            child: RepaintBoundary(
              key: canvasKey,
              child: CustomPaint(
                painter: state.strokes.isNotEmpty
                    ? DrawingPainter(
                        strokes: state.strokes,
                        currentStroke: state.currentStroke,
                      )
                    : DrawingPainter(strokes: [], currentStroke: null),
                size: Size.infinite,
              ),
            ),
          ),
        );
      },
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;

  DrawingPainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final activeDrawStrokes = strokes
        .where((stroke) => stroke.operation == 'draw' && stroke.isActive)
        .toList();

    for (final stroke in activeDrawStrokes) {
      _drawStroke(canvas, stroke);
    }

    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
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
    paint.color = Colors.white;
    paint.strokeWidth = (stroke.strokeWidth ?? 5.0) * 2;

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
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke;
  }
}
