import 'package:hive/hive.dart';
import '../models/subject_model.dart';
import '../models/agenda_item_model.dart';
import '../models/settings_preferences_model.dart';

abstract class SubjectLocalDataSource {
  Future<List<SubjectModel>> getSubjects();
  Future<void> saveSubjects(List<SubjectModel> subjects);

  Future<int> getDailyStudyMinutes();
  Future<void> saveDailyStudyMinutes(int minutes);

  Future<String> getPreferredTime();
  Future<void> savePreferredTime(String time);

  Future<bool> getNotificationsEnabled();
  Future<void> saveNotificationsEnabled(bool enabled);

  Future<List<AgendaItemModel>> getAgendaItems();
  Future<void> saveAgendaItems(List<AgendaItemModel> items);

  Future<SettingsPreferencesModel> getSettingsPreferences();
  Future<void> saveSettingsPreferences(SettingsPreferencesModel settings);

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

class SubjectLocalDataSourceImpl implements SubjectLocalDataSource {
  final Box _box;

  SubjectLocalDataSourceImpl(this._box);

  static const String _keySubjects = 'subjects';
  static const String _keyDailyMinutes = 'dailyStudyMinutes';
  static const String _keyPreferredTime = 'preferredTime';
  static const String _keyNotifications = 'notificationsEnabled';
  static const String _keyAgendaItems = 'agendaItems';
  static const String _keySettings = 'settings';
  static const String _keyOnboarding = 'hasCompletedOnboarding';
  static const String _keyStreak = 'streak';
  static const String _keyXp = 'xpProgress';
  static const String _keyLevel = 'level';
  static const String _keyLastStreakDate = 'lastStreakClaimedDate';

  @override
  Future<List<SubjectModel>> getSubjects() async {
    final List<dynamic>? rawList = _box.get(_keySubjects);
    if (rawList == null) return [];
    return rawList
        .map((item) => SubjectModel.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  @override
  Future<void> saveSubjects(List<SubjectModel> subjects) async {
    final rawList = subjects.map((s) => s.toMap()).toList();
    await _box.put(_keySubjects, rawList);
  }

  @override
  Future<int> getDailyStudyMinutes() async {
    final dynamic val = _box.get(_keyDailyMinutes);
    if (val is int) return val;
    return 90;
  }

  @override
  Future<void> saveDailyStudyMinutes(int minutes) async {
    await _box.put(_keyDailyMinutes, minutes);
  }

  @override
  Future<String> getPreferredTime() async {
    final dynamic val = _box.get(_keyPreferredTime);
    if (val is String) return val;
    return 'Morning';
  }

  @override
  Future<void> savePreferredTime(String time) async {
    await _box.put(_keyPreferredTime, time);
  }

  @override
  Future<bool> getNotificationsEnabled() async {
    final dynamic val = _box.get(_keyNotifications);
    if (val is bool) return val;
    return true;
  }

  @override
  Future<void> saveNotificationsEnabled(bool enabled) async {
    await _box.put(_keyNotifications, enabled);
  }

  @override
  Future<List<AgendaItemModel>> getAgendaItems() async {
    final List<dynamic>? rawList = _box.get(_keyAgendaItems);
    if (rawList == null) return [];
    return rawList
        .map((item) => AgendaItemModel.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  @override
  Future<void> saveAgendaItems(List<AgendaItemModel> items) async {
    final rawList = items.map((item) => item.toMap()).toList();
    await _box.put(_keyAgendaItems, rawList);
  }

  @override
  Future<SettingsPreferencesModel> getSettingsPreferences() async {
    final dynamic raw = _box.get(_keySettings);
    if (raw == null) return SettingsPreferencesModel();
    return SettingsPreferencesModel.fromMap(Map<String, dynamic>.from(raw as Map));
  }

  @override
  Future<void> saveSettingsPreferences(SettingsPreferencesModel settings) async {
    await _box.put(_keySettings, settings.toMap());
  }

  @override
  Future<bool> getHasCompletedOnboarding() async {
    final dynamic val = _box.get(_keyOnboarding);
    if (val is bool) return val;
    return false;
  }

  @override
  Future<void> saveHasCompletedOnboarding(bool completed) async {
    await _box.put(_keyOnboarding, completed);
  }

  @override
  Future<int> getStreak() async {
    final dynamic val = _box.get(_keyStreak);
    if (val is int) return val;
    return 0;
  }

  @override
  Future<void> saveStreak(int streak) async {
    await _box.put(_keyStreak, streak);
  }

  @override
  Future<double> getXpProgress() async {
    final dynamic val = _box.get(_keyXp);
    if (val is double) return val;
    return 0.0;
  }

  @override
  Future<void> saveXpProgress(double xp) async {
    await _box.put(_keyXp, xp);
  }

  @override
  Future<int> getLevel() async {
    final dynamic val = _box.get(_keyLevel);
    if (val is int) return val;
    return 1;
  }

  @override
  Future<void> saveLevel(int level) async {
    await _box.put(_keyLevel, level);
  }

  @override
  Future<String> getLastStreakClaimedDate() async {
    final dynamic val = _box.get(_keyLastStreakDate);
    if (val is String) return val;
    return '';
  }

  @override
  Future<void> saveLastStreakClaimedDate(String dateStr) async {
    await _box.put(_keyLastStreakDate, dateStr);
  }
}
