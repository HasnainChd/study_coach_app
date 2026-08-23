import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/api_config.dart';
import '../../core/services/usage_limit_service.dart';
import '../chat/data/models/chat_message_model.dart';

import '../chat/domain/repositories/chat_repository.dart';
import '../subjects/domain/entities/agenda_item.dart';
import '../subjects/domain/entities/subject.dart';
import '../subjects/presentation/bloc/subjects_state.dart';
import 'timer_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Domain types
// ─────────────────────────────────────────────────────────────────────────────

enum MessageSender { bot, user }

class ChatMessage {
  final String id;
  final MessageSender sender;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  ChatMessage copyWith({
    String? id,
    MessageSender? sender,
    String? text,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Convert to/from the persistence model.
  factory ChatMessage.fromModel(ChatMessageModel m) => ChatMessage(
        id: m.id,
        sender: m.sender == 'bot' ? MessageSender.bot : MessageSender.user,
        text: m.text,
        timestamp: m.timestamp,
      );

  ChatMessageModel toModel() => ChatMessageModel(
        id: id,
        sender: sender == MessageSender.bot ? 'bot' : 'user',
        text: text,
        timestamp: timestamp,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────────────────────

class ChatState {
  final List<ChatMessage> messages;

  /// True while waiting for the Cerebras API reply.
  final bool isTyping;

  /// Non-null when the last API call failed.
  final String? error;

  final bool limitReached;
  final int remainingMessages;

  const ChatState({
    required this.messages,
    this.isTyping = false,
    this.error,
    this.limitReached = false,
    this.remainingMessages = 18,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    String? error,
    bool clearError = false,
    bool? limitReached,
    int? remainingMessages,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      error: clearError ? null : (error ?? this.error),
      limitReached: limitReached ?? this.limitReached,
      remainingMessages: remainingMessages ?? this.remainingMessages,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EVENTS
// ─────────────────────────────────────────────────────────────────────────────

abstract class ChatEvent {}

/// Fired once when the chat page opens — restores Hive history.
class LoadChatHistoryEvent extends ChatEvent {}

/// The user pressed Send.
class SendMessageEvent extends ChatEvent {
  final String text;
  SendMessageEvent(this.text);
}

/// Clear all chat history.
class ClearChatEvent extends ChatEvent {}

/// Refresh the dynamic UI-only welcome message.
class RefreshWelcomeMessageEvent extends ChatEvent {}

// ─────────────────────────────────────────────────────────────────────────────
// BLOC
// ─────────────────────────────────────────────────────────────────────────────

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final UsageLimitService _usageLimitService;

  /// Snapshot of the SubjectsBloc state at construction time.
  /// The page updates this reference each time SubjectsBloc changes.
  SubjectsState _subjectsState;

  /// Snapshot of the TimerBloc state.
  TimerState? _timerState;

  ChatBloc({
    required ChatRepository chatRepository,
    required SubjectsState initialSubjectsState,
    TimerState? initialTimerState,
    required UsageLimitService usageLimitService,
  })  : _chatRepository = chatRepository,
        _subjectsState = initialSubjectsState,
        _timerState = initialTimerState,
        _usageLimitService = usageLimitService,
        super(const ChatState(messages: [])) {
    on<LoadChatHistoryEvent>(_onLoadHistory);
    on<SendMessageEvent>(_onSendMessage);
    on<ClearChatEvent>(_onClearChat);
    on<RefreshWelcomeMessageEvent>(_onRefreshWelcomeMessage);
  }

  static const welcomeMessageId = 'welcome_greeting';

  static bool _isWelcomeMessage(ChatMessage msg) {
    return msg.id == welcomeMessageId ||
        (msg.sender == MessageSender.bot &&
            (msg.text.contains('Scholar.') ||
                msg.text.contains('I\'m your AI coach')));
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Called by the UI whenever SubjectsBloc emits a new state so the system
  /// prompt always uses the latest real data.
  void updateSubjectsState(SubjectsState state) {
    _subjectsState = state;
    final msgs = this.state.messages;
    if (msgs.isEmpty || (msgs.length == 1 && _isWelcomeMessage(msgs.first))) {
      add(RefreshWelcomeMessageEvent());
    }
  }

  Future<void> _onRefreshWelcomeMessage(
    RefreshWelcomeMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final welcome = await _buildWelcomeMessage();
    final welcomeMsg = ChatMessage(
      id: welcomeMessageId,
      sender: MessageSender.bot,
      text: welcome,
      timestamp: DateTime.now(),
    );
    emit(state.copyWith(messages: [welcomeMsg]));
  }

  /// Called by the UI whenever TimerBloc emits a new state.
  void updateTimerState(TimerState state) {
    _timerState = state;
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onLoadHistory(
    LoadChatHistoryEvent event,
    Emitter<ChatState> emit,
  ) async {
    final remaining = await _usageLimitService.remainingToday(UsageType.coachMessage);
    var models = await _chatRepository.getMessages();

    // Migration check: if sole persisted message is a stale welcome greeting, clear it
    if (models.length == 1) {
      final firstMsg = ChatMessage.fromModel(models.first);
      if (_isWelcomeMessage(firstMsg)) {
        await _chatRepository.clearMessages();
        models = [];
      }
    }

    if (models.isNotEmpty) {
      final messages = models.map(ChatMessage.fromModel).toList();
      emit(state.copyWith(
        messages: messages,
        clearError: true,
        remainingMessages: remaining,
      ));
    } else {
      // First-ever open (or zero persisted real messages) — emit UI-only welcome message
      final welcome = await _buildWelcomeMessage();
      final welcomeMsg = ChatMessage(
        id: welcomeMessageId,
        sender: MessageSender.bot,
        text: welcome,
        timestamp: DateTime.now(),
      );
      // DO NOT persist welcomeMsg to Hive
      emit(state.copyWith(
        messages: [welcomeMsg],
        clearError: true,
        remainingMessages: remaining,
      ));
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty) return;

    final canPerform = await _usageLimitService.canPerformAction(UsageType.coachMessage);
    if (!canPerform) {
      emit(state.copyWith(limitReached: true));
      emit(state.copyWith(limitReached: false));
      return;
    }

    // 1. Filter out UI-only welcome greeting before sending/persisting real messages.
    final existingReal = state.messages.where((m) => !_isWelcomeMessage(m)).toList();

    final userMsg = ChatMessage(
      id: _newId(),
      sender: MessageSender.user,
      text: text,
      timestamp: DateTime.now(),
    );
    final withUser = List<ChatMessage>.from(existingReal)..add(userMsg);
    await _persistMessages(withUser);
    emit(state.copyWith(messages: withUser, isTyping: true, clearError: true));

    // 2. Call Cerebras API.
    try {
      final reply = await _callCerebrasApi(withUser);
      final botMsg = ChatMessage(
        id: _newId(),
        sender: MessageSender.bot,
        text: reply,
        timestamp: DateTime.now(),
      );
      final withBot = List<ChatMessage>.from(withUser)..add(botMsg);
      await _persistMessages(withBot);

      await _usageLimitService.recordAction(UsageType.coachMessage);
      final remaining = await _usageLimitService.remainingToday(UsageType.coachMessage);

      emit(state.copyWith(
        messages: withBot,
        isTyping: false,
        remainingMessages: remaining,
      ));
    } catch (e, st) {
      // Print real error to console for debugging.
      // ignore: avoid_print
      print('[ChatBloc] Cerebras API error: $e');
      // ignore: avoid_print
      print('[ChatBloc] Stack: $st');
      final errMsg = ChatMessage(
        id: _newId(),
        sender: MessageSender.bot,
        text:
            "Sorry, I couldn't reach the server right now. Please try again in a moment.",
        timestamp: DateTime.now(),
      );
      final withErr = List<ChatMessage>.from(withUser)..add(errMsg);
      await _persistMessages(withErr);

      final remaining = await _usageLimitService.remainingToday(UsageType.coachMessage);

      emit(state.copyWith(
        messages: withErr,
        isTyping: false,
        error: e.toString(),
        remainingMessages: remaining,
      ));
    }
  }

  Future<void> _onClearChat(
    ClearChatEvent event,
    Emitter<ChatState> emit,
  ) async {
    await _chatRepository.clearMessages();
    final remaining = await _usageLimitService.remainingToday(UsageType.coachMessage);
    emit(ChatState(messages: const [], remainingMessages: remaining));
    // Immediately reload to show a fresh welcome.
    add(LoadChatHistoryEvent());
  }

  // ── Cerebras API ──────────────────────────────────────────────────────────

  Future<String> _callCerebrasApi(List<ChatMessage> history) async {
    final systemPrompt = await _buildSystemPrompt();

    // Build the messages array: system + today's history only.
    final apiMessages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    final now = DateTime.now();
    final todayMessages = history.where((msg) {
      final t = msg.timestamp;
      return t.year == now.year && t.month == now.month && t.day == now.day;
    }).toList();

    for (final msg in todayMessages) {
      apiMessages.add({
        'role': msg.sender == MessageSender.user ? 'user' : 'assistant',
        'content': msg.text,
      });
    }

    final uri = Uri.parse('${ApiConfig.cerebrasBaseUrl}/chat/completions');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${ApiConfig.cerebrasApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': ApiConfig.cerebrasModel,
        'messages': apiMessages,
        'max_tokens': 512,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Cerebras API error ${response.statusCode}: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Cerebras returned no choices.');
    }

    final content =
        (choices[0] as Map<String, dynamic>)['message']?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw Exception('Cerebras returned empty content.');
    }

    return content.trim();
  }

  // ── Prompt builders ───────────────────────────────────────────────────────

  String _formatTimerContext() {
    final t = _timerState;
    if (t == null || t.status == TimerStatus.idle || t.status == TimerStatus.sessionsEnded) {
      return '(No active timer session currently running)';
    }

    final isPaused = t.status == TimerStatus.paused;
    final remainingSecs = isPaused && t.pausedRemainingSeconds != null
        ? t.pausedRemainingSeconds!
        : t.remainingSeconds;

    final totalSecs = t.totalSeconds > 0 ? t.totalSeconds : 1500;
    final elapsedSecs = (totalSecs - remainingSecs).clamp(0, totalSecs);
    final elapsedMins = (elapsedSecs / 60).floor();
    final totalMins = (totalSecs / 60).round();

    final sessionType = t.isBreakTime ? 'active break' : 'Pomodoro focus session';
    final statusStr = isPaused ? 'paused' : 'active';
    final subjectInfo = t.subjectName != null && t.subjectName!.trim().isNotEmpty
        ? ' for ${t.subjectName}'
        : '';
    final taskInfo = t.taskTitle != null && t.taskTitle!.trim().isNotEmpty
        ? ' ("${t.taskTitle}")'
        : '';

    return 'Currently in a $statusStr $sessionType$subjectInfo$taskInfo, $elapsedMins minutes elapsed of $totalMins minute block.';
  }

  Future<String> _buildSystemPrompt() async {
    final name = await _getUserName();
    final s = _subjectsState;

    final subjectsStr = _formatSubjects(s.subjects);
    final agendaStr = _formatAgenda(s.agendaItems);
    final completedCount = s.agendaItems.where((a) => a.isCompleted).length;
    final totalCount = s.agendaItems.length;
    final timerStr = _formatTimerContext();

    return '''
You are a warm, encouraging personal AI Study Coach inside a student study app.

=== STUDENT PROFILE ===
Name: ${name.isEmpty ? 'there' : name}
Level: ${s.level} Scholar
Streak: ${s.streak} day${s.streak == 1 ? '' : 's'}
XP Progress: ${(s.xpProgress * 100).toStringAsFixed(0)}% toward Level ${s.level + 1}

=== SUBJECTS & EXAM DATES ===
$subjectsStr

=== TODAY'S AGENDA ($completedCount/$totalCount completed) ===
$agendaStr

=== SCHEDULE SETTINGS ===
Daily Study Goal: ${s.dailyStudyMinutes} minutes
Preferred Study Time: ${s.preferredTime}
Pomodoro Focus: ${s.settings.pomodoroFocus} min | Short Break: ${s.settings.shortBreak} min | Long Break: ${s.settings.longBreak} min

=== ACTIVE TIMER SESSION ===
$timerStr

=== COACHING STYLE & SESSION STRUCTURE ===
- Be warm, motivating, and concise (2–4 sentences unless asked for detail).
- Use the student's name (${name.isEmpty ? 'buddy' : name}) sparingly and naturally (e.g., only in greetings or occasionally for warmth, not in every single response).
- Ground advice in their actual subjects, exam dates, and today's agenda above.
- ONLY mention their exam dates/countdown or streak when it is directly relevant to their query or when they explicitly ask about it. Do NOT repeat or bring up the exam countdown or streak in every response.
- When suggesting study strategies, align with their preferred study time and Pomodoro settings.
- Celebrate streak milestones and XP gains only when relevant to keep motivation high.
- Never make up subjects or tasks — only reference what is listed above.
- STRUCTURE STUDY TOPICS: Structure any study session/topic into three distinct phases in order:
  1. Concept Explanation
  2. Practice (ask at least 2 practice questions sequentially to the student)
  3. Recap
- PHASE PROGRESSION: Do NOT advance to a new topic or phase until the current phase is actually complete. For Practice specifically, a phase is NOT complete just because you say "let's move on" — at least one practice question must have been asked AND the student must have responded to it before moving to recap or a new topic.
- NO ELAPSED TIME HALLUCINATION: Do NOT state or imply elapsed session time (e.g., "you're 20 minutes into your session") unless exact timer data is explicitly provided in ACTIVE TIMER SESSION above. If no active timer session is running (or it says "(No active timer session currently running)"), do NOT mention or reference elapsed session time at all.
- SKIPPING/EARLY END: If the student asks to skip ahead or end early, comply politely, but do not later claim that a skipped phase was completed.
''';
  }

  Future<String> _buildWelcomeMessage() async {
    final name = await _getUserName();
    final s = _subjectsState;

    final greeting = name.isNotEmpty ? 'Hey $name! 👋' : 'Hey there! 👋';
    final streakLine =
        s.streak > 0 ? 'You\'re on a 🔥 ${s.streak}-day streak' : 'Ready to start a new streak';
    final pendingItems = s.agendaItems.where((a) => !a.isCompleted).toList();
    final agendaLine = pendingItems.isEmpty
        ? 'All tasks for today are done — amazing work!'
        : 'You still have ${pendingItems.length} task${pendingItems.length == 1 ? '' : 's'} on today\'s agenda.';

    final firstTask =
        pendingItems.isNotEmpty ? pendingItems.first.title : null;
    final nudge = firstTask != null
        ? ' Ready to tackle **$firstTask**?'
        : '';

    return '$greeting $streakLine — Level ${s.level} Scholar. $agendaLine$nudge\n\nI\'m your AI coach. Ask me anything — study strategies, topic explanations, motivation, or a quiz! 🎓';
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<String> _getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getString('userName') ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  String _formatSubjects(List<Subject> subjects) {
    if (subjects.isEmpty) return '  (No subjects added yet)';
    final now = DateTime.now();
    return subjects.map((s) {
      if (s.examDate == null) return '  • ${s.name} (No exam scheduled)';
      final days = s.examDate!.difference(now).inDays;
      final label = days <= 0
          ? 'Exam today!'
          : 'Exam in $days day${days == 1 ? '' : 's'}';
      return '  • ${s.name} — $label';
    }).join('\n');
  }

  String _formatAgenda(List<AgendaItem> items) {
    if (items.isEmpty) return '  (No tasks scheduled for today)';
    return items.map((a) {
      final check = a.isCompleted ? '✓' : '○';
      return '  $check ${a.title} (${a.tag}, ${a.durationMinutes} min)';
    }).join('\n');
  }

  Future<void> _persistMessages(List<ChatMessage> messages) async {
    await _chatRepository.saveMessages(messages.map((m) => m.toModel()).toList());
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
