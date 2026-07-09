import '../../domain/entities/subject.dart';
import '../../domain/entities/agenda_item.dart';
import '../../domain/entities/settings_preferences.dart';

enum SubjectsStatus { initial, loading, success, failure, planGenerating, planGenerated }

class SubjectsState {
  final List<Subject> subjects;
  final int dailyStudyMinutes;
  final String preferredTime;
  final bool notificationsEnabled;
  final List<AgendaItem> agendaItems;
  final SettingsPreferences settings;

  final SubjectsStatus status;
  final String? errorMessage;

  // Tracks which agenda card the user last tapped — used by Quick Start
  final String? selectedAgendaItemId;

  // Gamification fields
  final int streak;
  final double xpProgress;
  final int level;
  final String lastStreakClaimedDate;

  SubjectsState({
    required this.subjects,
    this.dailyStudyMinutes = 90,
    this.preferredTime = 'Morning',
    this.notificationsEnabled = true,
    required this.agendaItems,
    required this.settings,
    this.status = SubjectsStatus.initial,
    this.errorMessage,
    this.selectedAgendaItemId,
    this.streak = 12,
    this.xpProgress = 0.68,
    this.level = 7,
    this.lastStreakClaimedDate = '',
  });

  SubjectsState copyWith({
    List<Subject>? subjects,
    int? dailyStudyMinutes,
    String? preferredTime,
    bool? notificationsEnabled,
    List<AgendaItem>? agendaItems,
    SettingsPreferences? settings,
    SubjectsStatus? status,
    String? errorMessage,
    String? selectedAgendaItemId,
    bool clearSelectedAgendaItem = false,
    int? streak,
    double? xpProgress,
    int? level,
    String? lastStreakClaimedDate,
  }) {
    return SubjectsState(
      subjects: subjects ?? this.subjects,
      dailyStudyMinutes: dailyStudyMinutes ?? this.dailyStudyMinutes,
      preferredTime: preferredTime ?? this.preferredTime,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      agendaItems: agendaItems ?? this.agendaItems,
      settings: settings ?? this.settings,
      status: status ?? this.status,
      errorMessage: errorMessage,
      selectedAgendaItemId: clearSelectedAgendaItem
          ? null
          : (selectedAgendaItemId ?? this.selectedAgendaItemId),
      streak: streak ?? this.streak,
      xpProgress: xpProgress ?? this.xpProgress,
      level: level ?? this.level,
      lastStreakClaimedDate: lastStreakClaimedDate ?? this.lastStreakClaimedDate,
    );
  }
}
