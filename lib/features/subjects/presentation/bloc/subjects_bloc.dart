import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/subject.dart';
import '../../domain/entities/agenda_item.dart';
import '../../domain/entities/settings_preferences.dart';
import '../../domain/repositories/subject_repository.dart';
import '../../domain/usecases/add_subject_usecase.dart';
import '../../domain/usecases/get_subjects_usecase.dart';
import '../../domain/usecases/remove_subject_usecase.dart';
import '../../domain/usecases/generate_study_plan_usecase.dart';
import 'subjects_event.dart';
import 'subjects_state.dart';

const int _dailyStudyMinMinutes = 15;
const int _dailyStudyMaxMinutes = 240;
const int _dailyStudySliderDivisions = 15;

int normalizeDailyStudyMinutes(int minutes) {
  final clamped = minutes.clamp(_dailyStudyMinMinutes, _dailyStudyMaxMinutes);
  final step =
      (_dailyStudyMaxMinutes - _dailyStudyMinMinutes) ~/ _dailyStudySliderDivisions;
  final stepsFromMin = ((clamped - _dailyStudyMinMinutes) / step).round();
  return _dailyStudyMinMinutes + (stepsFromMin * step);
}

class SubjectsBloc extends Bloc<SubjectsEvent, SubjectsState> {
  final SubjectRepository repository;
  final GetSubjectsUseCase getSubjectsUseCase;
  final AddSubjectUseCase addSubjectUseCase;
  final RemoveSubjectUseCase removeSubjectUseCase;
  final GenerateStudyPlanUseCase generateStudyPlanUseCase;

  Subject? _lastDeletedSubject;
  List<AgendaItem>? _lastDeletedAgendaItems;

  SubjectsBloc({
    required this.repository,
    required this.getSubjectsUseCase,
    required this.addSubjectUseCase,
    required this.removeSubjectUseCase,
    required this.generateStudyPlanUseCase,
  }) : super(SubjectsState(
          subjects: const [],
          agendaItems: const [],
          settings: SettingsPreferences(),
          status: SubjectsStatus.initial,
        )) {
    on<LoadSubjectsEvent>(_onLoadSubjects);
    on<AddSubjectEvent>(_onAddSubject);
    on<RemoveSubjectEvent>(_onRemoveSubject);
    on<UndoRemoveSubjectEvent>(_onUndoRemoveSubject);
    on<UpdateDailyMinutesEvent>(_onUpdateDailyMinutes);
    on<UpdatePreferredTimeEvent>(_onUpdatePreferredTime);
    on<ToggleNotificationsEvent>(_onToggleNotifications);
    on<ToggleAgendaItemEvent>(_onToggleAgendaItem);
    on<UpdateSettingsPreferencesEvent>(_onUpdateSettingsPreferences);
    on<GenerateStudyPlanEvent>(_onGenerateStudyPlan);
    on<RegenerateStudyPlanEvent>(_onRegenerateStudyPlan);
    on<ClaimStreakEvent>(_onClaimStreak);
    on<AddXpEvent>(_onAddXp);
    on<SelectAgendaItemEvent>(_onSelectAgendaItem);
    on<UpdateSubjectEvent>(_onUpdateSubject);
  }

  AgendaItem? getNextIncompleteItem(String? currentTaskTitle) {
    for (final item in state.agendaItems) {
      if (!item.isCompleted && item.title != currentTaskTitle) {
        return item;
      }
    }
    return null;
  }

  AgendaItem? get nextIncompleteItem {
    for (final item in state.agendaItems) {
      if (!item.isCompleted) {
        return item;
      }
    }
    return null;
  }

