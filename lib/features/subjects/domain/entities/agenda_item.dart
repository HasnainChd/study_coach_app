import 'package:flutter/material.dart';

class AgendaItem {
  final String id;
  final String title;
  final String tag;
  final int durationMinutes;
  final Color tagColor;
  final bool isCompleted;
  final bool hasEarnedXp;

  AgendaItem({
    required this.id,
    required this.title,
    required this.tag,
    required this.durationMinutes,
    required this.tagColor,
    this.isCompleted = false,
    this.hasEarnedXp = false,
  });

  AgendaItem copyWith({
    String? id,
    String? title,
    String? tag,
    int? durationMinutes,
    Color? tagColor,
    bool? isCompleted,
    bool? hasEarnedXp,
  }) {
    return AgendaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      tagColor: tagColor ?? this.tagColor,
      isCompleted: isCompleted ?? this.isCompleted,
      hasEarnedXp: hasEarnedXp ?? this.hasEarnedXp,
    );
  }
}
