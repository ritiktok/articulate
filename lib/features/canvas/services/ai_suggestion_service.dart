import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../../constants/config.dart';
import '../../../data/models/drawing_stroke.dart';
import '../../../data/models/drawing_point.dart';

class AISuggestionService {
  static const int _snapshotSize = Config.snapshotSize;

  bool _isInitialized = false;
  bool _isInitializing = false;

  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;
    _isInitializing = true;

    try {
      if (!Config.isOpenAIConfigured) {
        if (kDebugMode) {
          print('OpenAI API key not configured. Using mock canvas completion.');
        }
      }
      _isInitialized = true;
      _isInitializing = false;
    } catch (e) {
      _isInitializing = false;
      if (kDebugMode) {
        print('OpenAI service initialization failed: $e');
      }
      _isInitialized = true;
    }
  }

  bool get isReady => _isInitialized;

  Future<List<DrawingStroke>> requestCanvasCompletion(
    List<DrawingStroke> strokes,
    String sessionId, {
    GlobalKey? canvasKey,
  }) async {
    if (!isReady) {
      throw Exception('AI service not initialized');
    }

    try {
      if (!Config.isOpenAIConfigured) {
        return [];
      }

      ui.Image? canvasImage;
      if (canvasKey != null) {
        canvasImage = await _captureCanvasImage(canvasKey);
      }

      final prompt =
          '''Analyze this drawing and generate a complete, enhanced version that builds upon the existing artwork. 

Instructions:
1. Study the current drawing elements, style, and composition
2. Identify what the drawing represents or suggests
3. Generate additional strokes that complete or enhance the artwork
4. Maintain the same artistic style and technique
5. Add details, shading, or complementary elements that make the drawing more complete

Respond with ONLY a valid JSON array of stroke objects. Each stroke object must have:
- "points": array of objects with "x" and "y" coordinates (0-1000 range)
- "color": hex color string (e.g., "#000000")
- "strokeWidth": number (1-20 range)
- "toolType": string ("brush", "eraser", "line", "rectangle", "circle")
- "userId": string ("ai")

Example format:
[
  {
    "points": [{"x": 100, "y": 100}, {"x": 150, "y": 150}],
    "color": "#000000",
    "strokeWidth": 3,
    "toolType": "brush",
    "userId": "ai"
  }
]''';

      return await _callOpenAIWithImage(prompt, canvasImage, sessionId);
    } catch (e) {
      if (kDebugMode) {
        print('OpenAI API call failed: $e');
      }

      return [];
    }
  }

  Future<ui.Image?> _captureCanvasImage(GlobalKey canvasKey) async {
    try {
      final RenderRepaintBoundary boundary =
          canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);

      final resizedImage = await _resizeImage(
        image,
        _snapshotSize,
        _snapshotSize,
      );
      return resizedImage;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to capture canvas image: $e');
      }
      return null;
    }
  }

  Future<ui.Image> _resizeImage(ui.Image image, int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());

    canvas.drawImageRect(image, src, dst, Paint());

    final picture = recorder.endRecording();
    return await picture.toImage(width, height);
  }

  Future<List<DrawingStroke>> _callOpenAIWithImage(
    String prompt,
    ui.Image? canvasImage,
    String sessionId,
  ) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${Config.openaiApiKey}',
    };

    final byteData = await canvasImage?.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final bytes = byteData?.buffer.asUint8List();
    final base64Image = base64Encode(bytes ?? []);

    final body = jsonEncode({
      'model': Config.openaiModel,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are an expert AI drawing assistant that analyzes base64-encoded canvas images and generates enhanced, complete drawings. Your task is to:\n\n1. Analyze the provided base64 image to understand the existing artwork\n2. Identify the drawing style, technique, and subject matter\n3. Generate additional strokes that complete or enhance the artwork\n4. Maintain visual consistency with the existing elements\n5. Respond with ONLY a valid JSON array of stroke objects\n\nEach stroke object must include: points (array of {x, y} coordinates), color (hex string), strokeWidth (number), toolType (string), and userId ("ai").\n\nDo not include any explanations, markdown formatting, or additional text - only the JSON array.',
        },
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/png;base64,$base64Image'},
            },
          ],
        },
      ],
      'max_tokens': Config.maxTokens,
      'temperature': Config.temperature,
    });

    final response = await http.post(
      Uri.parse(Config.openaiApiUrl),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      return _parseCanvasSnapshotResponse(content, sessionId);
    } else {
      throw Exception(
        'OpenAI API error: ${response.statusCode} - ${response.body}',
      );
    }
  }

  List<DrawingStroke> _parseCanvasSnapshotResponse(
    String response,
    String sessionId,
  ) {
    final strokes = <DrawingStroke>[];
    try {
      String jsonString = response.trim();
      if (jsonString.startsWith('```json')) {
        jsonString = jsonString.substring(7);
      }
      if (jsonString.startsWith('```')) {
        jsonString = jsonString.substring(3);
      }
      if (jsonString.endsWith('```')) {
        jsonString = jsonString.substring(0, jsonString.length - 3);
      }

      jsonString = _extractCompleteJson(jsonString);

      final jsonData = jsonDecode(jsonString.trim());
      if (jsonData is List) {
        for (final item in jsonData) {
          if (item is Map<String, dynamic>) {
            try {
              final stroke = _createDrawingStrokeFromJson(item, sessionId);
              if (stroke != null) {
                strokes.add(stroke);
              }
            } catch (e) {
              if (kDebugMode) {
                print('Failed to parse stroke: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to parse CanvasSnapshot response: $e');
        print('Response was: $response');
      }
    }
    return strokes;
  }

  String _extractCompleteJson(String jsonString) {
    int bracketCount = 0;
    int lastCompleteIndex = -1;

    for (int i = 0; i < jsonString.length; i++) {
      if (jsonString[i] == '{') {
        bracketCount++;
      } else if (jsonString[i] == '}') {
        bracketCount--;
        if (bracketCount == 0) {
          lastCompleteIndex = i;
        }
      }
    }

    if (lastCompleteIndex > 0) {
      int arrayStart = jsonString.indexOf('[');
      if (arrayStart >= 0) {
        return '${jsonString.substring(arrayStart, lastCompleteIndex + 1)}]';
      }
    }

    return jsonString;
  }

  DrawingStroke? _createDrawingStrokeFromJson(
    Map<String, dynamic> json,
    String sessionId,
  ) {
    try {
      final points = <DrawingPoint>[];
      final pointsList = json['points'] as List?;

      if (pointsList != null) {
        for (final pointData in pointsList) {
          if (pointData is Map<String, dynamic>) {
            final x = (pointData['x'] as num?)?.toDouble() ?? 0.0;
            final y = (pointData['y'] as num?)?.toDouble() ?? 0.0;

            points.add(
              DrawingPoint(
                point: Offset(x, y),
                color: _hexToColor(json['color'] as String? ?? '#000000'),
                strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 5.0,
                toolType: json['toolType'] as String? ?? 'brush',
                userId: json['userId'] as String? ?? 'ai',
                timestamp: DateTime.now(),
              ),
            );
          }
        }
      }

      if (points.isNotEmpty) {
        return DrawingStroke(
          id: Uuid().v4(),
          sessionId: sessionId,
          points: points,
          userId: json['userId'] as String? ?? 'ai',
          createdAt: DateTime.now(),
          version: 1,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating DrawingStroke from JSON: $e');
      }
    }

    return null;
  }

  Color _hexToColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');

      if (hex.length == 6) {
        hex = 'FF$hex';
      }

      final value = int.parse(hex, radix: 16);
      return Color(value);
    } catch (e) {
      return Colors.black;
    }
  }
}
