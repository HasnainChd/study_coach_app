import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:study_coach_app/core/services/usage_limit_service.dart';
import 'package:study_coach_app/features/analytics/domain/entities/study_history_entry.dart';
import 'package:study_coach_app/features/analytics/domain/repositories/study_history_repository.dart';
import 'package:study_coach_app/features/bloc/navigation_bloc.dart';
import 'package:study_coach_app/features/bloc/subjects_bloc.dart';
import 'package:study_coach_app/features/bloc/theme_bloc.dart';
import 'package:study_coach_app/features/bloc/timer_bloc.dart';
import 'package:study_coach_app/features/focus/data/datasources/timer_local_data_source.dart';
import 'package:study_coach_app/features/focus/data/models/timer_persisted_state_model.dart';
import 'package:study_coach_app/features/home/presentation/pages/home_dashboard_page.dart';
import 'package:study_coach_app/features/subjects/domain/repositories/subject_repository.dart';
import 'package:study_coach_app/features/subjects/domain/usecases/add_subject_usecase.dart';
import 'package:study_coach_app/features/subjects/domain/usecases/generate_study_plan_usecase.dart';
import 'package:study_coach_app/features/subjects/domain/usecases/get_subjects_usecase.dart';
import 'package:study_coach_app/features/subjects/domain/usecases/remove_subject_usecase.dart';

class MockSubjectRepository implements SubjectRepository {
  @override
  Future<List<Subject>> getSubjects() async => [];
  @override
  Future<void> saveSubjects(List<Subject> subjects) async {}
  @override
  Future<List<AgendaItem>> getAgendaItems() async => [];
  @override
  Future<void> saveAgendaItems(List<AgendaItem> items) async {}
  @override
  Future<int> getStreak() async => 0;
  @override
  Future<void> saveStreak(int streak) async {}
  @override
  Future<String> getLastStreakClaimedDate() async => '';
  @override
  Future<void> saveLastStreakClaimedDate(String dateStr) async {}
  @override
  Future<int> getLevel() async => 1;
  @override
  Future<void> saveLevel(int level) async {}
  @override
  Future<double> getXpProgress() async => 0.0;
  @override
  Future<void> saveXpProgress(double xp) async {}
  @override
  Future<int> getCoins() async => 0;
  @override
  Future<void> saveCoins(int coins) async {}
  @override
  Future<List<String>> getUnlockedRewards() async => [];
  @override
  Future<void> saveUnlockedRewards(List<String> rewardIds) async {}
  @override
  Future<String?> getActiveThemeId() async => null;
  @override
  Future<void> saveActiveThemeId(String? id) async {}
  @override
  Future<String?> getActiveBadgeId() async => null;
  @override
  Future<void> saveActiveBadgeId(String? id) async {}
  @override
  Future<int> getDailyStudyMinutes() async => 60;
  @override
  Future<void> saveDailyStudyMinutes(int minutes) async {}
  @override
  Future<String> getPreferredTime() async => '09:00';
  @override
  Future<void> savePreferredTime(String time) async {}
  @override
  Future<bool> getNotificationsEnabled() async => true;
  @override
  Future<void> saveNotificationsEnabled(bool enabled) async {}
  @override
  Future<bool> getHasCompletedOnboarding() async => true;
  @override
  Future<void> saveHasCompletedOnboarding(bool completed) async {}
  @override
  Future<SettingsPreferences> getSettingsPreferences() async =>
      SettingsPreferences();
  @override
  Future<void> saveSettingsPreferences(SettingsPreferences settings) async {}
}

class MockStudyHistoryRepository implements StudyHistoryRepository {
  @override
  Future<void> addEntry(StudyHistoryEntry entry) async {}
  @override
  Future<List<StudyHistoryEntry>> getEntries() async => [];
  @override
  Future<void> removeByAgendaItemId(String agendaItemId) async {}
}

class MockTimerLocalDataSource implements TimerLocalDataSource {
  @override
  Future<void> saveState(TimerPersistedStateModel state) async {}
  @override
  Future<TimerPersistedStateModel?> getSavedState() async => null;
  @override
  Future<void> clearState() async {}
}

class FakeBox implements Box {
  final Map<dynamic, dynamic> _data = {};

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      _data[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, dynamic value) async => _data[key] = value;

  @override
  Future<void> delete(dynamic key) async => _data.remove(key);

  @override
  bool get isOpen => true;

  @override
  Future<void> close() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockSubjectRepository repository;
  late MockStudyHistoryRepository studyHistoryRepository;
  late UsageLimitService usageLimitService;
  late MockTimerLocalDataSource timerDataSource;
  late FakeBox testBox;

  setUp(() {
    testBox = FakeBox();
    repository = MockSubjectRepository();
    studyHistoryRepository = MockStudyHistoryRepository();
    usageLimitService = UsageLimitService(testBox);
    timerDataSource = MockTimerLocalDataSource();
  });

  SubjectsBloc createSubjectsBloc(SubjectsState initialState) {
    return SubjectsBloc(
      repository: repository,
      getSubjectsUseCase: GetSubjectsUseCase(repository),
      addSubjectUseCase: AddSubjectUseCase(repository),
      removeSubjectUseCase: RemoveSubjectUseCase(repository),
      generateStudyPlanUseCase: GenerateStudyPlanUseCase(repository),
      studyHistoryRepository: studyHistoryRepository,
      usageLimitService: usageLimitService,
    )..emit(initialState);
  }

