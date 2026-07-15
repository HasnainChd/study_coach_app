import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:study_coach_app/features/analytics/domain/entities/study_history_entry.dart';
import 'package:study_coach_app/features/analytics/domain/repositories/study_history_repository.dart';
import 'package:study_coach_app/features/subjects/domain/entities/subject.dart';
import 'package:study_coach_app/features/subjects/domain/entities/agenda_item.dart';
import 'package:study_coach_app/features/subjects/domain/entities/settings_preferences.dart';
import 'package:study_coach_app/features/subjects/domain/repositories/subject_repository.dart';
import 'package:study_coach_app/features/subjects/domain/usecases/add_subject_usecase.dart';
import 'package:study_coach_app/features/subjects/domain/usecases/get_subjects_usecase.dart';
import 'package:study_coach_app/features/subjects/domain/usecases/remove_subject_usecase.dart';
import 'package:study_coach_app/features/subjects/domain/entities/study_plan_result.dart';
import 'package:study_coach_app/features/subjects/domain/usecases/generate_study_plan_usecase.dart';
import 'package:study_coach_app/features/subjects/presentation/bloc/subjects_bloc.dart';
import 'package:study_coach_app/features/subjects/presentation/bloc/subjects_event.dart';
import 'package:study_coach_app/features/subjects/presentation/bloc/subjects_state.dart';
import 'package:study_coach_app/core/services/usage_limit_service.dart';

class MockStudyHistoryRepository implements StudyHistoryRepository {
  List<StudyHistoryEntry> entries = [];

  @override
  Future<void> addEntry(StudyHistoryEntry entry) async {
    entries = [...entries, entry];
  }

  @override
  Future<List<StudyHistoryEntry>> getEntries() async => entries;

  @override
  Future<void> removeByAgendaItemId(String agendaItemId) async {
    entries = entries.where((entry) => entry.agendaItemId != agendaItemId).toList();
  }
}

class MockSubjectRepository implements SubjectRepository {
  List<Subject> subjects = [];
  List<AgendaItem> agendaItems = [];
  int dailyStudyMinutes = 90;
  String preferredTime = 'Morning';
  bool notificationsEnabled = true;
  SettingsPreferences settings = SettingsPreferences();

  @override
  Future<List<Subject>> getSubjects() async => subjects;

  @override
  Future<void> saveSubjects(List<Subject> subjects) async {
    this.subjects = subjects;
  }

  @override
  Future<int> getDailyStudyMinutes() async => dailyStudyMinutes;

  @override
  Future<void> saveDailyStudyMinutes(int minutes) async {
    dailyStudyMinutes = minutes;
  }

  @override
  Future<String> getPreferredTime() async => preferredTime;

  @override
  Future<void> savePreferredTime(String time) async {
    preferredTime = time;
  }

  @override
  Future<bool> getNotificationsEnabled() async => notificationsEnabled;

  @override
  Future<void> saveNotificationsEnabled(bool enabled) async {
    notificationsEnabled = enabled;
  }

  @override
  Future<List<AgendaItem>> getAgendaItems() async => agendaItems;

  @override
  Future<void> saveAgendaItems(List<AgendaItem> items) async {
    agendaItems = items;
  }

  @override
  Future<SettingsPreferences> getSettingsPreferences() async => settings;

  @override
  Future<void> saveSettingsPreferences(SettingsPreferences settings) async {
    this.settings = settings;
  }

  bool hasCompletedOnboarding = false;

  @override
  Future<bool> getHasCompletedOnboarding() async => hasCompletedOnboarding;

  @override
  Future<void> saveHasCompletedOnboarding(bool completed) async {
    hasCompletedOnboarding = completed;
  }

  int streak = 12;
  double xpProgress = 0.68;
  int level = 7;
  String lastStreakClaimedDate = '';

  @override
  Future<int> getStreak() async => streak;

  @override
  Future<void> saveStreak(int streak) async {
    this.streak = streak;
  }

  @override
  Future<double> getXpProgress() async => xpProgress;

  @override
  Future<void> saveXpProgress(double xp) async {
    xpProgress = xp;
  }

  @override
  Future<int> getLevel() async => level;

  @override
  Future<void> saveLevel(int level) async {
    this.level = level;
  }

  @override
  Future<String> getLastStreakClaimedDate() async => lastStreakClaimedDate;

  @override
  Future<void> saveLastStreakClaimedDate(String dateStr) async {
    lastStreakClaimedDate = dateStr;
  }
}

