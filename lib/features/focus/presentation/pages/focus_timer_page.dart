import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../bloc/navigation_bloc.dart';
import '../../../bloc/timer_bloc.dart';
import '../../../focus/focus_agenda_session.dart';
import '../../../subjects/presentation/bloc/subjects_bloc.dart';
import '../../../subjects/presentation/bloc/subjects_event.dart';
import '../../../subjects/presentation/bloc/subjects_state.dart';

class FocusTimerPage extends StatelessWidget {
  const FocusTimerPage({super.key});

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: GradientBackground(
        child: BlocListener<TimerBloc, TimerState>(
          listenWhen: (previous, current) =>
              previous.status != current.status &&
              current.status == TimerStatus.sessionComplete &&
              !current.isBreakComplete,
          listener: (context, state) {
            final isFreeform = state.taskId?.startsWith('freeform_') ?? false;

            // Show beautiful success snackbar
            AppSnackbar.show(
              context,
              type: SnackbarType.success,
              title: "Session Complete! 🎉",
              message: isFreeform
                  ? "Great job on your freeform study session!"
                  : "+50 XP earned. Keep it up!",
            );

            if (!isFreeform) {
              // Dispatch ToggleAgendaItemEvent to mark current task complete
              final subjectsBloc = context.read<SubjectsBloc>();
              final agendaItems = subjectsBloc.state.agendaItems;
              final taskId = state.taskId;

              int matchingItemIndex = -1;
              if (taskId != null) {
                matchingItemIndex = agendaItems.indexWhere(
                  (item) => item.id == taskId && !item.isCompleted,
                );
              }
              if (matchingItemIndex == -1 && state.taskTitle != null) {
                matchingItemIndex = agendaItems.indexWhere(
                  (item) =>
                      item.title == state.taskTitle && !item.isCompleted,
                );
              }
              if (matchingItemIndex != -1) {
                subjectsBloc.add(
                  ToggleAgendaItemEvent(agendaItems[matchingItemIndex].id),
                );
              }
            }
          },
          child: BlocBuilder<SubjectsBloc, SubjectsState>(
            builder: (context, subjectsState) {
              final agendaItems = subjectsState.agendaItems;
              return BlocBuilder<TimerBloc, TimerState>(
                builder: (context, state) {
                  final isFreeform = state.taskId?.startsWith('freeform_') ?? false;
                  final sessionNumber =
                      agendaSessionNumber(agendaItems, state.taskId);
                  final totalSessions = agendaTotalSessions(agendaItems);

                  return Stack(
                children: [
                  Column(
                    children: [
                      // Top navigation bar with back arrow
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back_rounded,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.lightTextPrimary,
                              ),
                              onPressed: () {
                                // Redirect back to dashboard container (which displays Home tab index 0)
                                context.read<NavigationBloc>().add(
                                      NavigateToScreenEvent(
                                          AppScreen.dashboard),
                                    );
                              },
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),

                      // Session context & indicator dots
                      Text(
                        isFreeform
                            ? 'Freeform Session'
                            : 'Focus Session $sessionNumber of $totalSessions',
                        style: AppTextStyles.headingSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontSize: 18,
                        ),
                      ),
                      if (!isFreeform) ...[
                        const SizedBox(height: 12),
                        // Session dots row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(totalSessions, (index) {
                            final isActive = index == (sessionNumber - 1);
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder),
                                shape: BoxShape.circle,
                              ),
                            );
                          }),
                        ),
                      ],

                      const Spacer(),

                      // Subject tag chip & Task title
                      if (state.subjectName != null ||
                          state.taskTitle != null) ...[
                        if (state.subjectName != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (state.subjectColor ?? AppColors.primary)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              state.subjectName!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: state.subjectColor ?? AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (state.taskTitle != null) ...[
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Text(
                              state.taskTitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.headingSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                      ],

                      // Large central timer dial
                      Center(
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isDark ? const Color(0xFF13122B) : Colors.white,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 4.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary
                                    .withValues(alpha: isDark ? 0.35 : 0.15),
                                blurRadius: 36,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatDuration(state.remainingSeconds),
                                style: TextStyle(
                                  fontSize: 54.0,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.lightTextPrimary,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                state.status == TimerStatus.onBreak
                                    ? 'BREAK'
                                    : 'POMODORO',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: state.status == TimerStatus.onBreak
                                      ? AppColors.subjectGreen
                                      : (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary),
                                  letterSpacing: 1.5,
                                  fontWeight:
                                      state.status == TimerStatus.onBreak
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Play / Pause & Skip Buttons
                      Padding(
                        padding: const EdgeInsets.only(bottom: 56.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Invisible spacing block to keep the play button centered
                                const SizedBox(width: 56),
                                const SizedBox(width: 16),
                                // Main Play/Pause Button
                                GestureDetector(
                                  onTap: () {
                                    if (state.isRunning) {
                                      context
                                          .read<TimerBloc>()
                                          .add(PauseTimerEvent());
                                    } else {
                                      context
                                          .read<TimerBloc>()
                                          .add(StartTimerEvent());
                                    }
                                  },
                                  child: Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.35),
                                          blurRadius: 20,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      state.isRunning
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Skip Button
                                GestureDetector(
                                  onTap: () {
                                    if (state.status == TimerStatus.onBreak) {
                                      context
                                          .read<TimerBloc>()
                                          .add(TickEvent(0));
                                    } else {
                                      final currentTaskId = state.taskId;
                                      if (currentTaskId == null) return;

                                      if (currentTaskId.startsWith('freeform_')) {
                                        context
                                            .read<TimerBloc>()
                                            .add(ResetTimerEvent());
                                        context
                                            .read<NavigationBloc>()
                                            .add(SwitchDashboardTabEvent(0));
                                        context
                                            .read<NavigationBloc>()
                                            .add(NavigateToScreenEvent(AppScreen.dashboard));
                                        return;
                                      }

                                      if (agendaItems.indexWhere(
                                            (item) => item.id == currentTaskId,
                                          ) <
                                          0) {
                                        return;
                                      }

                                      final next = agendaNextIncompleteItemForward(
                                        agendaItems,
                                        currentTaskId,
                                      );

                                      if (next == null) {
                                        context
                                            .read<TimerBloc>()
                                            .add(EndSessionsEvent());
                                        return;
                                      }

                                      context.read<TimerBloc>().add(
                                        SkipSessionEvent(
                                          taskId: next.id,
                                          durationSeconds:
                                              next.durationMinutes * 60,
                                          taskTitle: next.title,
                                          subjectName: next.tag,
                                          subjectColor: next.tagColor,
                                          isRunning: true,
                                        ),
                                      );
                                      AppSnackbar.show(
                                        context,
                                        type: SnackbarType.info,
                                        title: "Skipped to next task",
                                        message: next.title,
                                      );
                                    }
                                  },
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? AppColors.darkCardBg
                                          : Colors.white,
                                      border: Border.all(
                                        color: isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.skip_next_rounded,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.lightTextPrimary,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (state.status == TimerStatus.onBreak) ...[
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () {
                                  context.read<TimerBloc>().add(TickEvent(0));
                                },
                                child: const Text(
                                  'End Break Early',
                                  style: TextStyle(
                                    color: AppColors.subjectGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Blur overlay when session completes or sessions end via skip
                  if (state.status == TimerStatus.sessionComplete)
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.6),
                          child: Center(
                            child: SessionCompleteModal(
                              timerState: state,
                              sessionNumber: sessionNumber,
                              totalSessions: totalSessions,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (state.status == TimerStatus.sessionsEnded)
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.6),
                          child: Center(
                            child: SessionsEndedModal(
                              timerState: state,
                              sessionNumber: sessionNumber,
                              totalSessions: totalSessions,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class SessionCompleteModal extends StatelessWidget {
  final TimerState timerState;
  final int sessionNumber;
  final int totalSessions;

  const SessionCompleteModal({
    super.key,
    required this.timerState,
    required this.sessionNumber,
    required this.totalSessions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = timerState;
    final isBreakComplete = state.isBreakComplete;
    final subjectsBloc = context.read<SubjectsBloc>();
    final agendaItems = subjectsBloc.state.agendaItems;
    final nextItem = agendaNextItemAtIndex(agendaItems, state.taskId);
    final isLongBreak = isLongBreakForAgendaSession(sessionNumber);
    final settings = subjectsBloc.state.settings;
    final breakMinutes =
        isLongBreak ? settings.longBreak : settings.shortBreak;
    final isFreeform = state.taskId?.startsWith('freeform_') ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkOverlayBg.withValues(alpha: 0.95)
            : AppColors.lightCardBg.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              (state.subjectColor ?? AppColors.primary).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Success icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.subjectGreen.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.subjectGreen,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),

          // 2. Title
          Text(
            isBreakComplete ? 'Break Complete!' : 'Session Complete!',
            style: AppTextStyles.headingSmall.copyWith(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // 3. XP earned text
          if (!isBreakComplete && !isFreeform) ...[
            const Text(
              '+50 XP Earned!',
              style: TextStyle(
                color: AppColors.subjectGreen,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],

          if (!isFreeform) ...[
            // 4. Session counter
            Text(
              'Session $sessionNumber of $totalSessions complete',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // 5. Break type label
            Text(
              isBreakComplete
                  ? 'Ready for your next study session?'
                  : (isLongBreak
                      ? 'Long Break — $breakMinutes minutes'
                      : 'Short Break — $breakMinutes minutes'),
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary.withValues(alpha: 0.7)
                    : AppColors.lightTextSecondary.withValues(alpha: 0.7),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Next Task Preview Section
            Text(
              'Up Next:',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              child: nextItem != null
                  ? Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: nextItem.tagColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            nextItem.tag,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: nextItem.tagColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            nextItem.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightTextPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${nextItem.durationMinutes}m',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Text(
                        'All tasks complete! 🎉',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.subjectGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            Text(
              'Great job focusing on ${state.subjectName ?? 'your study'}!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],

          // 6 & 7. Buttons
          if (isFreeform) ...[
            GestureDetector(
              onTap: () {
                context.read<TimerBloc>().add(ResetTimerEvent());
                context
                    .read<NavigationBloc>()
                    .add(NavigateToScreenEvent(AppScreen.focusTimer)); // Navigate to clear/reset state properly or stay on dashboard
                // Wait! Let's navigate to dashboard since it's the home screen
                context
                    .read<NavigationBloc>()
                    .add(NavigateToScreenEvent(AppScreen.dashboard));
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.subjectPurple],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ] else ...[
            if (!isBreakComplete) ...[
              // Start Break Button
              GestureDetector(
                onTap: () {
                  context.read<TimerBloc>().add(
                        StartBreakEvent(
                          isLongBreak: isLongBreak,
                          durationSeconds: breakMinutes * 60,
                        ),
                      );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.subjectPurple],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: const Text(
                    'Start Break',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Skip Break Button
              GestureDetector(
                onTap: () {
                  final taskTitle = state.taskTitle;
                  if (taskTitle != null) {
                    final agendaItems = subjectsBloc.state.agendaItems;
                    final matchingItemIndex = agendaItems.indexWhere(
                      (item) => item.title == taskTitle && !item.isCompleted,
                    );
                    if (matchingItemIndex != -1) {
                      subjectsBloc.add(ToggleAgendaItemEvent(
                          agendaItems[matchingItemIndex].id));
                    }
                  }

                  if (nextItem != null) {
                    context.read<TimerBloc>().add(SkipBreakEvent(
                          nextTaskId: nextItem.id,
                          nextDurationSeconds: nextItem.durationMinutes * 60,
                          nextTaskTitle: nextItem.title,
                          nextSubjectName: nextItem.tag,
                          nextSubjectColor: nextItem.tagColor,
                        ));
                  } else {
                    context.read<TimerBloc>().add(ResetTimerEvent());
                    context
                        .read<NavigationBloc>()
                        .add(NavigateToScreenEvent(AppScreen.dashboard));
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 1.5,
                    ),
                    color: isDark ? const Color(0xFF2E2B54) : Colors.white,
                  ),
                  child: Text(
                    'Skip Break',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ] else ...[
              if (nextItem != null) ...[
                // Start Next Session Button
                GestureDetector(
                  onTap: () {
                    // Mark current task complete
                    final taskTitle = state.taskTitle;
                    if (taskTitle != null) {
                      final subjectsBloc = context.read<SubjectsBloc>();
                      final agendaItems = subjectsBloc.state.agendaItems;
                      final matchingItemIndex = agendaItems.indexWhere(
                        (item) => item.title == taskTitle && !item.isCompleted,
                      );
                      if (matchingItemIndex != -1) {
                        subjectsBloc.add(ToggleAgendaItemEvent(
                            agendaItems[matchingItemIndex].id));
                      }
                    }

                    context.read<TimerBloc>().add(StartTimerEvent(
                          taskId: nextItem.id,
                          durationSeconds: nextItem.durationMinutes * 60,
                          taskTitle: nextItem.title,
                          subjectName: nextItem.tag,
                          subjectColor: nextItem.tagColor,
                        ));
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.subjectPurple],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: const Text(
                      'Start Next Session',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            const SizedBox(height: 12),
          ] else ...[
            // All Done Today! 🎉 Button
            GestureDetector(
              onTap: () {
                // Mark current task complete
                final taskTitle = state.taskTitle;
                if (taskTitle != null) {
                  final subjectsBloc = context.read<SubjectsBloc>();
                  final agendaItems = subjectsBloc.state.agendaItems;
                  final matchingItemIndex = agendaItems.indexWhere(
                    (item) => item.title == taskTitle && !item.isCompleted,
                  );
                  if (matchingItemIndex != -1) {
                    subjectsBloc.add(ToggleAgendaItemEvent(
                        agendaItems[matchingItemIndex].id));
                  }
                }

                context.read<TimerBloc>().add(ResetTimerEvent());
                context
                    .read<NavigationBloc>()
                    .add(NavigateToScreenEvent(AppScreen.dashboard));
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [AppColors.subjectGreen, AppColors.subjectBlue],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: const Text(
                  'All Done Today! 🎉',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          // All Done Button
          GestureDetector(
            onTap: () {
              context.read<TimerBloc>().add(ResetTimerEvent());
              context
                  .read<NavigationBloc>()
                  .add(NavigateToScreenEvent(AppScreen.dashboard));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.5,
                ),
                color: isDark ? const Color(0xFF2E2B54) : Colors.white,
              ),
              child: Text(
                'All Done',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ],
    ],
  ),
);
}
}

class SessionsEndedModal extends StatelessWidget {
  final TimerState timerState;
  final int sessionNumber;
  final int totalSessions;

  const SessionsEndedModal({
    super.key,
    required this.timerState,
    required this.sessionNumber,
    required this.totalSessions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkOverlayBg.withValues(alpha: 0.95)
            : AppColors.lightCardBg.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.self_improvement_rounded,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "You've finished today's focus sessions",
            style: AppTextStyles.headingSmall.copyWith(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Session $sessionNumber of $totalSessions',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Skipped tasks stay on your agenda until you mark them complete on Home.',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary.withValues(alpha: 0.8)
                  : AppColors.lightTextSecondary.withValues(alpha: 0.8),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              context.read<TimerBloc>().add(ResetTimerEvent());
              context
                  .read<NavigationBloc>()
                  .add(NavigateToScreenEvent(AppScreen.dashboard));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.subjectPurple],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: const Text(
                'Back to Home',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
