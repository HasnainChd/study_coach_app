import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:study_coach_app/core/services/usage_limit_service.dart';
import 'package:study_coach_app/features/analytics/domain/entities/study_history_entry.dart';
import 'package:study_coach_app/features/analytics/domain/repositories/study_history_repository.dart';
import 'package:study_coach_app/features/rewards/domain/entities/reward_item.dart';
import 'package:study_coach_app/features/subjects/domain/entities/agenda_item.dart';
import 'package:study_coach_app/features/subjects/domain/entities/settings_preferences.dart';
import 'package:study_coach_app/features/subjects/domain/entities/subject.dart';
import 'package:study_coach_app/features/subjects/domain/repositories/subject_repository.dart';
import 'package:study_coach_app/features/subjects/domain/usecases/add_subject_usecase.dart';
import 'package:study_coach_app/features/subjects/domain/usecases/generate_study_plan_usecase.dart';
import 'package:study_coach_app/features/subjects/domain/usecases/get_subjects_usecase.dart';
import 'package:study_coach_app/features/subjects/domain/usecases/remove_subject_usecase.dart';
import 'package:study_coach_app/features/subjects/presentation/bloc/subjects_bloc.dart';
import 'package:study_coach_app/features/subjects/presentation/bloc/subjects_event.dart';

class TestSubjectRepository implements SubjectRepository {
  List<Subject> subjects = [];
  List<AgendaItem> agendaItems = [];
  int dailyStudyMinutes = 90;
  String preferredTime = 'Morning';
  bool notificationsEnabled = true;
  SettingsPreferences settings = SettingsPreferences();
  bool hasCompletedOnboarding = true;

  int streak = 0;
  double xpProgress = 0.0;
  int level = 1;
  String lastStreakClaimedDate = '';
  int coins = 0;
  List<String> unlockedRewardIds = [];
  String? activeThemeId;
  String? activeBadgeId;

  @override
  Future<List<Subject>> getSubjects() async => subjects;
  @override
  Future<void> saveSubjects(List<Subject> subjects) async =>
      this.subjects = subjects;

  @override
  Future<int> getDailyStudyMinutes() async => dailyStudyMinutes;
  @override
  Future<void> saveDailyStudyMinutes(int minutes) async =>
      dailyStudyMinutes = minutes;

  @override
  Future<String> getPreferredTime() async => preferredTime;
  @override
  Future<void> savePreferredTime(String time) async => preferredTime = time;

  @override
  Future<bool> getNotificationsEnabled() async => notificationsEnabled;
  @override
  Future<void> saveNotificationsEnabled(bool enabled) async =>
      notificationsEnabled = enabled;

  @override
  Future<List<AgendaItem>> getAgendaItems() async => agendaItems;
  @override
  Future<void> saveAgendaItems(List<AgendaItem> items) async =>
      agendaItems = items;

  @override
  Future<SettingsPreferences> getSettingsPreferences() async => settings;
  @override
  Future<void> saveSettingsPreferences(SettingsPreferences settings) async =>
      this.settings = settings;

  @override
  Future<bool> getHasCompletedOnboarding() async => hasCompletedOnboarding;
  @override
  Future<void> saveHasCompletedOnboarding(bool completed) async =>
      hasCompletedOnboarding = completed;

  @override
  Future<int> getStreak() async => streak;
  @override
  Future<void> saveStreak(int streak) async => this.streak = streak;

  @override
  Future<double> getXpProgress() async => xpProgress;
  @override
  Future<void> saveXpProgress(double xp) async => xpProgress = xp;

  @override
  Future<int> getLevel() async => level;
  @override
  Future<void> saveLevel(int level) async => this.level = level;

  @override
  Future<String> getLastStreakClaimedDate() async => lastStreakClaimedDate;
  @override
  Future<void> saveLastStreakClaimedDate(String dateStr) async =>
      lastStreakClaimedDate = dateStr;

  @override
  Future<int> getCoins() async => coins;
  @override
  Future<void> saveCoins(int coins) async => this.coins = coins;

  @override
  Future<List<String>> getUnlockedRewards() async => unlockedRewardIds;
  @override
  Future<void> saveUnlockedRewards(List<String> rewardIds) async =>
      unlockedRewardIds = rewardIds;

  @override
  Future<String?> getActiveThemeId() async => activeThemeId;
  @override
  Future<void> saveActiveThemeId(String? id) async => activeThemeId = id;

  @override
  Future<String?> getActiveBadgeId() async => activeBadgeId;
  @override
  Future<void> saveActiveBadgeId(String? id) async => activeBadgeId = id;
}

