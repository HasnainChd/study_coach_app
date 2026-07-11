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
    on<UpdateDailyMinutesEvent>(_onUpdateDailyMinutes);
    on<UpdatePreferredTimeEvent>(_onUpdatePreferredTime);
    on<ToggleNotificationsEvent>(_onToggleNotifications);
    on<ToggleAgendaItemEvent>(_onToggleAgendaItem);
    on<UpdateSettingsPreferencesEvent>(_onUpdateSettingsPreferences);
    on<GenerateStudyPlanEvent>(_onGenerateStudyPlan);
    on<ClaimStreakEvent>(_onClaimStreak);
    on<AddXpEvent>(_onAddXp);
    on<SelectAgendaItemEvent>(_onSelectAgendaItem);
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
        progress: 0.10,
      );

      await addSubjectUseCase(subject);

      final updatedSubjects = await getSubjectsUseCase();
      emit(state.copyWith(
        status: SubjectsStatus.success,
        subjects: updatedSubjects,
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
      await removeSubjectUseCase(event.id);
      final updatedSubjects = await getSubjectsUseCase();
      emit(state.copyWith(
        status: SubjectsStatus.success,
        subjects: updatedSubjects,
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

      final updatedAgenda = state.agendaItems.map((item) {
        if (item.id == event.id) {
          final nextCompleted = !item.isCompleted;
          bool nextHasEarnedXp = item.hasEarnedXp;
          if (nextCompleted && !item.hasEarnedXp) {
            shouldAwardXp = true;
            nextHasEarnedXp = true;
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

      if (shouldAwardXp) {
        final totalTasks = state.agendaItems.length;
        final xpPerTask = totalTasks > 0 ? (1.0 / totalTasks) : 0.15;
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
      }

      emit(state.copyWith(
        agendaItems: updatedAgenda,
        xpProgress: currentXp,
        level: currentLevel,
        streak: currentStreak,
        lastStreakClaimedDate: lastClaimed,
      ));

    } catch (_) {}
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
}