class MockGenerateStudyPlanUseCase implements GenerateStudyPlanUseCase {
  @override
  final SubjectRepository repository;
  
  MockGenerateStudyPlanUseCase(this.repository);

  @override
  Future<StudyPlanResult> call({
    required int dailyMinutes,
    required String preferredTime,
  }) async {
    return StudyPlanResult(
      agendaItems: [
        AgendaItem(
          id: 'mock_1',
          title: 'Mock study topic',
          tag: 'History',
          durationMinutes: 45,
          tagColor: Colors.red,
        ),
      ],
    );
  }
}

class FakeUsageLimitService implements UsageLimitService {
  @override
  Future<bool> canPerformAction(UsageType type) async => true;

  @override
  Future<void> recordAction(UsageType type) async {}

  @override
  Future<int> remainingToday(UsageType type) async => type.limit;
}

class DeniedUsageLimitService implements UsageLimitService {
  @override
  Future<bool> canPerformAction(UsageType type) async => false;

  @override
  Future<void> recordAction(UsageType type) async {}

  @override
  Future<int> remainingToday(UsageType type) async => 0;
}

void main() {
  late MockSubjectRepository repository;
  late GetSubjectsUseCase getSubjectsUseCase;
  late AddSubjectUseCase addSubjectUseCase;
  late RemoveSubjectUseCase removeSubjectUseCase;
  late MockGenerateStudyPlanUseCase generateStudyPlanUseCase;
  late MockStudyHistoryRepository studyHistoryRepository;
  late SubjectsBloc bloc;

  setUp(() {
    repository = MockSubjectRepository();
    studyHistoryRepository = MockStudyHistoryRepository();
    getSubjectsUseCase = GetSubjectsUseCase(repository);
    addSubjectUseCase = AddSubjectUseCase(repository);
    removeSubjectUseCase = RemoveSubjectUseCase(repository);
    generateStudyPlanUseCase = MockGenerateStudyPlanUseCase(repository);
    bloc = SubjectsBloc(
      repository: repository,
      getSubjectsUseCase: getSubjectsUseCase,
      addSubjectUseCase: addSubjectUseCase,
      removeSubjectUseCase: removeSubjectUseCase,
      generateStudyPlanUseCase: generateStudyPlanUseCase,
      studyHistoryRepository: studyHistoryRepository,
      usageLimitService: FakeUsageLimitService(),
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is correct', () {
    expect(bloc.state.subjects, isEmpty);
    expect(bloc.state.status, SubjectsStatus.initial);
  });

  test('LoadSubjectsEvent remains empty when data is empty', () async {
    bloc.add(LoadSubjectsEvent());
    
    await expectLater(
      bloc.stream,
      emitsInOrder([
        predicate<SubjectsState>((state) => state.status == SubjectsStatus.loading),
        predicate<SubjectsState>((state) => state.status == SubjectsStatus.success && state.subjects.isEmpty),
      ]),
    );
  });

  test('AddSubjectEvent successfully adds validation-passed subject', () async {
    repository.subjects = [];
    
    bloc.add(AddSubjectEvent(
      name: 'History',
      color: Colors.red,
      examDate: null,
    ));

    await expectLater(
      bloc.stream,
      emitsInOrder([
        predicate<SubjectsState>((state) => state.status == SubjectsStatus.loading),
        predicate<SubjectsState>((state) => state.status == SubjectsStatus.success && state.subjects.any((s) => s.name == 'History')),
      ]),
    );
  });

  test('AddSubjectEvent fails when adding duplicate subject name', () async {
    final originalSubject = Subject(id: '1', name: 'History', color: Colors.red);
    repository.subjects = [originalSubject];

    bloc.add(AddSubjectEvent(
      name: 'History',
      color: Colors.red,
      examDate: null,
    ));

    await expectLater(
      bloc.stream,
      emitsInOrder([
        predicate<SubjectsState>((state) => state.status == SubjectsStatus.loading),
        predicate<SubjectsState>((state) => state.status == SubjectsStatus.failure && state.errorMessage == 'Subject with this name already exists'),
      ]),
    );
  });

  test('AddSubjectEvent fails when name exceeds 40 characters', () async {
    final longName = 'A' * 41;

    bloc.add(AddSubjectEvent(
      name: longName,
      color: Colors.red,
      examDate: null,
    ));

    await expectLater(
      bloc.stream,
      emitsInOrder([
        predicate<SubjectsState>((state) => state.status == SubjectsStatus.loading),
        predicate<SubjectsState>((state) => state.status == SubjectsStatus.failure && state.errorMessage == 'Subject name cannot exceed 40 characters'),
      ]),
    );
  });

  test('GenerateStudyPlanEvent emits planGenerating and planGenerated states', () async {
    bloc.add(GenerateStudyPlanEvent());

    await expectLater(
      bloc.stream,
      emitsInOrder([
        predicate<SubjectsState>((state) => state.status == SubjectsStatus.planGenerating),
        predicate<SubjectsState>((state) => state.status == SubjectsStatus.planGenerated && state.agendaItems.any((i) => i.id == 'mock_1')),
      ]),
    );
  });

  test('ClaimStreakEvent increments streak when not claimed today', () async {
    bloc.emit(bloc.state.copyWith(
      streak: 12,
      lastStreakClaimedDate: '',
    ));
    repository.streak = 12;
    repository.lastStreakClaimedDate = '';

    bloc.add(ClaimStreakEvent());

    await expectLater(
      bloc.stream,
      emits(
        predicate<SubjectsState>((state) =>
            state.streak == 13 &&
            state.lastStreakClaimedDate == DateTime.now().toIso8601String().substring(0, 10)),
      ),
    );
  });

  test('ClaimStreakEvent does not increment streak if already claimed today', () async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    repository.streak = 12;
    repository.lastStreakClaimedDate = today;

    bloc.emit(bloc.state.copyWith(streak: 12, lastStreakClaimedDate: today));

    bloc.add(ClaimStreakEvent());

    expect(bloc.state.streak, 12);
  });

  test('ToggleAgendaItemEvent auto-increments XP and claims streak on completion', () async {
    final item1 = AgendaItem(
      id: 'task_1',
      title: 'Calculus',
      tag: 'Math',
      durationMinutes: 30,
      tagColor: Colors.purple,
      isCompleted: false,
    );
    final item2 = AgendaItem(
      id: 'task_2',
      title: 'Algebra',
      tag: 'Math',
      durationMinutes: 30,
      tagColor: Colors.purple,
      isCompleted: false,
    );
    bloc.emit(bloc.state.copyWith(
      subjects: [
        Subject(id: 's_math', name: 'Math', color: Colors.purple, progress: 0.0),
      ],
      agendaItems: [item1, item2],
      xpProgress: 0.20,
      streak: 12,
      lastStreakClaimedDate: '',
    ));

    bloc.add(ToggleAgendaItemEvent('task_1'));

    await expectLater(
      bloc.stream,
      emits(
        predicate<SubjectsState>((state) =>
            state.agendaItems.first.isCompleted &&
            (state.xpProgress - 0.70).abs() < 0.001 && // 0.20 + 0.50 = 0.70
            state.subjects.first.progress == 0.50 &&
            state.streak == 13),
      ),
    );
  });

  test('ToggleAgendaItemEvent deducts XP and resets hasEarnedXp on uncheck', () async {
    final item1 = AgendaItem(
      id: 'task_1',
      title: 'Calculus',
      tag: 'Math',
      durationMinutes: 30,
      tagColor: Colors.purple,
      isCompleted: true,
      hasEarnedXp: true,
    );
    final item2 = AgendaItem(
      id: 'task_2',
      title: 'Algebra',
      tag: 'Math',
      durationMinutes: 30,
      tagColor: Colors.purple,
      isCompleted: false,
    );
    bloc.emit(bloc.state.copyWith(
      subjects: [
        Subject(id: 's_math', name: 'Math', color: Colors.purple, progress: 0.0),
      ],
      agendaItems: [item1, item2],
      xpProgress: 0.66,
      level: 7,
      streak: 12,
      lastStreakClaimedDate: DateTime.now().toIso8601String().substring(0, 10),
    ));

    bloc.add(ToggleAgendaItemEvent('task_1'));

    await expectLater(
      bloc.stream,
      emits(
        predicate<SubjectsState>((state) {
          final task = state.agendaItems.first;
          return !task.isCompleted &&
              !task.hasEarnedXp &&
              (state.xpProgress - 0.16).abs() < 0.001 && // 0.66 - 0.50
              state.level == 7 &&
              state.streak == 12;
        }),
      ),
    );
  });

  test('ToggleAgendaItemEvent re-awards XP after re-check', () async {
    final items = List.generate(
      3,
      (i) => AgendaItem(
        id: 'task_${i + 1}',
        title: 'Task ${i + 1}',
        tag: 'Math',
        durationMinutes: 30,
        tagColor: Colors.purple,
        isCompleted: false,
      ),
    );
    const baselineXp = 0.33;
    bloc.emit(bloc.state.copyWith(
      subjects: [
        Subject(id: 's_math', name: 'Math', color: Colors.purple, progress: 0.0),
      ],
      agendaItems: items,
      xpProgress: baselineXp,
      level: 7,
    ));

    bloc.add(ToggleAgendaItemEvent('task_1'));
    await bloc.stream.firstWhere((s) => s.agendaItems.first.isCompleted);

    bloc.add(ToggleAgendaItemEvent('task_1'));
    await bloc.stream.firstWhere((s) => !s.agendaItems.first.isCompleted);

    bloc.add(ToggleAgendaItemEvent('task_1'));
    await expectLater(
      bloc.stream,
      emits(
        predicate<SubjectsState>((state) {
          final task = state.agendaItems.first;
          final expectedXp = baselineXp + (1.0 / 3);
          return task.isCompleted &&
              task.hasEarnedXp &&
              (state.xpProgress - expectedXp).abs() < 0.001;
        }),
      ),
    );
  });

  test('ToggleAgendaItemEvent rapid toggles do not drift XP from baseline', () async {
    final items = List.generate(
      3,
      (i) => AgendaItem(
        id: 'task_${i + 1}',
        title: 'Task ${i + 1}',
        tag: 'Math',
        durationMinutes: 30,
        tagColor: Colors.purple,
      ),
    );
    const baselineXp = 0.33;
    bloc.emit(bloc.state.copyWith(
      subjects: [
        Subject(id: 's_math', name: 'Math', color: Colors.purple, progress: 0.0),
      ],
      agendaItems: items,
      xpProgress: baselineXp,
      level: 7,
    ));

    for (var i = 0; i < 6; i++) {
      bloc.add(ToggleAgendaItemEvent('task_1'));
      await bloc.stream.firstWhere(
        (s) => i.isEven
            ? s.agendaItems.first.isCompleted
            : !s.agendaItems.first.isCompleted,
      );
    }

    expect((bloc.state.xpProgress - baselineXp).abs() < 0.001, isTrue);
    expect(bloc.state.agendaItems.first.isCompleted, isFalse);
    expect(bloc.state.agendaItems.first.hasEarnedXp, isFalse);
  });

  test('ToggleAgendaItemEvent logs and removes study history entries', () async {
    final item = AgendaItem(
      id: 'task_1',
      title: 'Urdu',
      tag: 'Urdu',
      durationMinutes: 45,
      tagColor: Colors.green,
    );
    bloc.emit(bloc.state.copyWith(
      subjects: [
        Subject(id: 's_urdu', name: 'Urdu', color: Colors.green, progress: 0.0),
      ],
      agendaItems: [item],
      xpProgress: 0.0,
    ));

    bloc.add(ToggleAgendaItemEvent('task_1'));
    await bloc.stream.firstWhere((s) => s.agendaItems.first.isCompleted);

    expect(studyHistoryRepository.entries.length, 1);
    expect(studyHistoryRepository.entries.first.agendaItemId, 'task_1');
    expect(studyHistoryRepository.entries.first.subjectId, 's_urdu');
    expect(studyHistoryRepository.entries.first.durationMinutes, 45);

    bloc.add(ToggleAgendaItemEvent('task_1'));
    await bloc.stream.firstWhere((s) => !s.agendaItems.first.isCompleted);

    expect(studyHistoryRepository.entries, isEmpty);
  });

  test('ToggleAgendaItemEvent uncheck does not reverse auto-claimed streak', () async {
    final item = AgendaItem(
      id: 'task_1',
      title: 'Calculus',
      tag: 'Math',
      durationMinutes: 30,
      tagColor: Colors.purple,
      isCompleted: true,
      hasEarnedXp: true,
    );
    final today = DateTime.now().toIso8601String().substring(0, 10);
    bloc.emit(bloc.state.copyWith(
      subjects: [
        Subject(id: 's_math', name: 'Math', color: Colors.purple, progress: 0.0),
      ],
      agendaItems: [item],
      xpProgress: 0.50,
      streak: 5,
      lastStreakClaimedDate: today,
    ));

    bloc.add(ToggleAgendaItemEvent('task_1'));

    await expectLater(
      bloc.stream,
      emits(
        predicate<SubjectsState>((state) =>
            !state.agendaItems.first.isCompleted &&
            state.streak == 5 &&
            state.lastStreakClaimedDate == today),
      ),
    );
  });

  test('RemoveSubjectEvent and UndoRemoveSubjectEvent successfully delete and restore subject and tasks', () async {
    final sub = Subject(id: 's_history', name: 'History', color: Colors.blue, progress: 0.0);
    final item = AgendaItem(
      id: 'task_history',
      title: 'World War 1',
      tag: 'History',
      durationMinutes: 30,
      tagColor: Colors.blue,
      isCompleted: false,
    );

    repository.subjects = [sub];
    repository.agendaItems = [item];

    bloc.emit(bloc.state.copyWith(
      subjects: [sub],
      agendaItems: [item],
    ));

    bloc.add(RemoveSubjectEvent('s_history'));

    await expectLater(
      bloc.stream,
      emitsInOrder([
        predicate<SubjectsState>((state) => state.status == SubjectsStatus.loading),
        predicate<SubjectsState>((state) =>
            state.status == SubjectsStatus.success &&
            state.subjects.isEmpty &&
            state.agendaItems.isEmpty),
      ]),
    );

    bloc.add(UndoRemoveSubjectEvent());

    await expectLater(
      bloc.stream,
      emitsInOrder([
        predicate<SubjectsState>((state) => state.status == SubjectsStatus.loading),
        predicate<SubjectsState>((state) =>
            state.status == SubjectsStatus.success &&
            state.subjects.length == 1 &&
            state.subjects.first.id == 's_history' &&
            state.agendaItems.length == 1 &&
            state.agendaItems.first.id == 'task_history'),
      ]),
    );
  });

  test('UpdateSubjectEvent updates subject details and cascadingly updates agenda tags and colors', () async {
    final sub = Subject(id: 's_history', name: 'History', color: Colors.blue, progress: 0.0);
    final item = AgendaItem(
      id: 'task_history',
      title: 'World War 1',
      tag: 'History',
      durationMinutes: 30,
      tagColor: Colors.blue,
      isCompleted: false,
    );

    repository.subjects = [sub];
    repository.agendaItems = [item];

    bloc.emit(bloc.state.copyWith(
      subjects: [sub],
      agendaItems: [item],
    ));

    bloc.add(UpdateSubjectEvent(
      id: 's_history',
      name: 'World History',
      color: Colors.red,
      examDate: DateTime(2027, 10, 10),
    ));

    await expectLater(
      bloc.stream,
      emitsInOrder([
        predicate<SubjectsState>((state) => state.status == SubjectsStatus.loading),
        predicate<SubjectsState>((state) =>
            state.status == SubjectsStatus.success &&
            state.subjects.first.name == 'World History' &&
            state.subjects.first.color == Colors.red &&
            state.agendaItems.first.tag == 'World History' &&
            state.agendaItems.first.tagColor == Colors.red),
      ]),
    );
  });

  test('GenerateStudyPlanEvent and RegenerateStudyPlanEvent emit limitReached and reset to initial when limit is reached', () async {
    final deniedBloc = SubjectsBloc(
      repository: repository,
      getSubjectsUseCase: getSubjectsUseCase,
      addSubjectUseCase: addSubjectUseCase,
      removeSubjectUseCase: removeSubjectUseCase,
      generateStudyPlanUseCase: generateStudyPlanUseCase,
      studyHistoryRepository: studyHistoryRepository,
      usageLimitService: DeniedUsageLimitService(),
    );

    deniedBloc.add(GenerateStudyPlanEvent());

    await expectLater(
      deniedBloc.stream,
      emitsInOrder([
        predicate<SubjectsState>((state) => state.status == SubjectsStatus.limitReached),
        predicate<SubjectsState>((state) => state.status == SubjectsStatus.initial),
      ]),
    );

    deniedBloc.add(RegenerateStudyPlanEvent(30, '09:00'));

    await expectLater(
      deniedBloc.stream,
      emitsInOrder([
        predicate<SubjectsState>((state) => state.status == SubjectsStatus.limitReached),
        predicate<SubjectsState>((state) => state.status == SubjectsStatus.initial),
      ]),
    );

    await deniedBloc.close();
  });
}
