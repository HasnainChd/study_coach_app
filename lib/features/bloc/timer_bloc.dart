import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

// STATE
class TimerState {
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final int sessionNumber;

  TimerState({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRunning,
    required this.sessionNumber,
  });

  TimerState copyWith({
    int? remainingSeconds,
    int? totalSeconds,
    bool? isRunning,
    int? sessionNumber,
  }) {
    return TimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isRunning: isRunning ?? this.isRunning,
      sessionNumber: sessionNumber ?? this.sessionNumber,
    );
  }
}

// EVENTS
abstract class TimerEvent {}

class StartTimerEvent extends TimerEvent {
  final int? durationSeconds;
  StartTimerEvent({this.durationSeconds});
}

class PauseTimerEvent extends TimerEvent {}
class ResetTimerEvent extends TimerEvent {}
class SkipSessionEvent extends TimerEvent {}

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
        )) {
    on<StartTimerEvent>((event, emit) {
      _tickerSubscription?.cancel();

      final nextDuration = event.durationSeconds ?? state.remainingSeconds;
      final nextTotal = event.durationSeconds ?? state.totalSeconds;

      emit(TimerState(
        remainingSeconds: nextDuration,
        totalSeconds: nextTotal,
        isRunning: true,
        sessionNumber: state.sessionNumber,
      ));

      _tickerSubscription = Stream.periodic(const Duration(seconds: 1), (x) => x)
          .take(nextDuration)
          .listen((tick) {
        add(TickEvent(state.remainingSeconds - 1));
      });
    });

    on<TickEvent>((event, emit) {
      if (event.remainingSeconds <= 0) {
        _tickerSubscription?.cancel();
        final nextSession = state.sessionNumber < 4 ? state.sessionNumber + 1 : 1;
        emit(TimerState(
          remainingSeconds: state.totalSeconds,
          totalSeconds: state.totalSeconds,
          isRunning: false,
          sessionNumber: nextSession,
        ));
      } else {
        emit(state.copyWith(remainingSeconds: event.remainingSeconds));
      }
    });

    on<PauseTimerEvent>((event, emit) {
      _tickerSubscription?.cancel();
      emit(state.copyWith(isRunning: false));
    });

    on<ResetTimerEvent>((event, emit) {
      _tickerSubscription?.cancel();
      emit(state.copyWith(
        remainingSeconds: state.totalSeconds,
        isRunning: false,
      ));
    });

    on<SkipSessionEvent>((event, emit) {
      _tickerSubscription?.cancel();
      final nextSession = state.sessionNumber < 4 ? state.sessionNumber + 1 : 1;
      emit(TimerState(
        remainingSeconds: state.totalSeconds,
        totalSeconds: state.totalSeconds,
        isRunning: false,
        sessionNumber: nextSession,
      ));
    });

    on<SetDurationEvent>((event, emit) {
      _tickerSubscription?.cancel();
      emit(TimerState(
        remainingSeconds: event.durationSeconds,
        totalSeconds: event.durationSeconds,
        isRunning: false,
        sessionNumber: state.sessionNumber,
      ));
    });
  }

  @override
  Future<void> close() {
    _tickerSubscription?.cancel();
    return super.close();
  }
}
