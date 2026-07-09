import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum TimerStatus { idle, running, paused, sessionComplete, onBreak }

// STATE
class TimerState {
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final int sessionNumber;
  final String? taskTitle;
  final String? subjectName;
  final Color? subjectColor;
  final TimerStatus status;
  final int completedSessions;
  final bool isLongBreak;
  final bool isBreakComplete;
  final bool isBreakTime;
  final int workDurationSeconds;

  TimerState({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRunning,
    required this.sessionNumber,
    this.taskTitle,
    this.subjectName,
    this.subjectColor,
    this.status = TimerStatus.idle,
    this.completedSessions = 0,
    this.isLongBreak = false,
    this.isBreakComplete = false,
    this.isBreakTime = false,
    this.workDurationSeconds = 25 * 60,
  });

  TimerState copyWith({
    int? remainingSeconds,
    int? totalSeconds,
    bool? isRunning,
    int? sessionNumber,
    String? taskTitle,
    String? subjectName,
    Color? subjectColor,
    TimerStatus? status,
    int? completedSessions,
    bool? isLongBreak,
    bool? isBreakComplete,
    bool? isBreakTime,
    int? workDurationSeconds,
  }) {
    return TimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isRunning: isRunning ?? this.isRunning,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      taskTitle: taskTitle ?? this.taskTitle,
      subjectName: subjectName ?? this.subjectName,
      subjectColor: subjectColor ?? this.subjectColor,
      status: status ?? this.status,
      completedSessions: completedSessions ?? this.completedSessions,
      isLongBreak: isLongBreak ?? this.isLongBreak,
      isBreakComplete: isBreakComplete ?? this.isBreakComplete,
      isBreakTime: isBreakTime ?? this.isBreakTime,
      workDurationSeconds: workDurationSeconds ?? this.workDurationSeconds,
    );
  }
}

// EVENTS
abstract class TimerEvent {}

class StartTimerEvent extends TimerEvent {
  final int? durationSeconds;
  final String? taskTitle;
  final String? subjectName;
  final Color? subjectColor;
  StartTimerEvent({
    this.durationSeconds,
    this.taskTitle,
    this.subjectName,
    this.subjectColor,
  });
}

class PauseTimerEvent extends TimerEvent {}

class ResetTimerEvent extends TimerEvent {}

class SkipSessionEvent extends TimerEvent {}

class StartBreakEvent extends TimerEvent {}

class SkipBreakEvent extends TimerEvent {
  final int? nextDurationSeconds;
  final String? nextTaskTitle;
  final String? nextSubjectName;
  final Color? nextSubjectColor;

  SkipBreakEvent({
    this.nextDurationSeconds,
    this.nextTaskTitle,
    this.nextSubjectName,
    this.nextSubjectColor,
  });
}

class SetDurationEvent extends TimerEvent {
  final int durationSeconds;
  SetDurationEvent(this.durationSeconds);
}

class TickEvent extends TimerEvent {
  final int remainingSeconds;
  TickEvent(this.remainingSeconds);
}

// BLOC
class TimerBloc extends Bloc<TimerEvent, TimerState> {
  StreamSubscription<int>? _tickerSubscription;

  static const int _defaultDuration = 25 * 60; // 25 minutes

