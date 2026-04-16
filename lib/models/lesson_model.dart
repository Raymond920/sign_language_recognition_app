import 'package:flutter/material.dart';

class Lesson {
  final int id;
  final String title;
  final String description;
  final int signCount;              // Total signs in this lesson
  final double progress;            // 0.0 to 1.0 (Calculated via SQL)
  final bool isCompleted;            // From LESSON_PROGRESS.is_completed
  final bool pointsClaimed;          // From LESSON_PROGRESS.points_claimed

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.signCount,
    required this.progress,
    required this.isCompleted,
    required this.pointsClaimed,
  });

  // Lesson rewards 50 points once when completed
  bool get canClaimPoints => isCompleted && !pointsClaimed;

  // Dynamic status logic - no need to store this in DB
  String get status {
    if (progress <= 0) return "Not Started";
    if (progress >= 1.0) return "Completed";
    return "In Progress";
  }

  // Helper for UI colors
  Color get statusColor {
    if (progress <= 0) return Colors.grey;
    if (progress >= 1.0) return Colors.green;
    return Colors.indigo;
  }

  // Updated factory to handle the calculated fields from your SQL Query
  factory Lesson.fromMap(Map<String, dynamic> json) => Lesson(
    id: json['lesson_id'],
    title: json['title'],
    description: json['description'],
    signCount: json['sign_count'] ?? 0,
    progress: (json['progress_percentage'] ?? 0.0).toDouble(),
    isCompleted: (json['is_completed'] ?? 0) == 1,
    pointsClaimed: (json['points_claimed'] ?? 0) == 1,
  );

  /// Create a copy with modifications
  Lesson copyWith({
    bool? isCompleted,
    bool? pointsClaimed,
    double? progress,
  }) {
    return Lesson(
      id: id,
      title: title,
      description: description,
      signCount: signCount,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      pointsClaimed: pointsClaimed ?? this.pointsClaimed,
    );
  }
}