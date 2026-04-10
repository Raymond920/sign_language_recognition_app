import 'package:flutter/material.dart';

class LessonMock {
  final String title;
  final String description;
  final int signCount;
  final double progress; // 0.0 to 1.0

  LessonMock({
    required this.title, 
    required this.description, 
    required this.signCount, 
    required this.progress, 
  });
}

class Lesson {
  final int id;
  final String name;
  final String description;
  final int signCount;    // Total signs in this lesson
  final double progress;   // 0.0 to 1.0 (Calculated via SQL)

  Lesson({
    required this.id,
    required this.name,
    required this.description,
    required this.signCount,
    required this.progress,
  });

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
    name: json['lesson_name'],
    description: json['description'],
    // These two are returned by the subqueries in your SQL
    signCount: json['sign_count'] ?? 0, 
    progress: (json['progress_percentage'] ?? 0.0).toDouble(),
  );
}