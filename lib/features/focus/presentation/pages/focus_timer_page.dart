import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../bloc/navigation_bloc.dart';
import '../../../bloc/timer_bloc.dart';

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
        child: BlocBuilder<TimerBloc, TimerState>(
          builder: (context, state) {
            return Column(
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
                                NavigateToScreenEvent(AppScreen.dashboard),
                              );
                        },
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                // Session context & indicator dots
                Text(
                  'Focus Session ${state.sessionNumber} of 4',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                // Session dots row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isActive = index == (state.sessionNumber - 1);
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

                const Spacer(),

                // Large central timer dial
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF13122B) : Colors.white,
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
                          'POMODORO',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            letterSpacing: 1.5,
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Invisible spacing block to keep the play button centered
                      const SizedBox(width: 56),
                      const SizedBox(width: 16),
                      // Main Play/Pause Button
                      GestureDetector(
                        onTap: () {
                          if (state.isRunning) {
                            context.read<TimerBloc>().add(PauseTimerEvent());
                          } else {
                            context.read<TimerBloc>().add(StartTimerEvent());
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
                                color:
                                    AppColors.primary.withValues(alpha: 0.35),
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
                          context.read<TimerBloc>().add(SkipSessionEvent());
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? AppColors.darkCardBg : Colors.white,
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