  Widget buildWidget(SubjectsState subjectsState,
      {bool isDark = true, TimerState? timerState}) {
    if (isDark) {
      testBox.put('themeMode', 'dark');
    } else {
      testBox.put('themeMode', 'light');
    }

    final timerBloc = TimerBloc(timerDataSource: timerDataSource);
    if (timerState != null) {
      timerBloc.emit(timerState);
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<SubjectsBloc>(
          create: (_) => createSubjectsBloc(subjectsState),
        ),
        BlocProvider<NavigationBloc>(
          create: (_) => NavigationBloc(),
        ),
        BlocProvider<TimerBloc>(
          create: (_) => timerBloc,
        ),
        BlocProvider<ThemeBloc>(
          create: (_) => ThemeBloc(testBox),
        ),
      ],
      child: MaterialApp(
        theme: isDark ? ThemeData.dark() : ThemeData.light(),
        home: const Scaffold(
          body: HomeDashboardPage(),
        ),
      ),
    );
  }

  testWidgets(
      'Home Bento Grid renders streak, remaining time, completed count on 360dp screen without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final subjects = [
      Subject(id: 's1', name: 'Computer Science', color: Colors.purple),
      Subject(id: 's2', name: 'English', color: Colors.blue),
    ];

    final agendaItems = [
      AgendaItem(
        id: '1',
        title: 'Data Structures Part 1',
        tag: 'Computer Science',
        durationMinutes: 30,
        tagColor: Colors.purple,
        isCompleted: false,
      ),
      AgendaItem(
        id: '2',
        title: 'Data Structures Part 2',
        tag: 'Computer Science',
        durationMinutes: 30,
        tagColor: Colors.purple,
        isCompleted: false,
      ),
      AgendaItem(
        id: '3',
        title: 'Essay Writing',
        tag: 'English',
        durationMinutes: 20,
        tagColor: Colors.blue,
        isCompleted: true,
      ),
    ];

    final state = SubjectsState(
      subjects: subjects,
      agendaItems: agendaItems,
      streak: 7,
      level: 3,
      xpProgress: 0.6,
      coins: 120,
      settings: SettingsPreferences(),
    );

    await tester.pumpWidget(buildWidget(state, isDark: true));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('7 Day Streak'), findsOneWidget);
    expect(find.text('Lvl 3 Scholar'), findsOneWidget);
    expect(find.text('60 min left'), findsOneWidget);
    expect(find.text('1 of 3 done'), findsOneWidget);
    expect(find.textContaining('Quick Start Session'), findsOneWidget);
  });

  testWidgets('Home Bento Grid handles 0-day streak and 0 tasks state',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final state = SubjectsState(
      subjects: [],
      agendaItems: [],
      streak: 0,
      level: 1,
      xpProgress: 0.0,
      coins: 0,
      settings: SettingsPreferences(),
    );

    await tester.pumpWidget(buildWidget(state, isDark: false));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('0 Day Streak'), findsOneWidget);
    expect(find.text('Lvl 1 Scholar'), findsOneWidget);
    expect(find.text('0 min left'), findsOneWidget);
    expect(find.text('0 of 0 done'), findsOneWidget);
  });

  testWidgets(
      'Home Bento Grid displays compact rows with accent border for next active task and handles 5+ tasks',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final subjects = [
      Subject(id: 's1', name: 'Math', color: Colors.green),
    ];

    final agendaItems = List.generate(
      6,
      (index) => AgendaItem(
        id: 'task_$index',
        title:
            'Math Exercise Part $index with very long descriptive title overflow check',
        tag: 'Math',
        durationMinutes: 20,
        tagColor: Colors.green,
        isCompleted: index < 2,
      ),
    );

    final state = SubjectsState(
      subjects: subjects,
      agendaItems: agendaItems,
      streak: 12,
      level: 4,
      xpProgress: 0.8,
      coins: 250,
      settings: SettingsPreferences(),
    );

    await tester.pumpWidget(buildWidget(state, isDark: false));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('12 Day Streak'), findsOneWidget);
    expect(find.text('80 min left'), findsOneWidget);
    expect(find.text('2 of 6 done'), findsOneWidget);

    final titleText =
        tester.widget<Text>(find.textContaining('Math Exercise Part 0').first);
    expect(titleText.maxLines, equals(2));
  });

  testWidgets(
      'Quick Start button updates state to Resume Active Session when TimerBloc has active session',
      (WidgetTester tester) async {
    final state = SubjectsState(
      subjects: [Subject(id: 's1', name: 'Physics', color: Colors.purple)],
      agendaItems: [
        AgendaItem(
          id: '1',
          title: 'Quantum Mechanics',
          tag: 'Physics',
          durationMinutes: 25,
          tagColor: Colors.purple,
        )
      ],
      streak: 5,
      level: 2,
      xpProgress: 0.5,
      coins: 100,
      settings: SettingsPreferences(),
    );

    final timerState = TimerState(
      remainingSeconds: 1200,
      totalSeconds: 1500,
      isRunning: true,
      status: TimerStatus.running,
      taskId: '1',
      taskTitle: 'Quantum Mechanics',
    );

    await tester.pumpWidget(buildWidget(state, timerState: timerState));
    await tester.pumpAndSettle();

    expect(find.text('Resume Active Session'), findsOneWidget);
  });
}
