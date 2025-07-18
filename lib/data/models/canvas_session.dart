import 'package:equatable/equatable.dart';

class CanvasSession extends Equatable {
  final String id;
  final DateTime createdAt;
  final String? title;
  final String createdBy;

  const CanvasSession({
    required this.id,
    required this.createdAt,

    this.title,
    required this.createdBy,
  });

  @override
  List<Object?> get props => [id, createdAt, title, createdBy];

  CanvasSession copyWith({
    String? id,
    DateTime? createdAt,
    String? title,
    String? createdBy,
  }) {
    return CanvasSession(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'title': title,
      'created_by': createdBy,
    };
  }

  factory CanvasSession.fromJson(Map<String, dynamic> json) {
    return CanvasSession(
      id: json['id'],
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      title: json['title'],
      createdBy: json['created_by'],
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
}
