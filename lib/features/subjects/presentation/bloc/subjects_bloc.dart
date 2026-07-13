import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../analytics/domain/entities/study_history_entry.dart';
import '../../../analytics/domain/repositories/study_history_repository.dart';
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
  final StudyHistoryRepository studyHistoryRepository;

  Subject? _lastDeletedSubject;
  List<AgendaItem>? _lastDeletedAgendaItems;

  SubjectsBloc({
    required this.repository,
    required this.getSubjectsUseCase,
    required this.addSubjectUseCase,
    required this.removeSubjectUseCase,
    required this.generateStudyPlanUseCase,
    required this.studyHistoryRepository,
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
    on<ClearNotificationPermissionWarningEvent>(
      _onClearNotificationPermissionWarning,
    );
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
      await _syncScheduledNotifications();
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
      await _syncScheduledNotifications();
    } catch (_) {}
  }

  Future<void> _onToggleNotifications(
    ToggleNotificationsEvent event,
    Emitter<SubjectsState> emit,
  ) async {
    try {
      if (event.enabled) {
        debugPrint(
          '[SubjectsBloc] Master notifications toggle ON — checking permission',
        );
        final granted =
            await NotificationService().requestPermissionsIfNeeded();
        if (!granted) {
          debugPrint(
            '[SubjectsBloc] Master notifications permission denied — '
            'keeping toggle OFF',
          );
          emit(state.copyWith(showNotificationPermissionWarning: true));
          return;
        }
        await repository.saveNotificationsEnabled(true);
        emit(state.copyWith(notificationsEnabled: true));
        await _syncScheduledNotifications();
        return;
      }

      await repository.saveNotificationsEnabled(false);
      emit(state.copyWith(notificationsEnabled: false));
      await NotificationService().cancelAllNotifications();
    } catch (e, stackTrace) {
      debugPrint(
        '[SubjectsBloc] _onToggleNotifications failed: $e\n$stackTrace',
      );
    }
  }

  void _onClearNotificationPermissionWarning(
    ClearNotificationPermissionWarningEvent event,
    Emitter<SubjectsState> emit,
  ) {
    emit(state.copyWith(showNotificationPermissionWarning: false));
  }

  int _incompleteTaskCount() {
    return state.agendaItems.where((item) => !item.isCompleted).length;
  }

  bool _streakClaimedToday() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return state.lastStreakClaimedDate == today;
  }

  Future<void> _syncScheduledNotifications() async {
    final notificationService = NotificationService();

    if (!state.notificationsEnabled) {
      await notificationService.cancelAllNotifications();
      return;
    }

    if (!await notificationService.hasPermission()) {
      return;
    }

    final prefs = state.settings;

    if (prefs.dailyReminder) {
      await notificationService.scheduleDailyReminder(
        preferredTime: state.preferredTime,
        incompleteTaskCount: _incompleteTaskCount(),
      );
    } else {
      await notificationService.cancelNotification(
        NotificationIds.dailyReminder,
      );
    }

    if (prefs.streakAlerts && !_streakClaimedToday()) {
      await notificationService.scheduleStreakAlert();
    } else {
      await notificationService.cancelNotification(NotificationIds.streakAlert);
    }

    if (prefs.studyTips) {
      await notificationService.scheduleStudyTip();
    } else {
      await notificationService.cancelNotification(NotificationIds.studyTip);
    }
  }

  Future<bool> _schedulePostPlanReminder(Emitter<SubjectsState> emit) async {
    final scheduled = await NotificationService().scheduleStudyReminder(15);
    if (!scheduled) {
      emit(state.copyWith(showNotificationPermissionWarning: true));
    }
    return scheduled;
  }

  Future<void> _onToggleAgendaItem(
    ToggleAgendaItemEvent event,
    Emitter<SubjectsState> emit,
  ) async {
    try {
      bool shouldAwardXp = false;
      bool shouldDeductXp = false;
      AgendaItem? toggledItem;

      final updatedAgenda = state.agendaItems.map((item) {
        if (item.id == event.id) {
          toggledItem = item;
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

        final item = toggledItem;
        if (item != null) {
          final today = DateTime.now().toIso8601String().substring(0, 10);
          await studyHistoryRepository.addEntry(
            StudyHistoryEntry(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              agendaItemId: item.id,
              date: today,
              subjectName: item.tag,
              subjectId: _resolveSubjectId(state.subjects, item.tag),
              durationMinutes: item.durationMinutes,
              xpAwarded: xpPerTask,
            ),
          );
        }

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
        await studyHistoryRepository.removeByAgendaItemId(event.id);
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

      if (shouldAwardXp && lastClaimed == DateTime.now().toIso8601String().substring(0, 10)) {
        await NotificationService().cancelNotification(NotificationIds.streakAlert);
      }

    } catch (_) {}
  }

  double _xpPerAgendaTask(int totalTasks) {
    return totalTasks > 0 ? (1.0 / totalTasks) : 0.15;
  }

  String? _resolveSubjectId(List<Subject> subjects, String subjectName) {
    for (final subject in subjects) {
      if (subject.name.toLowerCase().trim() ==
          subjectName.toLowerCase().trim()) {
        return subject.id;
      }
    }
    return null;
  }

  Future<void> _onUpdateSettingsPreferences(
    UpdateSettingsPreferencesEvent event,
    Emitter<SubjectsState> emit,
  ) async {
    try {
      final enablingDaily =
          event.dailyReminder == true && !state.settings.dailyReminder;
      final enablingStreak =
          event.streakAlerts == true && !state.settings.streakAlerts;
      final enablingTips =
          event.studyTips == true && !state.settings.studyTips;

      if (enablingDaily || enablingStreak || enablingTips) {
        debugPrint(
          '[SubjectsBloc] Sub-toggle enable — checking notification permission '
          '(master=${state.notificationsEnabled})',
        );
        final granted =
            await NotificationService().requestPermissionsIfNeeded();
        if (!granted) {
          debugPrint(
            '[SubjectsBloc] Sub-toggle permission denied — reverting toggle',
          );
          final revertedPrefs = state.settings.copyWith(
            dailyReminder: enablingDaily ? false : event.dailyReminder,
            streakAlerts: enablingStreak ? false : event.streakAlerts,
            studyTips: enablingTips ? false : event.studyTips,
            pomodoroFocus: event.pomodoroFocus,
            shortBreak: event.shortBreak,
            longBreak: event.longBreak,
          );
          await repository.saveSettingsPreferences(revertedPrefs);
          emit(state.copyWith(
            settings: revertedPrefs,
            showNotificationPermissionWarning: true,
          ));
          return;
        }
      }

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
      await _syncScheduledNotifications();
    } catch (e, stackTrace) {
      debugPrint(
        '[SubjectsBloc] _onUpdateSettingsPreferences failed: $e\n$stackTrace',
      );
    }
  }

  Future<void> _onGenerateStudyPlan(
    GenerateStudyPlanEvent event,
    Emitter<SubjectsState> emit,
  ) async {
    emit(state.copyWith(
      status: SubjectsStatus.planGenerating,
      errorMessage: null,
      clearPlanBudgetWarning: true,
    ));
    try {
      final result = await generateStudyPlanUseCase(
        dailyMinutes: state.dailyStudyMinutes,
        preferredTime: state.preferredTime,
      );
      await repository.saveAgendaItems(result.agendaItems);

      // Persist that onboarding is completed
      await repository.saveHasCompletedOnboarding(true);

      // Trigger local study reminder notification (in 15 minutes) if enabled
      if (state.notificationsEnabled) {
        try {
          await _schedulePostPlanReminder(emit);
        } catch (e, stackTrace) {
          debugPrint(
            '[SubjectsBloc] Post-plan reminder scheduling failed: $e\n$stackTrace',
          );
        }
      }

      emit(state.copyWith(
        status: SubjectsStatus.planGenerated,
        agendaItems: result.agendaItems,
        planBudgetWarningMessage: result.budgetWarningMessage,
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
      clearPlanBudgetWarning: true,
    ));
    try {
      await repository.saveDailyStudyMinutes(event.dailyMinutes);
      await repository.savePreferredTime(event.preferredTime);

      final result = await generateStudyPlanUseCase(
        dailyMinutes: event.dailyMinutes,
        preferredTime: event.preferredTime,
      );
      await repository.saveAgendaItems(result.agendaItems);

      // Trigger local study reminder notification (in 15 minutes) if enabled
      if (state.notificationsEnabled) {
        try {
          await _schedulePostPlanReminder(emit);
        } catch (e, stackTrace) {
          debugPrint(
            '[SubjectsBloc] Post-plan reminder scheduling failed: $e\n$stackTrace',
          );
        }
      }

      emit(state.copyWith(
        status: SubjectsStatus.planGenerated,
        dailyStudyMinutes: event.dailyMinutes,
        preferredTime: event.preferredTime,
        agendaItems: result.agendaItems,
        planBudgetWarningMessage: result.budgetWarningMessage,
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
