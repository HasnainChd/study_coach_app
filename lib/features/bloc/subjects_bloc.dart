import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';

class Subject {
  final String id;
  final String name;
  final Color color;
  final DateTime? examDate;
  final double progress; // Progress value (e.g. 0.88 for 88%)

  Subject({
    required this.id,
    required this.name,
    required this.color,
    this.examDate,
    this.progress = 0.50, // Default 50%
  });

  Subject copyWith({
    String? id,
    String? name,
    Color? color,
    DateTime? examDate,
    double? progress,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      examDate: examDate ?? this.examDate,
      progress: progress ?? this.progress,
    );
  }
}

class AgendaItem {
  final String id;
  final String title;
  final String tag;
  final int durationMinutes;
  final Color tagColor;
  final bool isCompleted;

  AgendaItem({
    required this.id,
    required this.title,
    required this.tag,
    required this.durationMinutes,
    required this.tagColor,
    this.isCompleted = false,
  });

  AgendaItem copyWith({
    String? id,
    String? title,
    String? tag,
    int? durationMinutes,
    Color? tagColor,
    bool? isCompleted,
  }) {
    return AgendaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      tagColor: tagColor ?? this.tagColor,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

// POMODORO SETTINGS PREFERENCES
class SettingsPreferences {
  final int pomodoroFocus; // 25, 45, 60
  final int shortBreak;    // 5, 10
  final int longBreak;     // 15, 20
  final bool dailyReminder;
  final bool streakAlerts;
  final bool studyTips;

  SettingsPreferences({
    this.pomodoroFocus = 25,
    this.shortBreak = 5,
    this.longBreak = 15,
    this.dailyReminder = true,
    this.streakAlerts = true,
    this.studyTips = false,
  });

  SettingsPreferences copyWith({
    int? pomodoroFocus,
    int? shortBreak,
    int? longBreak,
    bool? dailyReminder,
    bool? streakAlerts,
    bool? studyTips,
  }) {
    return SettingsPreferences(
      pomodoroFocus: pomodoroFocus ?? this.pomodoroFocus,
      shortBreak: shortBreak ?? this.shortBreak,
      longBreak: longBreak ?? this.longBreak,
      dailyReminder: dailyReminder ?? this.dailyReminder,
      streakAlerts: streakAlerts ?? this.streakAlerts,
      studyTips: studyTips ?? this.studyTips,
    );
  }
}

// STATE
class SubjectsState {
  final List<Subject> subjects;
  final int dailyStudyMinutes;
  final String preferredTime;
  final bool notificationsEnabled;
  final List<AgendaItem> agendaItems;
  final SettingsPreferences settings;

  SubjectsState({
    required this.subjects,
    this.dailyStudyMinutes = 90,
    this.preferredTime = 'Morning',
    this.notificationsEnabled = true,
    required this.agendaItems,
    required this.settings,
  });

  SubjectsState copyWith({
    List<Subject>? subjects,
    int? dailyStudyMinutes,
    String? preferredTime,
    bool? notificationsEnabled,
    List<AgendaItem>? agendaItems,
    SettingsPreferences? settings,
  }) {
    return SubjectsState(
      subjects: subjects ?? this.subjects,
      dailyStudyMinutes: dailyStudyMinutes ?? this.dailyStudyMinutes,
      preferredTime: preferredTime ?? this.preferredTime,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      agendaItems: agendaItems ?? this.agendaItems,
      settings: settings ?? this.settings,
    );
  }
}

// EVENTS
abstract class SubjectsEvent {}

class AddSubjectEvent extends SubjectsEvent {
  final String name;
  final Color color;
  final DateTime? examDate;
  AddSubjectEvent({required this.name, required this.color, this.examDate});
}

class RemoveSubjectEvent extends SubjectsEvent {
  final String id;
  RemoveSubjectEvent(this.id);
}

class UpdateDailyMinutesEvent extends SubjectsEvent {
  final int minutes;
  UpdateDailyMinutesEvent(this.minutes);
}

class UpdatePreferredTimeEvent extends SubjectsEvent {
  final String preferredTime;
  UpdatePreferredTimeEvent(this.preferredTime);
}

class ToggleNotificationsEvent extends SubjectsEvent {
  final bool enabled;
  ToggleNotificationsEvent(this.enabled);
}

class ToggleAgendaItemEvent extends SubjectsEvent {
  final String id;
  ToggleAgendaItemEvent(this.id);
}

class UpdateSettingsPreferencesEvent extends SubjectsEvent {
  final int? pomodoroFocus;
  final int? shortBreak;
  final int? longBreak;
  final bool? dailyReminder;
  final bool? streakAlerts;
  final bool? studyTips;

  UpdateSettingsPreferencesEvent({
    this.pomodoroFocus,
    this.shortBreak,
    this.longBreak,
    this.dailyReminder,
    this.streakAlerts,
    this.studyTips,
  });
}

// BLOC
class SubjectsBloc extends Bloc<SubjectsEvent, SubjectsState> {
  SubjectsBloc()
      : super(SubjectsState(
          subjects: [
            Subject(
              id: '1',
              name: 'Computer Science',
              color: AppColors.subjectGreen,
              examDate: DateTime.now().add(const Duration(days: 45)),
              progress: 0.75,
            ),
            Subject(
              id: '2',
              name: 'Mathematics',
              color: AppColors.subjectPurple,
              examDate: DateTime.now().add(const Duration(days: 30)),
              progress: 0.55,
            ),
            Subject(
              id: '3',
              name: 'Spanish',
              color: AppColors.subjectOrange,
              examDate: DateTime.now().add(const Duration(days: 15)),
              progress: 0.88,
            ),
            Subject(
              id: '4',
              name: 'Physics',
              color: AppColors.subjectPink,
              examDate: DateTime.now().add(const Duration(days: 60)),
              progress: 0.31,
            ),
          ],
          agendaItems: [
            AgendaItem(
              id: 'a1',
              title: 'Data Structures - Binary Trees',
              tag: 'CS',
              durationMinutes: 30,
              tagColor: AppColors.subjectGreen,
              isCompleted: true,
            ),
            AgendaItem(
              id: 'a2',
              title: 'Calculus - Integration by Parts',
              tag: 'Math',
              durationMinutes: 45,
              tagColor: AppColors.subjectPurple,
            ),
            AgendaItem(
              id: 'a3',
              title: 'Spanish Vocabulary Review',
              tag: 'Language',
              durationMinutes: 20,
              tagColor: AppColors.subjectOrange,
            ),
            AgendaItem(
              id: 'a4',
              title: 'Physics - Quantum Mechanics',
              tag: 'Physics',
              durationMinutes: 60,
              tagColor: AppColors.subjectPink,
            ),
          ],
          settings: SettingsPreferences(),
        )) {
    on<AddSubjectEvent>((event, emit) {
      final updatedList = List<Subject>.from(state.subjects)
        ..add(Subject(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: event.name,
          color: event.color,
          examDate: event.examDate,
          progress: 0.10, // Initial progress
        ));
      emit(state.copyWith(subjects: updatedList));
    });

    on<RemoveSubjectEvent>((event, emit) {
      final updatedList = List<Subject>.from(state.subjects)
        ..removeWhere((subj) => subj.id == event.id);
      emit(state.copyWith(subjects: updatedList));
    });

    on<UpdateDailyMinutesEvent>((event, emit) {
      emit(state.copyWith(dailyStudyMinutes: event.minutes));
    });

    on<UpdatePreferredTimeEvent>((event, emit) {
      emit(state.copyWith(preferredTime: event.preferredTime));
    });

    on<ToggleNotificationsEvent>((event, emit) {
      emit(state.copyWith(notificationsEnabled: event.enabled));
    });

    on<ToggleAgendaItemEvent>((event, emit) {
      final updatedAgenda = state.agendaItems.map((item) {
        if (item.id == event.id) {
          return item.copyWith(isCompleted: !item.isCompleted);
        }
        return item;
      }).toList();
      emit(state.copyWith(agendaItems: updatedAgenda));
    });

    on<UpdateSettingsPreferencesEvent>((event, emit) {
      final updatedPrefs = state.settings.copyWith(
        pomodoroFocus: event.pomodoroFocus,
        shortBreak: event.shortBreak,
        longBreak: event.longBreak,
        dailyReminder: event.dailyReminder,
        streakAlerts: event.streakAlerts,
        studyTips: event.studyTips,
      );
      emit(state.copyWith(settings: updatedPrefs));
    });
  }
}
