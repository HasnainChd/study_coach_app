import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:study_coach_app/features/subjects/domain/entities/subject.dart';
import 'package:study_coach_app/features/subjects/domain/entities/agenda_item.dart';
import 'package:study_coach_app/features/subjects/domain/entities/settings_preferences.dart';
import 'package:study_coach_app/features/subjects/domain/repositories/subject_repository.dart';
import 'package:study_coach_app/features/subjects/domain/usecases/add_subject_usecase.dart';
import 'package:study_coach_app/features/subjects/domain/usecases/get_subjects_usecase.dart';
import 'package:study_coach_app/features/subjects/domain/usecases/remove_subject_usecase.dart';
import 'package:study_coach_app/features/subjects/domain/usecases/generate_study_plan_usecase.dart';
import 'package:study_coach_app/features/subjects/presentation/bloc/subjects_bloc.dart';
import 'package:study_coach_app/features/subjects/presentation/bloc/subjects_event.dart';
import 'package:study_coach_app/features/subjects/presentation/bloc/subjects_state.dart';

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
  Future<List<AgendaItem>> call({
    required int dailyMinutes,
    required String preferredTime,
  }) async {
    return [
      AgendaItem(
        id: 'mock_1',
        title: 'Mock study topic',
        tag: 'History',
        durationMinutes: 45,
        tagColor: Colors.red,
      )
    ];
  }
}

void main() {
  late MockSubjectRepository repository;
  late GetSubjectsUseCase getSubjectsUseCase;
  late AddSubjectUseCase addSubjectUseCase;
  late RemoveSubjectUseCase removeSubjectUseCase;
  late MockGenerateStudyPlanUseCase generateStudyPlanUseCase;
  late SubjectsBloc bloc;

  setUp(() {
    repository = MockSubjectRepository();
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
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is correct', () {
    expect(bloc.state.subjects, isEmpty);
    expect(bloc.state.status, SubjectsStatus.initial);
  });

  test('LoadSubjectsEvent populates initial default mock data if empty', () async {
    bloc.add(LoadSubjectsEvent());
    
    await expectLater(
      bloc.stream,
      emitsInOrder([
        predicate<SubjectsState>((state) => state.status == SubjectsStatus.loading),
        predicate<SubjectsState>((state) => state.status == SubjectsStatus.success && state.subjects.isNotEmpty),
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
    final item = AgendaItem(
      id: 'task_1',
      title: 'Calculus',
      tag: 'Math',
      durationMinutes: 30,
      tagColor: Colors.purple,
      isCompleted: false,
    );
    bloc.emit(bloc.state.copyWith(
      agendaItems: [item],
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
            (state.xpProgress - 0.35).abs() < 0.001 && // float comparison
            state.streak == 13),
      ),
    );
  });
}
