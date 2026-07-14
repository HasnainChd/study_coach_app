import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_coach_app/features/bloc/timer_bloc.dart';
import 'package:study_coach_app/features/focus/data/models/timer_persisted_state_model.dart';
import 'package:study_coach_app/features/focus/focus_agenda_session.dart';
import 'package:study_coach_app/features/subjects/domain/entities/agenda_item.dart';

import 'fake_timer_local_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('focus_agenda_session helpers', () {
    final items = [
      AgendaItem(
        id: 'task_1',
        title: 'Task 1',
        tag: 'Math',
        durationMinutes: 20,
        tagColor: Colors.red,
      ),
      AgendaItem(
        id: 'task_2',
        title: 'Task 2',
        tag: 'Math',
        durationMinutes: 25,
        tagColor: Colors.red,
      ),
      AgendaItem(
        id: 'task_3',
        title: 'Task 3',
        tag: 'Science',
        durationMinutes: 30,
        tagColor: Colors.blue,
      ),
    ];

    test('agendaSessionNumber returns index + 1 for taskId', () {
      expect(agendaSessionNumber(items, 'task_1'), 1);
      expect(agendaSessionNumber(items, 'task_2'), 2);
      expect(agendaSessionNumber(items, 'task_3'), 3);
    });

    test('agendaNextIncompleteItemForward returns literal next when none complete',
        () {
      expect(agendaNextIncompleteItemForward(items, 'task_1')?.id, 'task_2');
      expect(agendaNextIncompleteItemForward(items, 'task_2')?.id, 'task_3');
      expect(agendaNextIncompleteItemForward(items, 'task_3'), isNull);
    });

    test('isLongBreakForAgendaSession uses position not lifetime counter', () {
      expect(isLongBreakForAgendaSession(4), isTrue);
      expect(isLongBreakForAgendaSession(3), isFalse);
      expect(isLongBreakForAgendaSession(27), isFalse);
    });
  });

  group('TimerBloc', () {
    late FakeTimerLocalDataSource dataSource;
    late TimerBloc timerBloc;

    setUp(() {
      dataSource = FakeTimerLocalDataSource();
      timerBloc = TimerBloc(timerDataSource: dataSource);
    });

    tearDown(() {
      timerBloc.close();
    });

    test('SkipSessionEvent advances taskId without incrementing counters', () async {
      timerBloc.add(SkipSessionEvent(
        taskId: 'task_2',
        durationSeconds: 1500,
        taskTitle: 'Task 2',
        subjectName: 'Math',
        isRunning: true,
      ));
      await Future.delayed(Duration.zero);

      expect(timerBloc.state.taskId, 'task_2');
      expect(timerBloc.state.taskTitle, 'Task 2');
      expect(timerBloc.state.isRunning, true);
    });

    test('StartTimerEvent, PauseTimerEvent, and in-place resume work correctly',
        () async {
      timerBloc.add(StartTimerEvent(
        taskId: 'task_1',
        durationSeconds: 100,
      ));
      await Future.delayed(Duration.zero);
      expect(timerBloc.state.remainingSeconds, 100);
      expect(timerBloc.state.isRunning, true);

      timerBloc.add(PauseTimerEvent());
      await Future.delayed(Duration.zero);
      expect(timerBloc.state.isRunning, false);
      expect(timerBloc.state.pausedRemainingSeconds, 100);
      expect(dataSource.saved?.isPaused, true);

      timerBloc.add(StartTimerEvent());
      await Future.delayed(Duration.zero);
      expect(timerBloc.state.isRunning, true);
      expect(timerBloc.state.pausedRemainingSeconds, isNull);
    });

    test('StartTimerEvent restores paused state from Hive for matching taskId',
        () async {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      dataSource.saved = TimerPersistedStateModel(
        taskId: 'task_1',
        taskTitle: 'Algebra',
        subjectName: 'Math',
        remainingSeconds: 750,
        totalSeconds: 1200,
        isPaused: true,
        lastUpdatedTimestampMs: nowMs,
        workDurationSeconds: 1200,
      );

      timerBloc.add(StartTimerEvent(
        taskId: 'task_1',
        durationSeconds: 1200,
        taskTitle: 'Algebra',
        subjectName: 'Math',
      ));
      await Future.delayed(Duration.zero);

      expect(timerBloc.state.remainingSeconds, 750);
      expect(timerBloc.state.isRunning, false);
      expect(timerBloc.state.status, TimerStatus.paused);
      expect(timerBloc.state.taskId, 'task_1');
    });

    test('StartTimerEvent recalculates running state from Hive timestamp',
        () async {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      dataSource.saved = TimerPersistedStateModel(
        taskId: 'task_1',
        remainingSeconds: 100,
        totalSeconds: 100,
        isPaused: false,
        lastUpdatedTimestampMs: nowMs - 10000,
        workDurationSeconds: 100,
      );

      timerBloc.add(StartTimerEvent(
        taskId: 'task_1',
        durationSeconds: 100,
      ));
      await Future.delayed(Duration.zero);

      expect(timerBloc.state.remainingSeconds, 90);
      expect(timerBloc.state.isRunning, true);
    });

    test('EndSessionsEvent emits sessionsEnded without sessionComplete', () async {
      timerBloc.add(StartTimerEvent(
        taskId: 'task_3',
        durationSeconds: 60,
        taskTitle: 'Task 3',
      ));
      await Future.delayed(Duration.zero);

      timerBloc.add(EndSessionsEvent());
      await Future.delayed(Duration.zero);

      expect(timerBloc.state.status, TimerStatus.sessionsEnded);
      expect(timerBloc.state.status, isNot(TimerStatus.sessionComplete));
      expect(timerBloc.state.isRunning, false);
      expect(dataSource.saved, isNull);
    });

    test('TickEvent(0) on work session emits sessionComplete without counter drift',
        () async {
      timerBloc.add(StartTimerEvent(
        taskId: 'task_3',
        durationSeconds: 60,
        taskTitle: 'Task 3',
      ));
      await Future.delayed(Duration.zero);

      timerBloc.add(TickEvent(0));
      await Future.delayed(Duration.zero);

      expect(timerBloc.state.status, TimerStatus.sessionComplete);
      expect(timerBloc.state.taskId, 'task_3');
      expect(timerBloc.state.isRunning, false);
      expect(dataSource.saved, isNull);
    });

    test('session complete clears persisted state', () async {
      timerBloc.add(StartTimerEvent(
        taskId: 'task_1',
        durationSeconds: 1,
      ));
      await Future.delayed(Duration.zero);
      expect(dataSource.saved, isNotNull);

      await Future.delayed(const Duration(milliseconds: 1100));
      expect(dataSource.saved, isNull);
    });

    test('StartBreakEvent uses durationSeconds from event', () async {
      timerBloc.add(StartBreakEvent(isLongBreak: true, durationSeconds: 20 * 60));
      await Future.delayed(Duration.zero);
      expect(timerBloc.state.status, TimerStatus.onBreak);
      expect(timerBloc.state.remainingSeconds, 20 * 60);

      timerBloc.add(ResetTimerEvent());
      await Future.delayed(Duration.zero);

      timerBloc.add(StartBreakEvent(isLongBreak: false, durationSeconds: 10 * 60));
      await Future.delayed(Duration.zero);
      expect(timerBloc.state.remainingSeconds, 10 * 60);
    });
  });
}
