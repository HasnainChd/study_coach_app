import 'package:flutter/material.dart';

class Subject {
  final String id;
  final String name;
  final Color color;
  final DateTime? examDate;
  final double progress;

  Subject({
    required this.id,
    required this.name,
    required this.color,
    this.examDate,
    this.progress = 0.0,
  });

  Subject copyWith({
    String? id,
    String? name,
    Color? color,
    DateTime? examDate,
    double? progress,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      examDate: examDate ?? this.examDate,
      progress: progress ?? this.progress,
    );
  }
}
