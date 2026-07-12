import '../entities/study_history_entry.dart';

abstract class StudyHistoryRepository {
  Future<List<StudyHistoryEntry>> getEntries();
  Future<void> addEntry(StudyHistoryEntry entry);
  Future<void> removeByAgendaItemId(String agendaItemId);
}
