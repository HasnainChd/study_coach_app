import 'package:flutter_bloc/flutter_bloc.dart';

enum MessageSender { bot, user }

class ChatMessage {
  final String id;
  final MessageSender sender;
  final String text;
  final String? codeSnippet;
  final String? codeLanguage;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    this.codeSnippet,
    this.codeLanguage,
    required this.timestamp,
  });

  ChatMessage copyWith({
    String? id,
    MessageSender? sender,
    String? text,
    String? codeSnippet,
    String? codeLanguage,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      codeSnippet: codeSnippet ?? this.codeSnippet,
      codeLanguage: codeLanguage ?? this.codeLanguage,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

// STATE
class ChatState {
  final List<ChatMessage> messages;

  ChatState({required this.messages});

  ChatState copyWith({List<ChatMessage>? messages}) {
    return ChatState(
      messages: messages ?? this.messages,
    );
  }
}

// EVENTS
abstract class ChatEvent {}

class SendMessageEvent extends ChatEvent {
  final String text;
  SendMessageEvent(this.text);
}

class ReceiveBotReplyEvent extends ChatEvent {
  final String text;
  ReceiveBotReplyEvent(this.text);
}

// BLOC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc()
      : super(ChatState(
          messages: [
            ChatMessage(
              id: '1',
              sender: MessageSender.bot,
              text: 'Welcome back, Alex! Ready to crush today\'s study session?',
              timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
            ),
            ChatMessage(
              id: '2',
              sender: MessageSender.bot,
              text: 'Today\'s Priority Plan:\n• Review CS binary trees\n• Calculus practice problems',
              codeSnippet: 'struct Node {\n  int data;\n  Node* left;\n};',
              codeLanguage: 'cpp',
              timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
            ),
            ChatMessage(
              id: '3',
              sender: MessageSender.user,
              text: 'What should I study if only 30 min?',
              timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
            ),
            ChatMessage(
              id: '4',
              sender: MessageSender.bot,
              text: 'Perfect for a quick session! I\'d recommend Spanish Vocabulary review to maximize short-term memory retention.',
              timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
            ),
          ],
        )) {
    on<SendMessageEvent>((event, emit) {
      if (event.text.trim().isEmpty) return;

      final updatedMessages = List<ChatMessage>.from(state.messages)
        ..add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: MessageSender.user,
          text: event.text,
          timestamp: DateTime.now(),
        ));

      emit(state.copyWith(messages: updatedMessages));

      // Simulate bot typing response
      Future.delayed(const Duration(milliseconds: 1000), () {
        add(ReceiveBotReplyEvent(
            _getSmartBotReply(event.text)));
      });
    });

    on<ReceiveBotReplyEvent>((event, emit) {
      final updatedMessages = List<ChatMessage>.from(state.messages)
        ..add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: MessageSender.bot,
          text: event.text,
          timestamp: DateTime.now(),
        ));

      emit(state.copyWith(messages: updatedMessages));
    });
  }

  String _getSmartBotReply(String userMessage) {
    final lower = userMessage.toLowerCase();
    if (lower.contains('math') || lower.contains('calculus')) {
      return 'For Calculus integration, remember to check substitution methods first before integration by parts!';
    } else if (lower.contains('cs') || lower.contains('computer')) {
      return 'For Binary Trees, focus on tree traversals (In-order, Pre-order, Post-order) as they are the foundation for most recursion problems.';
    } else if (lower.contains('spanish') || lower.contains('language')) {
      return 'Try using active recall and spaced repetition for vocabulary flashcards. Ten minutes a day does wonders!';
    } else if (lower.contains('hello') || lower.contains('hi')) {
      return 'Hello, Alex! Ready to check off some goals today? Let me know how I can guide your study session.';
    } else {
      return 'That sounds like a great topic. Let\'s outline the core terms first, then we can run a quick mock quiz to reinforce it!';
    }
  }
}
