import '../../domain/entities/subject.dart';
import '../../domain/entities/agenda_item.dart';
import '../../domain/entities/settings_preferences.dart';

enum SubjectsStatus { initial, loading, success, failure, planGenerating, planGenerated, limitReached }

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
  final String lastStreakClaimedDate; // Single unified active date string (YYYY-MM-DD)
  final bool streakResetTriggered;
  final int coins;
  final List<String> unlockedRewardIds;
  final String? activeThemeId;
  final String? activeBadgeId;
  final int? earnedCoinsLastAction;
  final String? streakCelebrationMessage;
  final String? planBudgetWarningMessage;
  final bool showNotificationPermissionWarning;

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
    this.streak = 0,
    this.xpProgress = 0.0,
    this.level = 1,
    this.lastStreakClaimedDate = '',
    this.streakResetTriggered = false,
    this.coins = 0,
    this.unlockedRewardIds = const [],
    this.activeThemeId,
    this.activeBadgeId,
    this.earnedCoinsLastAction,
    this.streakCelebrationMessage,
    this.planBudgetWarningMessage,
    this.showNotificationPermissionWarning = false,
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
    bool? streakResetTriggered,
    int? coins,
    List<String>? unlockedRewardIds,
    String? activeThemeId,
    bool clearActiveThemeId = false,
    String? activeBadgeId,
    bool clearActiveBadgeId = false,
    int? earnedCoinsLastAction,
    bool clearEarnedCoinsLastAction = false,
    String? streakCelebrationMessage,
    bool clearStreakCelebrationMessage = false,
    String? planBudgetWarningMessage,
    bool clearPlanBudgetWarning = false,
    bool? showNotificationPermissionWarning,
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
      streakResetTriggered: streakResetTriggered ?? this.streakResetTriggered,
      coins: coins ?? this.coins,
      unlockedRewardIds: unlockedRewardIds ?? this.unlockedRewardIds,
      activeThemeId: clearActiveThemeId ? null : (activeThemeId ?? this.activeThemeId),
      activeBadgeId: clearActiveBadgeId ? null : (activeBadgeId ?? this.activeBadgeId),
      earnedCoinsLastAction: clearEarnedCoinsLastAction
          ? null
          : (earnedCoinsLastAction ?? this.earnedCoinsLastAction),
      streakCelebrationMessage: clearStreakCelebrationMessage
          ? null
          : (streakCelebrationMessage ?? this.streakCelebrationMessage),
      planBudgetWarningMessage: clearPlanBudgetWarning
          ? null
          : (planBudgetWarningMessage ?? this.planBudgetWarningMessage),
      showNotificationPermissionWarning: showNotificationPermissionWarning ??
          this.showNotificationPermissionWarning,
    );
  }
}