  Future<void> _onLoadSubjects(
    LoadSubjectsEvent event,
    Emitter<SubjectsState> emit,
  ) async {
    emit(state.copyWith(status: SubjectsStatus.loading));
    try {
      var subjects = await getSubjectsUseCase();
      var agenda = await repository.getAgendaItems();
      final calculatedSubjects = _calculateSubjectsWithProgress(subjects, agenda);
      await repository.saveSubjects(calculatedSubjects);
      subjects = calculatedSubjects;
      final dailyMinutes =
          normalizeDailyStudyMinutes(await repository.getDailyStudyMinutes());
      final preferredTime = await repository.getPreferredTime();
      final notifications = await repository.getNotificationsEnabled();
      final settings = await repository.getSettingsPreferences();

      // Load gamification data
      final streak = await repository.getStreak();
      final xpProgress = await repository.getXpProgress();
      final level = await repository.getLevel();
      final lastClaimed = await repository.getLastStreakClaimedDate();



      // Data migration on launch
      bool migrated = false;
      final migratedAgenda = agenda.map((item) {
        if (item.isCompleted && !item.hasEarnedXp) {
          migrated = true;
          return item.copyWith(hasEarnedXp: true);
        }
        return item;
      }).toList();

      if (migrated) {
        agenda = migratedAgenda;
        await repository.saveAgendaItems(agenda);
      }

      // Streak Reset Check on Launch
      int currentStreak = streak;
      bool showResetSnackbar = false;
      if (lastClaimed.isNotEmpty) {
        try {
          final now = DateTime.now();
          final todayDateStr = now.toIso8601String().substring(0, 10);
          final yesterday = now.subtract(const Duration(days: 1));
          final yesterdayDateStr = yesterday.toIso8601String().substring(0, 10);
          
          if (lastClaimed != todayDateStr && lastClaimed != yesterdayDateStr && streak > 0) {
            currentStreak = 0;
            await repository.saveStreak(0);
            showResetSnackbar = true;
          }
        } catch (_) {}
      } else if (streak > 0) {
        currentStreak = 0;
        await repository.saveStreak(0);
        showResetSnackbar = true;
      }

      emit(state.copyWith(
        status: SubjectsStatus.success,
        subjects: subjects,
        agendaItems: agenda,
        dailyStudyMinutes: dailyMinutes,
        preferredTime: preferredTime,
        notificationsEnabled: notifications,
        settings: settings,
        streak: currentStreak,
        xpProgress: xpProgress,
        level: level,
        lastStreakClaimedDate: lastClaimed,
        streakResetTriggered: showResetSnackbar,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SubjectsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAddSubject(
    AddSubjectEvent event,
    Emitter<SubjectsState> emit,
  ) async {
    emit(state.copyWith(status: SubjectsStatus.loading));
    try {
      final subject = Subject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: event.name,
        color: event.color,
        examDate: event.examDate,
        progress: 0.0,
      );

      await addSubjectUseCase(subject);

      final updatedSubjects = await getSubjectsUseCase();
      final calculated = _calculateSubjectsWithProgress(updatedSubjects, state.agendaItems);
      await repository.saveSubjects(calculated);

      emit(state.copyWith(
        status: SubjectsStatus.success,
        subjects: calculated,
      ));
    } catch (e) {
      final msg = e is ArgumentError ? e.message.toString() : e.toString();
      emit(state.copyWith(
        status: SubjectsStatus.failure,
        errorMessage: msg,
      ));
    }
  }

  Future<void> _onRemoveSubject(
    RemoveSubjectEvent event,
    Emitter<SubjectsState> emit,
  ) async {
    emit(state.copyWith(status: SubjectsStatus.loading));
    try {
      Subject? oldSubject;
      try {
        oldSubject = state.subjects.firstWhere((s) => s.id == event.id);
      } catch (_) {}

      if (oldSubject != null) {
        _lastDeletedSubject = oldSubject;
        _lastDeletedAgendaItems = state.agendaItems.where(
          (item) => item.tag.toLowerCase() == oldSubject!.name.toLowerCase()
        ).toList();
      }

      await removeSubjectUseCase(event.id);
      final updatedSubjects = await getSubjectsUseCase();

      var updatedAgenda = state.agendaItems;
      if (oldSubject != null) {
        updatedAgenda = state.agendaItems.where(
          (item) => item.tag.toLowerCase() != oldSubject!.name.toLowerCase()
        ).toList();
        await repository.saveAgendaItems(updatedAgenda);
      }

      final calculated = _calculateSubjectsWithProgress(updatedSubjects, updatedAgenda);
      await repository.saveSubjects(calculated);

      emit(state.copyWith(
        status: SubjectsStatus.success,
        subjects: calculated,
        agendaItems: updatedAgenda,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SubjectsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateDailyMinutes(
    UpdateDailyMinutesEvent event,
    Emitter<SubjectsState> emit,
  ) async {
    try {
      final minutes = normalizeDailyStudyMinutes(event.minutes);
      await repository.saveDailyStudyMinutes(minutes);
      emit(state.copyWith(dailyStudyMinutes: minutes));
    } catch (_) {}
  }

  Future<void> _onUpdatePreferredTime(
    UpdatePreferredTimeEvent event,
    Emitter<SubjectsState> emit,
  ) async {
    try {
      await repository.savePreferredTime(event.preferredTime);
      emit(state.copyWith(preferredTime: event.preferredTime));
    } catch (_) {}
  }

  Future<void> _onToggleNotifications(
    ToggleNotificationsEvent event,
    Emitter<SubjectsState> emit,
  ) async {
    try {
      await repository.saveNotificationsEnabled(event.enabled);
      emit(state.copyWith(notificationsEnabled: event.enabled));
    } catch (_) {}
  }

  Future<void> _onToggleAgendaItem(
    ToggleAgendaItemEvent event,
    Emitter<SubjectsState> emit,
  ) async {
    try {
      bool shouldAwardXp = false;
      bool shouldDeductXp = false;

      final updatedAgenda = state.agendaItems.map((item) {
        if (item.id == event.id) {
          final nextCompleted = !item.isCompleted;
          var nextHasEarnedXp = item.hasEarnedXp;
          if (nextCompleted && !item.hasEarnedXp) {
            shouldAwardXp = true;
            nextHasEarnedXp = true;
          } else if (!nextCompleted && item.hasEarnedXp) {
            shouldDeductXp = true;
            nextHasEarnedXp = false;
          }
          return item.copyWith(
            isCompleted: nextCompleted,
            hasEarnedXp: nextHasEarnedXp,
          );
        }
        return item;
      }).toList();


      await repository.saveAgendaItems(updatedAgenda);

      var currentXp = state.xpProgress;
      var currentLevel = state.level;
      var currentStreak = state.streak;
      var lastClaimed = state.lastStreakClaimedDate;
      final xpPerTask = _xpPerAgendaTask(state.agendaItems.length);

      if (shouldAwardXp) {
        currentXp += xpPerTask;
        if (currentXp >= 0.99) {
          currentLevel += 1;
          currentXp = 0.0;
          await repository.saveLevel(currentLevel);
        }
        await repository.saveXpProgress(currentXp);

        // Auto claim streak on completing study tasks for the day
        final today = DateTime.now().toIso8601String().substring(0, 10);
        if (lastClaimed != today) {
          currentStreak += 1;
          lastClaimed = today;
          await repository.saveStreak(currentStreak);
          await repository.saveLastStreakClaimedDate(today);
        }
      } else if (shouldDeductXp) {
        currentXp -= xpPerTask;
        if (currentXp < 0 && currentLevel > 1) {
          currentLevel -= 1;
          currentXp += 1.0;
        }
        if (currentXp < 0) {
          currentXp = 0.0;
        }
        await repository.saveXpProgress(currentXp);
        if (currentLevel != state.level) {
          await repository.saveLevel(currentLevel);
        }
      }

      final calculatedSubjects = _calculateSubjectsWithProgress(state.subjects, updatedAgenda);
      await repository.saveSubjects(calculatedSubjects);

      emit(state.copyWith(
        agendaItems: updatedAgenda,
        subjects: calculatedSubjects,
        xpProgress: currentXp,
        level: currentLevel,
        streak: currentStreak,
        lastStreakClaimedDate: lastClaimed,
      ));

    } catch (_) {}
  }

  double _xpPerAgendaTask(int totalTasks) {
    return totalTasks > 0 ? (1.0 / totalTasks) : 0.15;
  }

  Future<void> _onUpdateSettingsPreferences(
    UpdateSettingsPreferencesEvent event,
    Emitter<SubjectsState> emit,
  ) async {
    try {
      final updatedPrefs = state.settings.copyWith(
        pomodoroFocus: event.pomodoroFocus,
        shortBreak: event.shortBreak,
        longBreak: event.longBreak,
        dailyReminder: event.dailyReminder,
        streakAlerts: event.streakAlerts,
        studyTips: event.studyTips,
      );
      await repository.saveSettingsPreferences(updatedPrefs);
      emit(state.copyWith(settings: updatedPrefs));
    } catch (_) {}
  }

  Future<void> _onGenerateStudyPlan(
    GenerateStudyPlanEvent event,
    Emitter<SubjectsState> emit,
  ) async {
    emit(state.copyWith(
      status: SubjectsStatus.planGenerating,
      errorMessage: null,
    ));
    try {
      final agendaItems = await generateStudyPlanUseCase(
        dailyMinutes: state.dailyStudyMinutes,
        preferredTime: state.preferredTime,
      );
      await repository.saveAgendaItems(agendaItems);

      // Persist that onboarding is completed
      await repository.saveHasCompletedOnboarding(true);

      // Trigger local study reminder notification (in 15 minutes) if enabled
      if (state.notificationsEnabled) {
        try {
          await NotificationService().scheduleStudyReminder(15);
        } catch (_) {}
      }

      emit(state.copyWith(
        status: SubjectsStatus.planGenerated,
        agendaItems: agendaItems,
        errorMessage: null,
      ));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(
        status: SubjectsStatus.failure,
        errorMessage: message,
      ));
    }
  }

  Future<void> _onRegenerateStudyPlan(
    RegenerateStudyPlanEvent event,
    Emitter<SubjectsState> emit,
  ) async {
    emit(state.copyWith(
      status: SubjectsStatus.planGenerating,
      errorMessage: null,
    ));
    try {
      await repository.saveDailyStudyMinutes(event.dailyMinutes);
      await repository.savePreferredTime(event.preferredTime);

      final agendaItems = await generateStudyPlanUseCase(
        dailyMinutes: event.dailyMinutes,
        preferredTime: event.preferredTime,
      );
      await repository.saveAgendaItems(agendaItems);

      // Trigger local study reminder notification (in 15 minutes) if enabled
      if (state.notificationsEnabled) {
        try {
          await NotificationService().scheduleStudyReminder(15);
        } catch (_) {}
      }

      emit(state.copyWith(
        status: SubjectsStatus.planGenerated,
        dailyStudyMinutes: event.dailyMinutes,
        preferredTime: event.preferredTime,
        agendaItems: agendaItems,
        errorMessage: null,
      ));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(
        status: SubjectsStatus.failure,
        errorMessage: message,
      ));
    }
  }

  Future<void> _onClaimStreak(
    ClaimStreakEvent event,
    Emitter<SubjectsState> emit,
  ) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (state.lastStreakClaimedDate != today) {
      final newStreak = state.streak + 1;
      await repository.saveStreak(newStreak);
      await repository.saveLastStreakClaimedDate(today);
      emit(state.copyWith(
        streak: newStreak,
        lastStreakClaimedDate: today,
      ));
    }
  }

  Future<void> _onAddXp(
    AddXpEvent event,
    Emitter<SubjectsState> emit,
  ) async {
    var newXp = state.xpProgress + event.xpAmount;
    var newLevel = state.level;
    if (newXp >= 1.0) {
      newLevel += 1;
      newXp = newXp % 1.0;
      await repository.saveLevel(newLevel);
    }
    await repository.saveXpProgress(newXp);
    emit(state.copyWith(
      xpProgress: newXp,
      level: newLevel,
    ));
  }

  void _onSelectAgendaItem(
    SelectAgendaItemEvent event,
    Emitter<SubjectsState> emit,
  ) {
    emit(state.copyWith(selectedAgendaItemId: event.id));
  }

  Future<void> _onUndoRemoveSubject(
    UndoRemoveSubjectEvent event,
    Emitter<SubjectsState> emit,
  ) async {
    if (_lastDeletedSubject == null) return;
    emit(state.copyWith(status: SubjectsStatus.loading));
    try {
      await addSubjectUseCase(_lastDeletedSubject!);
      
      var updatedAgenda = state.agendaItems;
      if (_lastDeletedAgendaItems != null && _lastDeletedAgendaItems!.isNotEmpty) {
        final existingIds = state.agendaItems.map((item) => item.id).toSet();
        final itemsToRestore = _lastDeletedAgendaItems!.where((item) => !existingIds.contains(item.id));
        updatedAgenda = [...state.agendaItems, ...itemsToRestore];
        await repository.saveAgendaItems(updatedAgenda);
      }

      final updatedSubjects = await getSubjectsUseCase();
      final calculated = _calculateSubjectsWithProgress(updatedSubjects, updatedAgenda);
      await repository.saveSubjects(calculated);

      _lastDeletedSubject = null;
      _lastDeletedAgendaItems = null;

      emit(state.copyWith(
        status: SubjectsStatus.success,
        subjects: calculated,
        agendaItems: updatedAgenda,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SubjectsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateSubject(
    UpdateSubjectEvent event,
    Emitter<SubjectsState> emit,
  ) async {
    emit(state.copyWith(status: SubjectsStatus.loading));
    try {
      final existingSubjects = await getSubjectsUseCase();
      final index = existingSubjects.indexWhere((s) => s.id == event.id);
      if (index == -1) {
        throw ArgumentError('Subject not found');
      }

      final oldSubject = existingSubjects[index];

      final updatedSubject = oldSubject.copyWith(
        name: event.name,
        color: event.color,
        examDate: event.examDate,
      );

      if (oldSubject.name.toLowerCase() != event.name.toLowerCase()) {
        if (event.name.trim().isEmpty) {
          throw ArgumentError('Subject name cannot be empty');
        }
        if (event.name.length > 40) {
          throw ArgumentError('Subject name cannot exceed 40 characters');
        }
        if (existingSubjects.any((s) => s.name.toLowerCase() == event.name.trim().toLowerCase())) {
          throw ArgumentError('Subject with this name already exists');
        }
      }

      final updatedList = List<Subject>.from(existingSubjects)..[index] = updatedSubject;
      await repository.saveSubjects(updatedList);

      var updatedAgenda = state.agendaItems;
      if (oldSubject.name.toLowerCase() != event.name.toLowerCase()) {
        updatedAgenda = state.agendaItems.map((item) {
          if (item.tag.toLowerCase() == oldSubject.name.toLowerCase()) {
            return item.copyWith(
              tag: event.name,
              tagColor: event.color,
            );
          }
          return item;
        }).toList();
        await repository.saveAgendaItems(updatedAgenda);
      }

      final calculated = _calculateSubjectsWithProgress(updatedList, updatedAgenda);
      await repository.saveSubjects(calculated);

      emit(state.copyWith(
        status: SubjectsStatus.success,
        subjects: calculated,
        agendaItems: updatedAgenda,
      ));
    } catch (e) {
      final msg = e is ArgumentError ? e.message.toString() : e.toString();
      emit(state.copyWith(
        status: SubjectsStatus.failure,
        errorMessage: msg,
      ));
    }
  }

  List<Subject> _calculateSubjectsWithProgress(
    List<Subject> subjects,
    List<AgendaItem> agendaItems,
  ) {
    return subjects.map((subject) {
      final subjectTasks = agendaItems.where(
        (item) => item.tag.toLowerCase() == subject.name.toLowerCase()
      ).toList();

      if (subjectTasks.isEmpty) {
        return subject.copyWith(progress: 0.0);
      }

      final completedCount = subjectTasks.where((item) => item.isCompleted).length;
      return subject.copyWith(progress: completedCount / subjectTasks.length);
    }).toList();
  }
}
