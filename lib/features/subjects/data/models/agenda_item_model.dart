import 'package:flutter/material.dart';
import '../../domain/entities/agenda_item.dart';

class AgendaItemModel extends AgendaItem {
  AgendaItemModel({
    required super.id,
    required super.title,
    required super.tag,
    required super.durationMinutes,
    required super.tagColor,
    super.isCompleted,
    super.hasEarnedXp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'tag': tag,
      'durationMinutes': durationMinutes,
      'tagColorValue': tagColor.value,
      'isCompleted': isCompleted,
      'hasEarnedXp': hasEarnedXp,
    };
  }

  factory AgendaItemModel.fromMap(Map<String, dynamic> map) {
    return AgendaItemModel(
      id: map['id'] as String,
      title: map['title'] as String,
      tag: map['tag'] as String,
      durationMinutes: map['durationMinutes'] as int,
      tagColor: Color(map['tagColorValue'] as int),
      isCompleted: map['isCompleted'] as bool? ?? false,
      hasEarnedXp: map['hasEarnedXp'] as bool? ?? false,
    );
  }

  factory AgendaItemModel.fromEntity(AgendaItem item) {
    return AgendaItemModel(
      id: item.id,
      title: item.title,
      tag: item.tag,
      durationMinutes: item.durationMinutes,
      tagColor: item.tagColor,
      isCompleted: item.isCompleted,
      hasEarnedXp: item.hasEarnedXp,
    );
  }
}