class TestStudyHistoryRepository implements StudyHistoryRepository {
  List<StudyHistoryEntry> entries = [];
  @override
  Future<void> addEntry(StudyHistoryEntry entry) async => entries.add(entry);
  @override
  Future<List<StudyHistoryEntry>> getEntries() async => entries;
  @override
  Future<void> removeByAgendaItemId(String id) async =>
      entries.removeWhere((e) => e.agendaItemId == id);
}

class FakeBox implements Box {
  final Map<dynamic, dynamic> _data = {};

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      _data[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, dynamic value) async => _data[key] = value;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

String formatLocalDate(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

void main() {
  late TestSubjectRepository repo;
  late TestStudyHistoryRepository historyRepo;
  late UsageLimitService limitService;
  late SubjectsBloc bloc;

  setUp(() {
    repo = TestSubjectRepository();
    historyRepo = TestStudyHistoryRepository();
    limitService = UsageLimitService(FakeBox());

    bloc = SubjectsBloc(
      repository: repo,
      getSubjectsUseCase: GetSubjectsUseCase(repo),
      addSubjectUseCase: AddSubjectUseCase(repo),
      removeSubjectUseCase: RemoveSubjectUseCase(repo),
      generateStudyPlanUseCase: GenerateStudyPlanUseCase(repo),
      studyHistoryRepository: historyRepo,
      usageLimitService: limitService,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('First qualifying action sets streak to 1 and awards 10 base coins',
      () async {
    repo.agendaItems = [
      AgendaItem(
          id: 'task-1',
          title: 'Math Problem Set',
          durationMinutes: 30,
          tag: 'Math',
          tagColor: Colors.blue,
          isCompleted: false),
    ];
    bloc.add(LoadSubjectsEvent());
    await Future.delayed(const Duration(milliseconds: 50));

    expect(bloc.state.streak, 0);
    expect(bloc.state.coins, 0);

    // Complete task (qualifying action)
    bloc.add(ToggleAgendaItemEvent('task-1'));
    await Future.delayed(const Duration(milliseconds: 50));

    expect(bloc.state.streak, 1);
    expect(bloc.state.coins, 10);
    expect(bloc.state.lastStreakClaimedDate, formatLocalDate(DateTime.now()));
  });

  test(
      'Multiple qualifying actions on same day only grant daily coins & streak once',
      () async {
    repo.agendaItems = [
      AgendaItem(
          id: 'task-1',
          title: 'Task 1',
          durationMinutes: 20,
          tag: 'Math',
          tagColor: Colors.blue,
          isCompleted: false),
      AgendaItem(
          id: 'task-2',
          title: 'Task 2',
          durationMinutes: 20,
          tag: 'Math',
          tagColor: Colors.blue,
          isCompleted: false),
    ];
    bloc.add(LoadSubjectsEvent());
    await Future.delayed(const Duration(milliseconds: 50));

    // First qualifying action (task 1)
    bloc.add(ToggleAgendaItemEvent('task-1'));
    await Future.delayed(const Duration(milliseconds: 50));
    expect(bloc.state.streak, 1);
    expect(bloc.state.coins, 10);

    // Second qualifying action (task 2) on same day
    bloc.add(ToggleAgendaItemEvent('task-2'));
    await Future.delayed(const Duration(milliseconds: 50));

    // Coins and streak must NOT increase again!
    expect(bloc.state.streak, 1);
    expect(bloc.state.coins, 10);

    // Focus session completion on same day
    bloc.add(CompleteQualifyingFocusSessionEvent());
    await Future.delayed(const Duration(milliseconds: 50));

    expect(bloc.state.streak, 1);
    expect(bloc.state.coins, 10);
  });

  test(
      'Consecutive day qualifying action increments streak to 2 and awards +10 coins',
      () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    repo.streak = 1;
    repo.coins = 10;
    repo.lastStreakClaimedDate = formatLocalDate(yesterday);
    repo.agendaItems = [
      AgendaItem(
          id: 'task-1',
          title: 'Physics Session',
          durationMinutes: 25,
          tag: 'Physics',
          tagColor: Colors.blue,
          isCompleted: false),
    ];

    bloc.add(LoadSubjectsEvent());
    await Future.delayed(const Duration(milliseconds: 50));

    expect(bloc.state.streak, 1);
    expect(bloc.state.coins, 10);

    // Complete task today
    bloc.add(ToggleAgendaItemEvent('task-1'));
    await Future.delayed(const Duration(milliseconds: 50));

    expect(bloc.state.streak, 2);
    expect(bloc.state.coins, 20); // 10 + 10 (1.0x)
  });

  test('Streak 5 applies 1.5x multiplier (+15 coins)', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    repo.streak = 4;
    repo.coins = 40;
    repo.lastStreakClaimedDate = formatLocalDate(yesterday);

    bloc.add(LoadSubjectsEvent());
    await Future.delayed(const Duration(milliseconds: 50));

    bloc.add(CompleteQualifyingFocusSessionEvent());
    await Future.delayed(const Duration(milliseconds: 50));

    expect(bloc.state.streak, 5);
    expect(bloc.state.coins, 55); // 40 + 15 (1.5x)
  });

  test('Unlocking reward deducts coins and updates unlockedRewardIds',
      () async {
    repo.coins = 100;
    bloc.add(LoadSubjectsEvent());
    await Future.delayed(const Duration(milliseconds: 50));

    final themeItem =
        RewardItem.catalog.firstWhere((r) => r.id == 'theme_midnight_neon');
    bloc.add(UnlockRewardEvent(rewardId: themeItem.id, cost: themeItem.cost));
    await Future.delayed(const Duration(milliseconds: 50));

    expect(bloc.state.coins, 50);
    expect(bloc.state.unlockedRewardIds, contains('theme_midnight_neon'));
  });

  test('Selecting active theme and badge updates state and repository',
      () async {
    bloc.add(LoadSubjectsEvent());
    await Future.delayed(const Duration(milliseconds: 50));

    bloc.add(SelectActiveThemeEvent('theme_midnight_neon'));
    bloc.add(SelectActiveBadgeEvent('badge_focus_wizard'));
    await Future.delayed(const Duration(milliseconds: 50));

    expect(bloc.state.activeThemeId, 'theme_midnight_neon');
    expect(bloc.state.activeBadgeId, 'badge_focus_wizard');
    expect(repo.activeThemeId, 'theme_midnight_neon');
    expect(repo.activeBadgeId, 'badge_focus_wizard');
  });

  test(
      'Unchecking and rechecking task does not re-trigger streak, coins, or streak reset notification',
      () async {
    repo.agendaItems = [
      AgendaItem(
          id: 'task-1',
          title: 'Task 1',
          durationMinutes: 20,
          tag: 'Math',
          tagColor: Colors.blue,
          isCompleted: false),
    ];
    bloc.add(LoadSubjectsEvent());
    await Future.delayed(const Duration(milliseconds: 50));

    // Complete task (qualifying action)
    bloc.add(ToggleAgendaItemEvent('task-1'));
    await Future.delayed(const Duration(milliseconds: 50));

    expect(bloc.state.streak, 1);
    expect(bloc.state.coins, 10);
    expect(bloc.state.streakCelebrationMessage, isNotNull);
    expect(bloc.state.streakResetTriggered, isFalse);

    // Uncheck task
    bloc.add(ToggleAgendaItemEvent('task-1'));
    await Future.delayed(const Duration(milliseconds: 50));

    expect(bloc.state.streak, 1);
    expect(bloc.state.coins, 10);
    expect(bloc.state.streakCelebrationMessage, isNull);
    expect(bloc.state.streakResetTriggered, isFalse);

    // Recheck task
    bloc.add(ToggleAgendaItemEvent('task-1'));
    await Future.delayed(const Duration(milliseconds: 50));

    // Coins, streak, celebration message, and streak reset must remain unchanged!
    expect(bloc.state.streak, 1);
    expect(bloc.state.coins, 10);
    expect(bloc.state.streakCelebrationMessage, isNull);
    expect(bloc.state.streakResetTriggered, isFalse);
  });

  test(
      'Device clock set backward relative to lastActiveDate blocks claim and preserves streak and coins',
      () async {
    final futureDate = DateTime.now().add(const Duration(days: 2));
    repo.streak = 5;
    repo.coins = 50;
    repo.lastStreakClaimedDate = formatLocalDate(futureDate);
    repo.agendaItems = [
      AgendaItem(
          id: 'task-1',
          title: 'Task 1',
          durationMinutes: 20,
          tag: 'Math',
          tagColor: Colors.blue,
          isCompleted: false),
    ];

    bloc.add(LoadSubjectsEvent());
    await Future.delayed(const Duration(milliseconds: 50));

    expect(bloc.state.streak, 5);
    expect(bloc.state.coins, 50);
    expect(bloc.state.streakResetTriggered, isFalse);

    // Attempt qualifying action when today < lastActiveDate
    bloc.add(ToggleAgendaItemEvent('task-1'));
    await Future.delayed(const Duration(milliseconds: 50));

    // Must be a no-op! No streak reset, no streak award, no celebration popup, no coin change.
    expect(bloc.state.streak, 5);
    expect(bloc.state.coins, 50);
    expect(bloc.state.streakCelebrationMessage, isNull);
    expect(bloc.state.streakResetTriggered, isFalse);
  });
}
