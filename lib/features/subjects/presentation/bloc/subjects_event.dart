import 'package:flutter/material.dart';

abstract class SubjectsEvent {}

class LoadSubjectsEvent extends SubjectsEvent {}

class AddSubjectEvent extends SubjectsEvent {
  final String name;
  final Color color;
  final DateTime? examDate;

  AddSubjectEvent({
    required this.name,
    required this.color,
    this.examDate,
  });
}

class RemoveSubjectEvent extends SubjectsEvent {
  final String id;
  RemoveSubjectEvent(this.id);
}

class UpdateDailyMinutesEvent extends SubjectsEvent {
  final int minutes;
  UpdateDailyMinutesEvent(this.minutes);
}

class UpdatePreferredTimeEvent extends SubjectsEvent {
  final String preferredTime;
  UpdatePreferredTimeEvent(this.preferredTime);
}

class ToggleNotificationsEvent extends SubjectsEvent {
  final bool enabled;
  ToggleNotificationsEvent(this.enabled);
}

class ToggleAgendaItemEvent extends SubjectsEvent {
  final String id;
  ToggleAgendaItemEvent(this.id);
}

class UpdateSettingsPreferencesEvent extends SubjectsEvent {
  final int? pomodoroFocus;
  final int? shortBreak;
  final int? longBreak;
  final bool? dailyReminder;
  final bool? streakAlerts;
  final bool? studyTips;

  UpdateSettingsPreferencesEvent({
    this.pomodoroFocus,
    this.shortBreak,
    this.longBreak,
    this.dailyReminder,
    this.streakAlerts,
    this.studyTips,
  });
}

class GenerateStudyPlanEvent extends SubjectsEvent {}

class ClaimStreakEvent extends SubjectsEvent {}

class AddXpEvent extends SubjectsEvent {
  final double xpAmount;
  AddXpEvent(this.xpAmount);
}
