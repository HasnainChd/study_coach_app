class StudyHistoryEntry {
  final String id;
  final String agendaItemId;
  final String date;
  final String subjectName;
  final String? subjectId;
  final int durationMinutes;
  final double xpAwarded;

  const StudyHistoryEntry({
    required this.id,
    required this.agendaItemId,
    required this.date,
    required this.subjectName,
    this.subjectId,
    required this.durationMinutes,
    required this.xpAwarded,
  });
}
