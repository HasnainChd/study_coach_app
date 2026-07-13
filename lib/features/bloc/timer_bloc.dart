import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../focus/data/datasources/timer_local_data_source.dart';
import '../focus/data/models/timer_persisted_state_model.dart';

enum TimerStatus {
  idle,
  running,
  paused,
  sessionComplete,
  sessionsEnded,
  onBreak,
}

// STATE — taskId is the navigation anchor; session X/Y is derived in the UI from agenda.
class TimerState {
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final String? taskId;
  final String? taskTitle;
  final String? subjectName;
  final Color? subjectColor;
  final TimerStatus status;
  final bool isBreakComplete;
  final bool isBreakTime;
  final int workDurationSeconds;
  final int? pausedRemainingSeconds;

  TimerState({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRunning,
    this.taskId,
    this.taskTitle,
    this.subjectName,
    this.subjectColor,
    this.status = TimerStatus.idle,
    this.isBreakComplete = false,
    this.isBreakTime = false,
    this.workDurationSeconds = 25 * 60,
    this.pausedRemainingSeconds,
  });

  TimerState copyWith({
    int? remainingSeconds,
    int? totalSeconds,
    bool? isRunning,
    String? taskId,
    String? taskTitle,
    String? subjectName,
    Color? subjectColor,
    TimerStatus? status,
    bool? isBreakComplete,
    bool? isBreakTime,
    int? workDurationSeconds,
    int? pausedRemainingSeconds,
    bool clearPausedRemainingSeconds = false,
    bool clearTaskId = false,
  }) {
    return TimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isRunning: isRunning ?? this.isRunning,
      taskId: clearTaskId ? null : (taskId ?? this.taskId),
      taskTitle: taskTitle ?? this.taskTitle,
      subjectName: subjectName ?? this.subjectName,
      subjectColor: subjectColor ?? this.subjectColor,
      status: status ?? this.status,
      isBreakComplete: isBreakComplete ?? this.isBreakComplete,
      isBreakTime: isBreakTime ?? this.isBreakTime,
      workDurationSeconds: workDurationSeconds ?? this.workDurationSeconds,
      pausedRemainingSeconds: clearPausedRemainingSeconds
          ? null
          : (pausedRemainingSeconds ?? this.pausedRemainingSeconds),
    );
  }
}

// EVENTS
abstract class TimerEvent {}

class StartTimerEvent extends TimerEvent {
  final String? taskId;
  final int? durationSeconds;
  final String? taskTitle;
  final String? subjectName;
  final Color? subjectColor;
  final bool? isRunning;

  StartTimerEvent({
    this.taskId,
    this.durationSeconds,
    this.taskTitle,
    this.subjectName,
    this.subjectColor,
    this.isRunning,
  });
}

class PauseTimerEvent extends TimerEvent {}

class ResetTimerEvent extends TimerEvent {}

class SkipSessionEvent extends TimerEvent {
  final String? taskId;
  final int? durationSeconds;
  final String? taskTitle;
  final String? subjectName;
  final Color? subjectColor;
  final bool? isRunning;

  SkipSessionEvent({
    this.taskId,
    this.durationSeconds,
    this.taskTitle,
    this.subjectName,
    this.subjectColor,
    this.isRunning,
  });
}

class StartBreakEvent extends TimerEvent {
  final bool isLongBreak;
  final int durationSeconds;

  StartBreakEvent({
    this.isLongBreak = false,
    required this.durationSeconds,
  });
}

class SkipBreakEvent extends TimerEvent {
  final String? nextTaskId;
  final int? nextDurationSeconds;
  final String? nextTaskTitle;
  final String? nextSubjectName;
  final Color? nextSubjectColor;

