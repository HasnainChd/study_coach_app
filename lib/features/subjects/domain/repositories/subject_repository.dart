import '../entities/subject.dart';
import '../entities/agenda_item.dart';
import '../entities/settings_preferences.dart';

abstract class SubjectRepository {
  Future<List<Subject>> getSubjects();
  Future<void> saveSubjects(List<Subject> subjects);

  Future<int> getDailyStudyMinutes();
  Future<void> saveDailyStudyMinutes(int minutes);

  Future<String> getPreferredTime();
  Future<void> savePreferredTime(String time);

  Future<bool> getNotificationsEnabled();
  Future<void> saveNotificationsEnabled(bool enabled);

  Future<List<AgendaItem>> getAgendaItems();
  Future<void> saveAgendaItems(List<AgendaItem> items);

  Future<SettingsPreferences> getSettingsPreferences();
  Future<void> saveSettingsPreferences(SettingsPreferences settings);

  Future<bool> getHasCompletedOnboarding();
  Future<void> saveHasCompletedOnboarding(bool completed);

  Future<int> getStreak();
  Future<void> saveStreak(int streak);

  Future<double> getXpProgress();
  Future<void> saveXpProgress(double xp);

  Future<int> getLevel();
  Future<void> saveLevel(int level);

  Future<String> getLastStreakClaimedDate();
  Future<void> saveLastStreakClaimedDate(String dateStr);
}
