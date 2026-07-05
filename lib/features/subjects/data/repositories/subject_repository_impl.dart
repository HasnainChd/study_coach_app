import '../../domain/entities/agenda_item.dart';
import '../../domain/entities/settings_preferences.dart';
import '../../domain/entities/subject.dart';
import '../../domain/repositories/subject_repository.dart';
import '../datasources/subject_local_data_source.dart';
import '../models/agenda_item_model.dart';
import '../models/settings_preferences_model.dart';
import '../models/subject_model.dart';

class SubjectRepositoryImpl implements SubjectRepository {
  final SubjectLocalDataSource localDataSource;

  SubjectRepositoryImpl(this.localDataSource);

  @override
  Future<List<Subject>> getSubjects() async {
    return await localDataSource.getSubjects();
  }

  @override
  Future<void> saveSubjects(List<Subject> subjects) async {
    final models = subjects.map((s) => SubjectModel.fromEntity(s)).toList();
    await localDataSource.saveSubjects(models);
  }

  @override
  Future<int> getDailyStudyMinutes() async {
    return await localDataSource.getDailyStudyMinutes();
  }

  @override
  Future<void> saveDailyStudyMinutes(int minutes) async {
    await localDataSource.saveDailyStudyMinutes(minutes);
  }

  @override
  Future<String> getPreferredTime() async {
    return await localDataSource.getPreferredTime();
  }

  @override
  Future<void> savePreferredTime(String time) async {
    await localDataSource.savePreferredTime(time);
  }

  @override
  Future<bool> getNotificationsEnabled() async {
    return await localDataSource.getNotificationsEnabled();
  }

  @override
  Future<void> saveNotificationsEnabled(bool enabled) async {
    await localDataSource.saveNotificationsEnabled(enabled);
  }

  @override
  Future<List<AgendaItem>> getAgendaItems() async {
    return await localDataSource.getAgendaItems();
  }

  @override
  Future<void> saveAgendaItems(List<AgendaItem> items) async {
    final models = items.map((item) => AgendaItemModel.fromEntity(item)).toList();
    await localDataSource.saveAgendaItems(models);
  }

  @override
  Future<SettingsPreferences> getSettingsPreferences() async {
    return await localDataSource.getSettingsPreferences();
  }

  @override
  Future<void> saveSettingsPreferences(SettingsPreferences settings) async {
    final model = SettingsPreferencesModel.fromEntity(settings);
    await localDataSource.saveSettingsPreferences(model);
  }

  @override
  Future<bool> getHasCompletedOnboarding() async {
    return await localDataSource.getHasCompletedOnboarding();
  }

  @override
  Future<void> saveHasCompletedOnboarding(bool completed) async {
    await localDataSource.saveHasCompletedOnboarding(completed);
  }

  @override
  Future<int> getStreak() async {
    return await localDataSource.getStreak();
  }

  @override
  Future<void> saveStreak(int streak) async {
    await localDataSource.saveStreak(streak);
  }

  @override
  Future<double> getXpProgress() async {
    return await localDataSource.getXpProgress();
  }

  @override
  Future<void> saveXpProgress(double xp) async {
    await localDataSource.saveXpProgress(xp);
  }

  @override
  Future<int> getLevel() async {
    return await localDataSource.getLevel();
  }

  @override
  Future<void> saveLevel(int level) async {
    await localDataSource.saveLevel(level);
  }

  @override
  Future<String> getLastStreakClaimedDate() async {
    return await localDataSource.getLastStreakClaimedDate();
  }

  @override
  Future<void> saveLastStreakClaimedDate(String dateStr) async {
    await localDataSource.saveLastStreakClaimedDate(dateStr);
  }
}