  SkipBreakEvent({
    this.nextTaskId,
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

class SyncTimerEvent extends TimerEvent {}

/// Ends the focus-session flow via skip without marking tasks complete.
class EndSessionsEvent extends TimerEvent {}

class TimerBloc extends Bloc<TimerEvent, TimerState> with WidgetsBindingObserver {
  final TimerLocalDataSource _timerDataSource;

  StreamSubscription<int>? _tickerSubscription;
  DateTime? _targetEndTime;
  int _lastPersistMs = 0;

  static const int _defaultDuration = 25 * 60;
  static const int _persistThrottleMs = 5000;

  TimerBloc({required TimerLocalDataSource timerDataSource})
      : _timerDataSource = timerDataSource,
        super(TimerState(
          remainingSeconds: _defaultDuration,
          totalSeconds: _defaultDuration,
          isRunning: false,
          status: TimerStatus.idle,
          isBreakComplete: false,
          isBreakTime: false,
          workDurationSeconds: _defaultDuration,
        )) {
    WidgetsBinding.instance.addObserver(this);

    on<StartTimerEvent>(_onStartTimer);
    on<TickEvent>(_onTick);
    on<PauseTimerEvent>(_onPauseTimer);
    on<ResetTimerEvent>(_onResetTimer);
    on<SkipSessionEvent>(_onSkipSession);
    on<StartBreakEvent>(_onStartBreak);
    on<SkipBreakEvent>(_onSkipBreak);
    on<SetDurationEvent>(_onSetDuration);
    on<SyncTimerEvent>(_onSyncTimer);
    on<EndSessionsEvent>(_onEndSessions);
  }

  Future<void> _onEndSessions(
    EndSessionsEvent event,
    Emitter<TimerState> emit,
  ) async {
    _tickerSubscription?.cancel();
    _targetEndTime = null;
    await _timerDataSource.clearState();
    emit(state.copyWith(
      isRunning: false,
      status: TimerStatus.sessionsEnded,
      clearPausedRemainingSeconds: true,
    ));
  }

  Future<void> _onStartTimer(
    StartTimerEvent event,
    Emitter<TimerState> emit,
  ) async {
    _tickerSubscription?.cancel();

    final isInPlaceResume =
        event.taskId == null && state.pausedRemainingSeconds != null;

    if (!isInPlaceResume &&
        event.taskId != null &&
        event.durationSeconds != null) {
      final saved = await _timerDataSource.getSavedState();
      if (saved != null) {
        if (saved.taskId == event.taskId) {
          await _restoreFromPersisted(saved, event, emit);
          return;
        }
        await _timerDataSource.clearState();
      }
    }

    final nextDuration = event.durationSeconds ?? state.remainingSeconds;
    final nextTotal = event.durationSeconds ?? state.totalSeconds;
    final nextWorkDuration =
        event.durationSeconds ?? state.workDurationSeconds;
    final nextIsBreakTime =
        event.durationSeconds != null ? false : state.isBreakTime;

    final resolvedShouldRun = event.isRunning ??
        (isInPlaceResume ? true : event.durationSeconds != null);

    final effectiveDuration = isInPlaceResume
        ? state.pausedRemainingSeconds!
        : nextDuration;

    final nextStatus = nextIsBreakTime
        ? TimerStatus.onBreak
        : (resolvedShouldRun ? TimerStatus.running : TimerStatus.paused);

    if (resolvedShouldRun) {
      _targetEndTime =
          DateTime.now().add(Duration(seconds: effectiveDuration));
    } else {
      _targetEndTime = null;
    }

    emit(TimerState(
      remainingSeconds: effectiveDuration,
      totalSeconds: isInPlaceResume ? state.totalSeconds : nextTotal,
      isRunning: resolvedShouldRun,
      taskId: event.taskId ?? state.taskId,
      taskTitle: event.taskTitle ?? state.taskTitle,
      subjectName: event.subjectName ?? state.subjectName,
      subjectColor: event.subjectColor ?? state.subjectColor,
      status: nextStatus,
      isBreakComplete: state.isBreakComplete,
      isBreakTime: nextIsBreakTime,
      workDurationSeconds: nextWorkDuration,
      pausedRemainingSeconds: null,
    ));

    if (resolvedShouldRun) {
      _startTicker(effectiveDuration);
      await _persistCurrentState(isPaused: false, force: true);
    } else if (state.taskId != null) {
      await _persistCurrentState(isPaused: true, force: true);
    }
  }

  Future<void> _restoreFromPersisted(
    TimerPersistedStateModel saved,
    StartTimerEvent event,
    Emitter<TimerState> emit,
  ) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final elapsedSeconds =
        ((nowMs - saved.lastUpdatedTimestampMs) / 1000).floor();

    int remaining;
    bool shouldRun;

    if (saved.isPaused) {
      remaining = saved.remainingSeconds;
      shouldRun = false;
      _targetEndTime = null;
    } else {
      remaining =
          (saved.remainingSeconds - elapsedSeconds).clamp(0, saved.totalSeconds);
      shouldRun = remaining > 0;
      _targetEndTime =
          shouldRun ? DateTime.now().add(Duration(seconds: remaining)) : null;
    }

    if (remaining <= 0 && !saved.isPaused) {
      await _timerDataSource.clearState();
      emit(state.copyWith(
        remainingSeconds: 0,
        isRunning: false,
        status: TimerStatus.sessionComplete,
        clearPausedRemainingSeconds: true,
      ));
      return;
    }

    final subjectColor = saved.subjectColorValue != null
        ? Color(saved.subjectColorValue!)
        : event.subjectColor;

    emit(TimerState(
      remainingSeconds: remaining,
      totalSeconds: saved.totalSeconds,
      isRunning: shouldRun,
      taskId: saved.taskId,
      taskTitle: saved.taskTitle ?? event.taskTitle,
      subjectName: saved.subjectName ?? event.subjectName,
      subjectColor: subjectColor ?? event.subjectColor,
      status: shouldRun ? TimerStatus.running : TimerStatus.paused,
      isBreakComplete: false,
      isBreakTime: false,
      workDurationSeconds: saved.workDurationSeconds,
      pausedRemainingSeconds: shouldRun ? null : remaining,
    ));

    if (shouldRun) {
      _startTicker(remaining);
      await _persistCurrentState(isPaused: false, force: true);
    }
  }

  Future<void> _onTick(TickEvent event, Emitter<TimerState> emit) async {
    if (event.remainingSeconds <= 0) {
      _tickerSubscription?.cancel();
      await _timerDataSource.clearState();

      if (state.status == TimerStatus.onBreak) {
        emit(state.copyWith(
          remainingSeconds: state.workDurationSeconds,
          totalSeconds: state.workDurationSeconds,
          isRunning: false,
          status: TimerStatus.sessionComplete,
          isBreakComplete: true,
          isBreakTime: false,
          clearPausedRemainingSeconds: true,
        ));
      } else {
        emit(state.copyWith(
          remainingSeconds: 0,
          isRunning: false,
          status: TimerStatus.sessionComplete,
          isBreakComplete: false,
          isBreakTime: false,
          clearPausedRemainingSeconds: true,
        ));
      }
    } else {
      emit(state.copyWith(remainingSeconds: event.remainingSeconds));
      await _persistCurrentState(isPaused: false);
    }
  }

  Future<void> _onPauseTimer(
    PauseTimerEvent event,
    Emitter<TimerState> emit,
  ) async {
    _tickerSubscription?.cancel();
    _targetEndTime = null;
    emit(state.copyWith(
      isRunning: false,
      status: TimerStatus.paused,
      pausedRemainingSeconds: state.remainingSeconds,
    ));
    await _persistCurrentState(isPaused: true, force: true);
  }

  Future<void> _onResetTimer(
    ResetTimerEvent event,
    Emitter<TimerState> emit,
  ) async {
    _tickerSubscription?.cancel();
    _targetEndTime = null;
    await _timerDataSource.clearState();
    emit(state.copyWith(
      remainingSeconds: state.workDurationSeconds,
      totalSeconds: state.workDurationSeconds,
      isRunning: false,
      status: TimerStatus.idle,
      isBreakComplete: false,
      isBreakTime: false,
      clearPausedRemainingSeconds: true,
      clearTaskId: true,
    ));
  }

  Future<void> _onSkipSession(
    SkipSessionEvent event,
    Emitter<TimerState> emit,
  ) async {
    _tickerSubscription?.cancel();
    _targetEndTime = null;
    await _timerDataSource.clearState();

    final nextDuration = event.durationSeconds ?? state.workDurationSeconds;
    final shouldRun = event.isRunning ?? false;
    final nextStatus = shouldRun ? TimerStatus.running : TimerStatus.idle;

    if (shouldRun) {
      _targetEndTime = DateTime.now().add(Duration(seconds: nextDuration));
    }

    emit(TimerState(
      remainingSeconds: nextDuration,
      totalSeconds: nextDuration,
      isRunning: shouldRun,
      taskId: event.taskId,
      taskTitle: event.taskTitle ?? state.taskTitle,
      subjectName: event.subjectName ?? state.subjectName,
      subjectColor: event.subjectColor ?? state.subjectColor,
      status: nextStatus,
      isBreakComplete: false,
      isBreakTime: false,
      workDurationSeconds: nextDuration,
      pausedRemainingSeconds: null,
    ));

    if (shouldRun) {
      _startTicker(nextDuration);
      await _persistCurrentState(isPaused: false, force: true);
    }
  }

  Future<void> _onStartBreak(
    StartBreakEvent event,
    Emitter<TimerState> emit,
  ) async {
    _tickerSubscription?.cancel();
    await _timerDataSource.clearState();

    final breakDuration = event.durationSeconds;
    _targetEndTime = DateTime.now().add(Duration(seconds: breakDuration));
    emit(state.copyWith(
      remainingSeconds: breakDuration,
      totalSeconds: breakDuration,
      isRunning: true,
      status: TimerStatus.onBreak,
      isBreakComplete: false,
      isBreakTime: true,
      pausedRemainingSeconds: null,
      clearTaskId: true,
    ));

    _startTicker(breakDuration);
  }

  Future<void> _onSkipBreak(
    SkipBreakEvent event,
    Emitter<TimerState> emit,
  ) async {
    _tickerSubscription?.cancel();
    _targetEndTime = null;

    final nextWorkSeconds =
        event.nextDurationSeconds ?? state.workDurationSeconds;
    emit(TimerState(
      remainingSeconds: nextWorkSeconds,
      totalSeconds: nextWorkSeconds,
      isRunning: false,
      taskId: event.nextTaskId,
      taskTitle: event.nextTaskTitle,
      subjectName: event.nextSubjectName,
      subjectColor: event.nextSubjectColor,
      status: TimerStatus.idle,
      isBreakComplete: false,
      isBreakTime: false,
      workDurationSeconds: nextWorkSeconds,
      pausedRemainingSeconds: null,
    ));
  }

  Future<void> _onSetDuration(
    SetDurationEvent event,
    Emitter<TimerState> emit,
  ) async {
    _tickerSubscription?.cancel();
    _targetEndTime = null;
    await _timerDataSource.clearState();
    emit(TimerState(
      remainingSeconds: event.durationSeconds,
      totalSeconds: event.durationSeconds,
      isRunning: false,
      taskId: state.taskId,
      taskTitle: state.taskTitle,
      subjectName: state.subjectName,
      subjectColor: state.subjectColor,
      status: TimerStatus.idle,
      isBreakComplete: false,
      isBreakTime: false,
      workDurationSeconds: event.durationSeconds,
      pausedRemainingSeconds: null,
    ));
  }

  Future<void> _onSyncTimer(
    SyncTimerEvent event,
    Emitter<TimerState> emit,
  ) async {
    if (state.status == TimerStatus.onBreak ||
        state.status == TimerStatus.sessionComplete ||
        state.status == TimerStatus.sessionsEnded) {
      return;
    }

    if (state.isRunning && _targetEndTime != null) {
      final remainingSeconds =
          _targetEndTime!.difference(DateTime.now()).inSeconds;
      if (remainingSeconds <= 0) {
        _tickerSubscription?.cancel();
        await _timerDataSource.clearState();

        if (state.status == TimerStatus.onBreak) {
          emit(state.copyWith(
            remainingSeconds: state.workDurationSeconds,
            totalSeconds: state.workDurationSeconds,
            isRunning: false,
            status: TimerStatus.sessionComplete,
            isBreakComplete: true,
            isBreakTime: false,
            clearPausedRemainingSeconds: true,
          ));
        } else {
          emit(state.copyWith(
            remainingSeconds: 0,
            isRunning: false,
            status: TimerStatus.sessionComplete,
            isBreakComplete: false,
            isBreakTime: false,
            clearPausedRemainingSeconds: true,
          ));
        }
      } else {
        emit(state.copyWith(remainingSeconds: remainingSeconds));
        _tickerSubscription?.cancel();
        _startTicker(remainingSeconds);
        await _persistCurrentState(isPaused: false, force: true);
      }
      return;
    }

    if (state.status == TimerStatus.paused && state.taskId != null) {
      final saved = await _timerDataSource.getSavedState();
      if (saved != null &&
          saved.taskId == state.taskId &&
          saved.isPaused) {
        emit(state.copyWith(
          remainingSeconds: saved.remainingSeconds,
          pausedRemainingSeconds: saved.remainingSeconds,
        ));
      }
      return;
    }

    if (state.taskId != null &&
        !state.isRunning &&
        state.status == TimerStatus.idle) {
      final saved = await _timerDataSource.getSavedState();
      if (saved != null && saved.taskId == state.taskId && saved.isPaused) {
        final subjectColor = saved.subjectColorValue != null
            ? Color(saved.subjectColorValue!)
            : state.subjectColor;
        emit(state.copyWith(
          remainingSeconds: saved.remainingSeconds,
          totalSeconds: saved.totalSeconds,
          taskTitle: saved.taskTitle ?? state.taskTitle,
          subjectName: saved.subjectName ?? state.subjectName,
          subjectColor: subjectColor,
          status: TimerStatus.paused,
          pausedRemainingSeconds: saved.remainingSeconds,
          workDurationSeconds: saved.workDurationSeconds,
        ));
      }
    }
  }

  void _startTicker(int durationSeconds) {
    _tickerSubscription?.cancel();
    _tickerSubscription =
        Stream.periodic(const Duration(seconds: 1), (x) => x)
            .take(durationSeconds)
            .listen((_) {
      add(TickEvent(state.remainingSeconds - 1));
    });
  }

  Future<void> _persistCurrentState({
    required bool isPaused,
    bool force = false,
  }) async {
    final taskId = state.taskId;
    if (taskId == null ||
        state.isBreakTime ||
        state.status == TimerStatus.sessionComplete) {
      return;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (!force && !isPaused && nowMs - _lastPersistMs < _persistThrottleMs) {
      return;
    }
    _lastPersistMs = nowMs;

    await _timerDataSource.saveState(
      TimerPersistedStateModel(
        taskId: taskId,
        taskTitle: state.taskTitle,
        subjectName: state.subjectName,
        subjectColorValue: state.subjectColor?.value,
        remainingSeconds: state.remainingSeconds,
        totalSeconds: state.totalSeconds,
        isPaused: isPaused,
        lastUpdatedTimestampMs: nowMs,
        workDurationSeconds: state.workDurationSeconds,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      add(SyncTimerEvent());
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _tickerSubscription?.cancel();
    return super.close();
  }
}
