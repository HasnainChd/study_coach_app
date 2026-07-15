import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/services/usage_limit_service.dart';
import '../../../bloc/chat_bloc.dart';
import '../../../bloc/subjects_bloc.dart';

class CoachChatPage extends StatefulWidget {
  const CoachChatPage({super.key});

  @override
  State<CoachChatPage> createState() => _CoachChatPageState();
}

class _CoachChatPageState extends State<CoachChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<SubjectsState>? _subjectsSubscription;

  @override
  void initState() {
    super.initState();

    final subjectsBloc = context.read<SubjectsBloc>();
    final chatBloc = context.read<ChatBloc>();

    // Sync initial state into ChatBloc.
    chatBloc.updateSubjectsState(subjectsBloc.state);

    // Keep ChatBloc informed of future SubjectsBloc changes.
    _subjectsSubscription = subjectsBloc.stream.listen((subjectsState) {
      chatBloc.updateSubjectsState(subjectsState);
    });

    // Restore persisted messages (or emit welcome message on first run).
    chatBloc.add(LoadChatHistoryEvent());
  }

  @override
  void dispose() {
    _subjectsSubscription?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    context.read<ChatBloc>().add(SendMessageEvent(text));
    _textController.clear();
    _scrollToBottom();
  }

  void _showClearDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reset Conversation?',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'This will clear all past chat history with your AI Study Coach. This action cannot be undone.',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        context.read<ChatBloc>().add(ClearChatEvent());
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.only(left: 8, right: 4, top: 4, bottom: 4),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: BlocBuilder<ChatBloc, ChatState>(
                      builder: (context, chatState) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'AI Coach',
                              style: AppTextStyles.headingSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              chatState.isTyping
                                  ? 'typing...'
                                  : '${chatState.remainingMessages}/${UsageType.coachMessage.limit} messages today',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: chatState.isTyping
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.darkTextSecondary.withValues(alpha: 0.7)
                                        : AppColors.lightTextSecondary.withValues(alpha: 0.7)),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    onSelected: (value) {
                      if (value == 'reset') {
                        _showClearDialog();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'reset',
                        child: Text(
                          'Reset Conversation',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Messages list ────────────────────────────────────────────────
            Expanded(
              child: BlocConsumer<ChatBloc, ChatState>(
                listener: (context, chatState) {
                  _scrollToBottom();
                  if (chatState.limitReached) {
                    AppSnackbar.show(
                      context,
                      type: SnackbarType.info,
                      title: "Daily limit reached",
                      message: "You've reached today's message limit. Let's continue tomorrow! 👋",
                    );
                  }
                },
                builder: (context, chatState) {
                  // Build display list: real messages + optional typing sentinel.
                  final messages = chatState.messages;
                  final showTyping = chatState.isTyping;
                  final itemCount =
                      messages.length + (showTyping ? 1 : 0);

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      // Last item is the typing bubble when isTyping == true.
                      if (showTyping && index == itemCount - 1) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _botAvatar(),
                              const SizedBox(width: 12),
                              _TypingBubble(isDark: isDark),
                            ],
                          ),
                        );
                      }

                      final message = messages[index];
                      final isBot = message.sender == MessageSender.bot;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: isBot
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.end,
                          children: [
                            if (isBot) ...[
                              _botAvatar(),
                              const SizedBox(width: 12),
                            ],
                            Flexible(
                              child: _MessageBubble(
                                message: message,
                                isBot: isBot,
                                isDark: isDark,
                              ),
                            ),
                            if (!isBot) const SizedBox(width: 48),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // ── Input row ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBg : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        onSubmitted: (_) => _sendMessage(),
                        maxLines: null,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : AppColors.lightTextPrimary,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask your coach...',
                          hintStyle: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          fillColor: Colors.transparent,
                          filled: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    BlocBuilder<ChatBloc, ChatState>(
                      builder: (context, state) {
                        return GestureDetector(
                          onTap: state.isTyping ? null : _sendMessage,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: state.isTyping
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFF9B82FF),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.smart_toy_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isBot;
  final bool isDark;

  const _MessageBubble({
    required this.message,
    required this.isBot,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isBot
            ? (isDark ? AppColors.darkCardBg : Colors.white)
            : AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isBot ? 4 : 20),
          bottomRight: Radius.circular(isBot ? 20 : 4),
        ),
        border: isBot
            ? Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1.2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message.text,
        style: AppTextStyles.bodyLarge.copyWith(
          color: isBot
              ? (isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary)
              : Colors.white,
          fontSize: 15,
          height: 1.4,
        ),
      ),
    );
  }
}

/// Animated three-dot typing indicator shown while Cerebras is responding.
class _TypingBubble extends StatefulWidget {
  final bool isDark;
  const _TypingBubble({required this.isDark});

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.circular(4),
        ),
        border: Border.all(
          color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.2,
        ),
      ),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final offset = (i / 3);
              final val = ((_ctrl.value - offset) % 1.0).clamp(0.0, 1.0);
              final opacity = val < 0.5 ? val * 2 : (1.0 - val) * 2;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Opacity(
                  opacity: 0.3 + opacity * 0.7,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
