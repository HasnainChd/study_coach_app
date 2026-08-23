import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:study_coach_app/features/bloc/chat_bloc.dart';
import 'package:study_coach_app/features/bloc/timer_bloc.dart';
import 'package:study_coach_app/features/subjects/domain/entities/agenda_item.dart';
import 'package:study_coach_app/features/subjects/presentation/bloc/subjects_state.dart';
import 'package:study_coach_app/features/subjects/domain/entities/settings_preferences.dart';
import 'package:study_coach_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:study_coach_app/features/chat/data/models/chat_message_model.dart';
import 'package:study_coach_app/core/services/usage_limit_service.dart';

class FakeChatRepository implements ChatRepository {
  List<ChatMessageModel> _messages = [];

  @override
  Future<List<ChatMessageModel>> getMessages() async => _messages;

  @override
  Future<void> saveMessages(List<ChatMessageModel> messages) async {
    _messages = List.from(messages);
  }

  @override
  Future<void> clearMessages() async {
    _messages.clear();
  }
}

void main() {
  late ChatBloc chatBloc;
  late FakeChatRepository fakeChatRepo;
  late UsageLimitService usageLimitService;
  late Box testBox;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_chat_timer_test');
    Hive.init(tempDir.path);
    testBox = await Hive.openBox('test_chat_timer');
    fakeChatRepo = FakeChatRepository();
    usageLimitService = UsageLimitService(testBox);
    chatBloc = ChatBloc(
      chatRepository: fakeChatRepo,
      initialSubjectsState: SubjectsState(
        subjects: const [],
        agendaItems: const [],
        settings: SettingsPreferences(),
      ),
      initialTimerState: TimerState(
        remainingSeconds: 1500,
        totalSeconds: 1500,
        isRunning: false,
        status: TimerStatus.idle,
      ),
      usageLimitService: usageLimitService,
    );
  });

  tearDown(() async {
    await chatBloc.close();
    await testBox.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('updateTimerState updates internal timer state', () {
    final activeTimerState = TimerState(
      remainingSeconds: 600,
      totalSeconds: 1500,
      isRunning: true,
      status: TimerStatus.running,
      subjectName: 'Math',
      taskTitle: 'Algebra Homework',
      isBreakTime: false,
    );

    chatBloc.updateTimerState(activeTimerState);

    expect(activeTimerState.isRunning, isTrue);
    expect(activeTimerState.subjectName, equals('Math'));
  });

  test('updateTimerState handles paused status and break time state', () {
    final pausedTimerState = TimerState(
      remainingSeconds: 900,
      totalSeconds: 1500,
      isRunning: false,
      status: TimerStatus.paused,
      pausedRemainingSeconds: 900,
      subjectName: 'Physics',
      taskTitle: 'Lab Report',
      isBreakTime: false,
    );

    chatBloc.updateTimerState(pausedTimerState);
    expect(pausedTimerState.status, equals(TimerStatus.paused));

    final breakTimerState = TimerState(
      remainingSeconds: 180,
      totalSeconds: 300,
      isRunning: true,
      status: TimerStatus.onBreak,
      isBreakTime: true,
    );

    chatBloc.updateTimerState(breakTimerState);
    expect(breakTimerState.isBreakTime, isTrue);
  });

  test('ChatMessage date filtering separates past messages from today', () {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    final oldMsg = ChatMessage(
      id: '1',
      sender: MessageSender.user,
      text: 'Old message from yesterday',
      timestamp: yesterday,
    );
    final todayMsg = ChatMessage(
      id: '2',
      sender: MessageSender.user,
      text: 'Today message',
      timestamp: now,
    );

    final history = [oldMsg, todayMsg];
    final todayFiltered = history.where((msg) {
      final t = msg.timestamp;
      return t.year == now.year && t.month == now.month && t.day == now.day;
    }).toList();

    expect(todayFiltered.length, equals(1));
    expect(todayFiltered.first.text, equals('Today message'));
  });

  test('LoadChatHistoryEvent emits welcome message without persisting it to repository', () async {
    chatBloc.add(LoadChatHistoryEvent());
    await Future.delayed(Duration.zero);

    expect(chatBloc.state.messages.length, equals(1));
    expect(chatBloc.state.messages.first.id, equals('welcome_greeting'));

    final stored = await fakeChatRepo.getMessages();
    expect(stored, isEmpty);
  });

  test('updateSubjectsState recomputes welcome message dynamically when zero real messages exist', () async {
    chatBloc.add(LoadChatHistoryEvent());
    await Future.delayed(Duration.zero);

    expect(chatBloc.state.messages.first.text, contains('All tasks for today are done'));

    // Update subjectsState with pending agenda items
    chatBloc.updateSubjectsState(SubjectsState(
      subjects: const [],
      agendaItems: [
        AgendaItem(
          id: 't1',
          title: 'Math Homework',
          tag: 'Math',
          durationMinutes: 20,
          tagColor: Colors.blue,
        ),
      ],
      settings: SettingsPreferences(),
    ));
    await Future.delayed(Duration.zero);

    expect(chatBloc.state.messages.first.text, contains('You still have 1 task on today\'s agenda'));
    expect(chatBloc.state.messages.first.text, contains('Math Homework'));

    final stored = await fakeChatRepo.getMessages();
    expect(stored, isEmpty);
  });
}
