import '../../domain/entities/study_history_entry.dart';

class StudyHistoryEntryModel extends StudyHistoryEntry {
  StudyHistoryEntryModel({
    required super.id,
    required super.agendaItemId,
    required super.date,
    required super.subjectName,
    super.subjectId,
    required super.durationMinutes,
    required super.xpAwarded,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'agendaItemId': agendaItemId,
      'date': date,
      'subjectName': subjectName,
      'subjectId': subjectId,
      'durationMinutes': durationMinutes,
      'xpAwarded': xpAwarded,
    };
  }

  factory StudyHistoryEntryModel.fromMap(Map<String, dynamic> map) {
    return StudyHistoryEntryModel(
      id: map['id'] as String,
      agendaItemId: map['agendaItemId'] as String,
      date: map['date'] as String,
      subjectName: map['subjectName'] as String,
      subjectId: map['subjectId'] as String?,
      durationMinutes: (map['durationMinutes'] as num).toInt(),
      xpAwarded: (map['xpAwarded'] as num).toDouble(),
    );
  }

  factory StudyHistoryEntryModel.fromEntity(StudyHistoryEntry entry) {
    return StudyHistoryEntryModel(
      id: entry.id,
      agendaItemId: entry.agendaItemId,
      date: entry.date,
      subjectName: entry.subjectName,
      subjectId: entry.subjectId,
      durationMinutes: entry.durationMinutes,
      xpAwarded: entry.xpAwarded,
    );
  }
}
