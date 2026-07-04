import '../../domain/entities/settings_preferences.dart';

class SettingsPreferencesModel extends SettingsPreferences {
  SettingsPreferencesModel({
    super.pomodoroFocus,
    super.shortBreak,
    super.longBreak,
    super.dailyReminder,
    super.streakAlerts,
    super.studyTips,
  });

  Map<String, dynamic> toMap() {
    return {
      'pomodoroFocus': pomodoroFocus,
      'shortBreak': shortBreak,
      'longBreak': longBreak,
      'dailyReminder': dailyReminder,
      'streakAlerts': streakAlerts,
      'studyTips': studyTips,
    };
  }

  factory SettingsPreferencesModel.fromMap(Map<String, dynamic> map) {
    return SettingsPreferencesModel(
      pomodoroFocus: map['pomodoroFocus'] as int? ?? 25,
      shortBreak: map['shortBreak'] as int? ?? 5,
      longBreak: map['longBreak'] as int? ?? 15,
      dailyReminder: map['dailyReminder'] as bool? ?? true,
      streakAlerts: map['streakAlerts'] as bool? ?? true,
      studyTips: map['studyTips'] as bool? ?? false,
    );
  }

  factory SettingsPreferencesModel.fromEntity(SettingsPreferences settings) {
    return SettingsPreferencesModel(
      pomodoroFocus: settings.pomodoroFocus,
      shortBreak: settings.shortBreak,
      longBreak: settings.longBreak,
      dailyReminder: settings.dailyReminder,
      streakAlerts: settings.streakAlerts,
      studyTips: settings.studyTips,
    );
  }
}
