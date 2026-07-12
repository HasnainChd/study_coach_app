import '../../domain/entities/study_history_entry.dart';
import '../../domain/repositories/study_history_repository.dart';
import '../datasources/study_history_local_data_source.dart';
import '../models/study_history_entry_model.dart';

class StudyHistoryRepositoryImpl implements StudyHistoryRepository {
  final StudyHistoryLocalDataSource localDataSource;

  StudyHistoryRepositoryImpl(this.localDataSource);

  @override
  Future<List<StudyHistoryEntry>> getEntries() async {
    return localDataSource.getEntries();
  }

  @override
  Future<void> addEntry(StudyHistoryEntry entry) async {
    final entries = await localDataSource.getEntries();
    final updated = [
      ...entries,
      StudyHistoryEntryModel.fromEntity(entry),
    ];
    await localDataSource.saveEntries(updated);
  }

  @override
  Future<void> removeByAgendaItemId(String agendaItemId) async {
    final entries = await localDataSource.getEntries();
    final updated = entries
        .where((entry) => entry.agendaItemId != agendaItemId)
        .toList();
    await localDataSource.saveEntries(updated);
  }
}
