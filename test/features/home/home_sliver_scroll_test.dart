import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:study_coach_app/core/services/usage_limit_service.dart';
import 'package:study_coach_app/core/widgets/app_snackbar.dart';
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

  Widget buildWidget(SubjectsState subjectsState) {
    testBox.put('themeMode', 'dark');

    final timerBloc = TimerBloc(timerDataSource: timerDataSource);

    final subjectsBloc = SubjectsBloc(
      repository: repository,
      getSubjectsUseCase: GetSubjectsUseCase(repository),
      addSubjectUseCase: AddSubjectUseCase(repository),
      removeSubjectUseCase: RemoveSubjectUseCase(repository),
      generateStudyPlanUseCase: GenerateStudyPlanUseCase(repository),
      studyHistoryRepository: studyHistoryRepository,
      usageLimitService: usageLimitService,
    )..emit(subjectsState);

    return MultiBlocProvider(
      providers: [
        BlocProvider<SubjectsBloc>(create: (_) => subjectsBloc),
        BlocProvider<NavigationBloc>(create: (_) => NavigationBloc()),
        BlocProvider<ThemeBloc>(create: (_) => ThemeBloc(testBox)),
        BlocProvider<TimerBloc>(create: (_) => timerBloc),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: HomeDashboardPage(),
        ),
      ),
    );
  }

  testWidgets(
      'HomeDashboardPage renders CustomScrollView and pinned SliverAppBar',
      (tester) async {
    final state = SubjectsState(
      settings: SettingsPreferences(),
      subjects: [
        Subject(id: '1', name: 'Mathematics', color: Colors.blue),
      ],
      agendaItems: [
        AgendaItem(
          id: '1',
          title: 'Math Part 1',
          tag: 'Mathematics',
          tagColor: Colors.blue,
          durationMinutes: 30,
        ),
      ],
    );

    await tester.pumpWidget(buildWidget(state));
    await tester.pumpAndSettle();

    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byType(SliverAppBar), findsOneWidget);
    expect(find.text("Today's Agenda"), findsOneWidget);
  });

  testWidgets(
      'AppSnackbar renders single line concise title with elevated bottom margin',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppSnackbar.show(
                    context,
                    title: 'Study plan updated',
                    type: SnackbarType.success,
                  );
                },
                child: const Text('Show Toast'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Toast'));
    await tester.pump();

    expect(find.text('Study plan updated'), findsOneWidget);
    final snackBarFinder = find.byType(SnackBar);
    expect(snackBarFinder, findsOneWidget);

    final snackBar = tester.widget<SnackBar>(snackBarFinder);
    expect(snackBar.margin, isNotNull);
    final margin = snackBar.margin as EdgeInsets;
    expect(margin.bottom, equals(84.0));
  });
}
