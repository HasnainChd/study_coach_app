class SettingsPreferences {
  final int pomodoroFocus;
  final int shortBreak;
  final int longBreak;
  final bool dailyReminder;
  final bool streakAlerts;
  final bool studyTips;

  SettingsPreferences({
    this.pomodoroFocus = 25,
    this.shortBreak = 5,
    this.longBreak = 15,
    this.dailyReminder = true,
    this.streakAlerts = true,
    this.studyTips = false,
  });

  SettingsPreferences copyWith({
    int? pomodoroFocus,
    int? shortBreak,
    int? longBreak,
    bool? dailyReminder,
    bool? streakAlerts,
    bool? studyTips,
  }) {
    return SettingsPreferences(
      pomodoroFocus: pomodoroFocus ?? this.pomodoroFocus,
      shortBreak: shortBreak ?? this.shortBreak,
      longBreak: longBreak ?? this.longBreak,
      dailyReminder: dailyReminder ?? this.dailyReminder,
      streakAlerts: streakAlerts ?? this.streakAlerts,
      studyTips: studyTips ?? this.studyTips,
    );
  }
}
