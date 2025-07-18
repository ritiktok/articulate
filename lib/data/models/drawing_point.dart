import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class DrawingPoint extends Equatable {
  final Offset point;
  final Color color;
  final double strokeWidth;
  final String toolType;
  final String userId;
  final DateTime timestamp;

  const DrawingPoint({
    required this.point,
    required this.color,
    required this.strokeWidth,
    required this.toolType,
    required this.userId,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
    point,
    color,
    strokeWidth,
    toolType,
    userId,
    timestamp,
  ];

  DrawingPoint copyWith({
    Offset? point,
    Color? color,
    double? strokeWidth,
    String? toolType,
    String? userId,
    DateTime? timestamp,
  }) {
    return DrawingPoint(
      point: point ?? this.point,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      toolType: toolType ?? this.toolType,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'point': {'dx': point.dx, 'dy': point.dy},
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'toolType': toolType,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    try {
      return DrawingPoint(
        point: Offset(
          (json['point']?['dx'] ?? 0.0).toDouble(),
          (json['point']?['dy'] ?? 0.0).toDouble(),
        ),
        color: Color(json['color'] ?? 0xFF000000),
        strokeWidth: (json['strokeWidth'] ?? 2.0).toDouble(),
        toolType: json['toolType'] ?? 'pen',
        userId: json['userId'] ?? '',
        timestamp: _parseDateTime(json['timestamp']),
      );
    } catch (e) {
      return DrawingPoint(
        point: const Offset(0, 0),
        color: Colors.black,
        strokeWidth: 2.0,
        toolType: 'pen',
        userId: '',
        timestamp: DateTime.now(),
      );
    }
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}