  TimerBloc()
      : super(TimerState(
          remainingSeconds: _defaultDuration,
          totalSeconds: _defaultDuration,
          isRunning: false,
          sessionNumber: 1,
          status: TimerStatus.idle,
          completedSessions: 0,
          isLongBreak: false,
          isBreakComplete: false,
          isBreakTime: false,
          workDurationSeconds: _defaultDuration,
        )) {
    on<StartTimerEvent>((event, emit) {
      _tickerSubscription?.cancel();

      final nextDuration = event.durationSeconds ?? state.remainingSeconds;
      final nextTotal = event.durationSeconds ?? state.totalSeconds;
      final nextWorkDuration =
          event.durationSeconds ?? state.workDurationSeconds;
      final nextIsBreakTime =
          event.durationSeconds != null ? false : state.isBreakTime;
      final nextStatus =
          nextIsBreakTime ? TimerStatus.onBreak : TimerStatus.running;

      emit(TimerState(
        remainingSeconds: nextDuration,
        totalSeconds: nextTotal,
        isRunning: true,
        sessionNumber: state.sessionNumber,
        taskTitle: event.taskTitle ?? state.taskTitle,
        subjectName: event.subjectName ?? state.subjectName,
        subjectColor: event.subjectColor ?? state.subjectColor,
        status: nextStatus,
        completedSessions: state.completedSessions,
        isLongBreak: state.isLongBreak,
        isBreakComplete: state.isBreakComplete,
        isBreakTime: nextIsBreakTime,
        workDurationSeconds: nextWorkDuration,
      ));

      _tickerSubscription =
          Stream.periodic(const Duration(seconds: 1), (x) => x)
              .take(nextDuration)
              .listen((tick) {
        add(TickEvent(state.remainingSeconds - 1));
      });
    });

    on<TickEvent>((event, emit) {
      if (event.remainingSeconds <= 0) {
        _tickerSubscription?.cancel();

        if (state.status == TimerStatus.onBreak) {
          emit(state.copyWith(
            remainingSeconds: state.workDurationSeconds,
            totalSeconds: state.workDurationSeconds,
            isRunning: false,
            status: TimerStatus.sessionComplete,
            isBreakComplete: true,
            isBreakTime: false,
          ));
        } else {
          final nextCompleted = state.completedSessions + 1;
          final displaySession = ((nextCompleted - 1) % 4) + 1;
          emit(state.copyWith(
            remainingSeconds: 0,
            isRunning: false,
            completedSessions: nextCompleted,
            sessionNumber: displaySession,
            status: TimerStatus.sessionComplete,
            isLongBreak: nextCompleted % 4 == 0,
            isBreakComplete: false,
            isBreakTime: false,
          ));
        }
      } else {
        emit(state.copyWith(remainingSeconds: event.remainingSeconds));
      }
    });

    on<PauseTimerEvent>((event, emit) {
      _tickerSubscription?.cancel();
      emit(state.copyWith(
        isRunning: false,
        status: TimerStatus.paused,
      ));
    });

    on<ResetTimerEvent>((event, emit) {
      _tickerSubscription?.cancel();
      emit(state.copyWith(
        remainingSeconds: state.workDurationSeconds,
        totalSeconds: state.workDurationSeconds,
        isRunning: false,
        status: TimerStatus.idle,
        isBreakComplete: false,
        isBreakTime: false,
      ));
    });

    on<SkipSessionEvent>((event, emit) {
      _tickerSubscription?.cancel();
      final nextCompleted = state.completedSessions + 1;
      final nextSession = ((nextCompleted - 1) % 4) + 1;
      emit(TimerState(
        remainingSeconds: state.workDurationSeconds,
        totalSeconds: state.workDurationSeconds,
        isRunning: false,
        sessionNumber: nextSession,
        taskTitle: state.taskTitle,
        subjectName: state.subjectName,
        subjectColor: state.subjectColor,
        status: TimerStatus.idle,
        completedSessions: nextCompleted,
        isLongBreak: nextCompleted % 4 == 0,
        isBreakComplete: false,
        isBreakTime: false,
        workDurationSeconds: state.workDurationSeconds,
      ));
    });
    on<StartBreakEvent>((event, emit) {
      _tickerSubscription?.cancel();
      final breakDuration = state.isLongBreak ? 15 * 60 : 5 * 60;
      emit(state.copyWith(
        remainingSeconds: breakDuration,
        totalSeconds: breakDuration,
        isRunning: true,
        status: TimerStatus.onBreak,
        isBreakComplete: false,
        isBreakTime: true,
      ));

      _tickerSubscription =
          Stream.periodic(const Duration(seconds: 1), (x) => x)
              .take(breakDuration)
              .listen((tick) {
        add(TickEvent(state.remainingSeconds - 1));
      });
    });

    on<SkipBreakEvent>((event, emit) {
      _tickerSubscription?.cancel();
      final nextWorkSeconds =
          event.nextDurationSeconds ?? state.workDurationSeconds;
      emit(TimerState(
        remainingSeconds: nextWorkSeconds,
        totalSeconds: nextWorkSeconds,
        isRunning: false,
        sessionNumber: state.sessionNumber,
        taskTitle: event.nextTaskTitle,
        subjectName: event.nextSubjectName,
        subjectColor: event.nextSubjectColor,
        status: TimerStatus.idle,
        completedSessions: state.completedSessions,
        isLongBreak: state.isLongBreak,
        isBreakComplete: false,
        isBreakTime: false,
        workDurationSeconds: nextWorkSeconds,
      ));
    });

    on<SetDurationEvent>((event, emit) {
      _tickerSubscription?.cancel();
      emit(TimerState(
        remainingSeconds: event.durationSeconds,
        totalSeconds: event.durationSeconds,
        isRunning: false,
        sessionNumber: state.sessionNumber,
        taskTitle: state.taskTitle,
        subjectName: state.subjectName,
        subjectColor: state.subjectColor,
        status: TimerStatus.idle,
        completedSessions: state.completedSessions,
        isLongBreak: state.isLongBreak,
        isBreakComplete: false,
        isBreakTime: false,
        workDurationSeconds: event.durationSeconds,
      ));
    });
  }

  @override
  Future<void> close() {
    _tickerSubscription?.cancel();
    return super.close();
  }
}
