import 'package:flutter/material.dart';
import '../../domain/entities/subject.dart';

class SubjectModel extends Subject {
  SubjectModel({
    required super.id,
    required super.name,
    required super.color,
    super.examDate,
    super.progress,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorValue': color.value,
      'examDate': examDate?.toIso8601String(),
      'progress': progress,
    };
  }

  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    return SubjectModel(
      id: map['id'] as String,
      name: map['name'] as String,
      color: Color(map['colorValue'] as int),
      examDate: map['examDate'] != null
          ? DateTime.parse(map['examDate'] as String)
          : null,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.50,
    );
  }

  factory SubjectModel.fromEntity(Subject subject) {
    return SubjectModel(
      id: subject.id,
      name: subject.name,
      color: subject.color,
      examDate: subject.examDate,
      progress: subject.progress,
    );
  }
}
