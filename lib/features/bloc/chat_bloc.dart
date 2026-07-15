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

// ─────────────────────────────────────────────────────────────────────────────
// BLOC
// ─────────────────────────────────────────────────────────────────────────────

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final UsageLimitService _usageLimitService;

  /// Snapshot of the SubjectsBloc state at construction time.
  /// The page updates this reference each time SubjectsBloc changes.
  SubjectsState _subjectsState;

  ChatBloc({
    required ChatRepository chatRepository,
    required SubjectsState initialSubjectsState,
    required UsageLimitService usageLimitService,
  })  : _chatRepository = chatRepository,
        _subjectsState = initialSubjectsState,
        _usageLimitService = usageLimitService,
        super(const ChatState(messages: [])) {
    on<LoadChatHistoryEvent>(_onLoadHistory);
    on<SendMessageEvent>(_onSendMessage);
    on<ClearChatEvent>(_onClearChat);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Called by the UI whenever SubjectsBloc emits a new state so the system
  /// prompt always uses the latest real data.
  void updateSubjectsState(SubjectsState state) {
    _subjectsState = state;
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onLoadHistory(
    LoadChatHistoryEvent event,
    Emitter<ChatState> emit,
  ) async {
    final remaining = await _usageLimitService.remainingToday(UsageType.coachMessage);
    final models = await _chatRepository.getMessages();
    if (models.isNotEmpty) {
      final messages = models.map(ChatMessage.fromModel).toList();
      emit(state.copyWith(
        messages: messages,
        clearError: true,
        remainingMessages: remaining,
      ));
    } else {
      // First-ever open — emit a personalised welcome based on real data.
      final welcome = await _buildWelcomeMessage();
      final welcomeMsg = ChatMessage(
        id: _newId(),
        sender: MessageSender.bot,
        text: welcome,
        timestamp: DateTime.now(),
      );
      final initial = [welcomeMsg];
      await _persistMessages(initial);
      emit(state.copyWith(
        messages: initial,
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

    // 1. Append user message immediately.
    final userMsg = ChatMessage(
      id: _newId(),
      sender: MessageSender.user,
      text: text,
      timestamp: DateTime.now(),
    );
    final withUser = List<ChatMessage>.from(state.messages)..add(userMsg);
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

    // Build the messages array: system + entire history.
    final apiMessages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    for (final msg in history) {
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

  Future<String> _buildSystemPrompt() async {
    final name = await _getUserName();
    final s = _subjectsState;

    final subjectsStr = _formatSubjects(s.subjects);
    final agendaStr = _formatAgenda(s.agendaItems);
    final completedCount = s.agendaItems.where((a) => a.isCompleted).length;
    final totalCount = s.agendaItems.length;

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

=== COACHING STYLE ===
- Be warm, motivating, and concise (2–4 sentences unless asked for detail).
- Use the student's name (${name.isEmpty ? 'buddy' : name}) sparingly and naturally (e.g., only in greetings or occasionally for warmth, not in every single response).
- Ground advice in their actual subjects, exam dates, and today's agenda above.
- ONLY mention their exam dates/countdown or streak when it is directly relevant to their query or when they explicitly ask about it. Do NOT repeat or bring up the exam countdown or streak in every response.
- When suggesting study strategies, align with their preferred study time and Pomodoro settings.
- Celebrate streak milestones and XP gains only when relevant to keep motivation high.
- Never make up subjects or tasks — only reference what is listed above.
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
