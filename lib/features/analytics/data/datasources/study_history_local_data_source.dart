import 'package:hive/hive.dart';

import '../models/study_history_entry_model.dart';

abstract class StudyHistoryLocalDataSource {
  Future<List<StudyHistoryEntryModel>> getEntries();
  Future<void> saveEntries(List<StudyHistoryEntryModel> entries);
}

class StudyHistoryLocalDataSourceImpl implements StudyHistoryLocalDataSource {
  final Box _box;

  StudyHistoryLocalDataSourceImpl(this._box);

  static const String _keyEntries = 'studyHistoryEntries';

  @override
  Future<List<StudyHistoryEntryModel>> getEntries() async {
    final List<dynamic>? rawList = _box.get(_keyEntries);
    if (rawList == null) return [];
    return rawList
        .map(
          (item) => StudyHistoryEntryModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  @override
  Future<void> saveEntries(List<StudyHistoryEntryModel> entries) async {
    final rawList = entries.map((entry) => entry.toMap()).toList();
    await _box.put(_keyEntries, rawList);
  }
}
