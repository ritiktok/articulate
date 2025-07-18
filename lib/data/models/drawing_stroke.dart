import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'drawing_point.dart';

class DrawingStroke extends Equatable {
  final String id;
  final String sessionId;
  final String userId;
  final String operation;
  final List<DrawingPoint> points;
  final String? targetStrokeId;
  final int? version;
  final bool isActive;
  final DateTime createdAt;

  const DrawingStroke({
    required this.id,
    required this.sessionId,
    required this.points,
    required this.userId,
    required this.createdAt,
    this.operation = 'draw',
    this.targetStrokeId,
    this.isActive = true,
    this.version,
  });

  @override
  List<Object?> get props => [
    id,
    sessionId,
    points,
    userId,
    createdAt,
    operation,
    targetStrokeId,
    isActive,
    version,
  ];

  DrawingStroke copyWith({
    String? id,
    String? sessionId,
    List<DrawingPoint>? points,
    String? userId,
    DateTime? createdAt,
    String? operation,
    String? targetStrokeId,
    bool? isActive,
    int? version,
  }) {
    return DrawingStroke(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      points: points ?? this.points,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      operation: operation ?? this.operation,
      targetStrokeId: targetStrokeId ?? this.targetStrokeId,
      isActive: isActive ?? this.isActive,
      version: version ?? this.version,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'points': points.map((point) => point.toJson()).toList(),
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'operation': operation,
      'target_stroke_id': targetStrokeId,
      'is_active': isActive,
      'version': version,
    };
  }

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    List<DrawingPoint> parsedPoints = [];

    try {
      final pointsData = json['points'];
      if (pointsData != null) {
        if (pointsData is String) {
          final pointsList = jsonDecode(pointsData) as List;
          parsedPoints = pointsList
              .map((pointJson) => DrawingPoint.fromJson(pointJson))
              .toList();
        } else if (pointsData is List) {
          parsedPoints = pointsData
              .map((pointJson) => DrawingPoint.fromJson(pointJson))
              .toList();
        }
      }
    } catch (e) {
      parsedPoints = [];
    }

    return DrawingStroke(
      id: json['id'],
      sessionId: json['session_id'] ?? json['sessionId'],
      points: parsedPoints,
      userId: json['user_id'] ?? json['userId'],
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      operation: json['operation'] ?? 'draw',
      targetStrokeId: json['target_stroke_id'] ?? json['targetStrokeId'],
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      version: json['version'],
    );
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

  bool get isEmpty => points.isEmpty;
  bool get isNotEmpty => points.isNotEmpty;
  int get pointCount => points.length;

  Color? get color => points.isNotEmpty ? points.first.color : null;
  double? get strokeWidth =>
      points.isNotEmpty ? points.first.strokeWidth : null;
  String? get toolType => points.isNotEmpty ? points.first.toolType : null;
}
