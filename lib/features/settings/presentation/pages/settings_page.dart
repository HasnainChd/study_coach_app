import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../bloc/navigation_bloc.dart';
import '../../../bloc/subjects_bloc.dart';
import '../../../bloc/chat_bloc.dart';
import '../../../home/presentation/pages/home_dashboard_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showEditNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.darkOverlayBg : AppColors.lightCardBg,
          title: Text(
            'Edit Name',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: controller,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'Enter your name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('userName', newName);
                  HomeDashboardPage.userNameNotifier.value = newName;
                }
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRegenerateConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkOverlayBg : AppColors.lightCardBg,
          title: Text(
            'Regenerate Study Plan?',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "This will replace all of today's tasks with a fresh plan including all your current subjects. XP and streak already earned will be kept. Continue?",
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
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
                    Navigator.pop(dialogContext);
                    final state = context.read<SubjectsBloc>().state;
                    context.read<SubjectsBloc>().add(
                      RegenerateStudyPlanEvent(
                        state.dailyStudyMinutes,
                        state.preferredTime,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primary,
                          Color(0xFF805CFF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Regenerate',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showResetChatConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkOverlayBg : AppColors.lightCardBg,
          title: Text(
            'Reset Conversation?',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "This will clear all past chat history with your AI Study Coach. This action cannot be undone. Continue?",
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<ChatBloc>().add(ClearChatEvent());
                AppSnackbar.show(
                  context,
                  type: SnackbarType.success,
                  title: 'Chat History Cleared!',
                  message: 'Your conversation has been reset.',
                );
              },
              child: const Text(
                'Reset',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (HomeDashboardPage.userNameNotifier.value == null) {
      SharedPreferences.getInstance().then((prefs) {
        final name = prefs.getString('userName');
        if (name != null) {
          HomeDashboardPage.userNameNotifier.value = name;
        }
      });
    }

    return Scaffold(
      body: GradientBackground(
        child: BlocConsumer<SubjectsBloc, SubjectsState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status == SubjectsStatus.planGenerated) {
              context.read<NavigationBloc>().add(SwitchDashboardTabEvent(0));
              if (state.planBudgetWarningMessage != null) {
                AppSnackbar.show(
                  context,
                  type: SnackbarType.warning,
                  title: 'Daily budget too small',
                  message: state.planBudgetWarningMessage!,
                );
              }
              AppSnackbar.show(
                context,
                type: SnackbarType.success,
                title: "Study plan regenerated! 🚀",
                message: "Your fresh study tasks are ready on Home.",
              );
            } else if (state.status == SubjectsStatus.failure) {
              AppSnackbar.show(
                context,
                type: SnackbarType.error,
                title: "Failed to regenerate plan",
                message: state.errorMessage ?? "An unknown error occurred.",
              );
            }
          },
          builder: (context, state) {
            final prefs = state.settings;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Header Actions
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightTextPrimary,
                            ),
                            onPressed: () {
                              // Go back to Home tab (index 0)
                              context
                                  .read<NavigationBloc>()
                                  .add(SwitchDashboardTabEvent(0));
                            },
                          ),
                          const Spacer(),
                          Text(
                            'Settings',
                            style: AppTextStyles.headingSmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const Spacer(),
                          // Done Checkmark
                          IconButton(
                            icon: const Icon(
                              Icons.check_rounded,
                              color: AppColors.primary,
                            ),
                            onPressed: () {
                              context
                                  .read<NavigationBloc>()
                                  .add(SwitchDashboardTabEvent(0));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Profile Card
                      Center(
                        child: ValueListenableBuilder<String?>(
                          valueListenable: HomeDashboardPage.userNameNotifier,
                          builder: (context, name, _) {
                            final displayName = name != null && name.isNotEmpty
                                ? name
                                : 'Study Coach User';
                            final initial = displayName.trim().isNotEmpty
                                ? displayName.trim()[0].toUpperCase()
                                : 'S';

                            return GlassCard(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  // Circular edit avatar
                                  Stack(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            initial,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: () {
                                            _showEditNameDialog(
                                                context, name ?? '');
                                          },
                                          child: Container(
                                            width: 26,
                                            height: 26,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF2C2A4A),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.edit_rounded,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    displayName,
                                    style: AppTextStyles.headingSmall.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to edit name',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),

                      // STUDY PREFERENCES
                      Text(
                        'STUDY PREFERENCES',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Preferences Card
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        child: Column(
                          children: [
                            _buildChoiceSelector(
                              context,
                              label: 'Pomodoro Focus',
                              options: [25, 45, 60],
                              selectedValue: prefs.pomodoroFocus,
                              onSelected: (val) {
                                context.read<SubjectsBloc>().add(
                                      UpdateSettingsPreferencesEvent(
                                          pomodoroFocus: val),
                                    );
                              },
                              isDark: isDark,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Divider(color: Colors.transparent, height: 1),
                            ),
                            _buildChoiceSelector(
                              context,
                              label: 'Short Break',
                              options: [5, 10],
                              selectedValue: prefs.shortBreak,
                              onSelected: (val) {
                                context.read<SubjectsBloc>().add(
                                      UpdateSettingsPreferencesEvent(
                                          shortBreak: val),
                                    );
                              },
                              isDark: isDark,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Divider(color: Colors.transparent, height: 1),
                            ),
                            _buildChoiceSelector(
                              context,
                              label: 'Long Break',
                              options: [15, 20],
                              selectedValue: prefs.longBreak,
                              onSelected: (val) {
                                context.read<SubjectsBloc>().add(
                                      UpdateSettingsPreferencesEvent(
                                          longBreak: val),
                                    );
                              },
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // NOTIFICATIONS
                      Text(
                        'NOTIFICATIONS',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Notifications settings Card
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Column(
                          children: [
                            _buildSwitchRow(
                              context,
                              label: 'Daily Reminder',
                              value: prefs.dailyReminder,
                              onChanged: (val) {
                                context.read<SubjectsBloc>().add(
                                      UpdateSettingsPreferencesEvent(
                                          dailyReminder: val),
                                    );
                              },
                            ),
                            _buildSwitchRow(
                              context,
                              label: 'Streak Alerts',
                              value: prefs.streakAlerts,
                              onChanged: (val) {
                                context.read<SubjectsBloc>().add(
                                      UpdateSettingsPreferencesEvent(
                                          streakAlerts: val),
                                    );
                              },
                            ),
                            _buildSwitchRow(
                              context,
                              label: 'Study Tips',
                              value: prefs.studyTips,
                              onChanged: (val) {
                                context.read<SubjectsBloc>().add(
                                      UpdateSettingsPreferencesEvent(
                                          studyTips: val),
                                    );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ACCOUNT & DATA
                      Text(
                        'ACCOUNT & DATA',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                              title: Text(
                                'Regenerate Study Plan',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              subtitle: Text(
                                'AI drafts a fresh plan with current subjects',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              onTap: () => _showRegenerateConfirmation(context),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.redAccent),
                              title: Text(
                                'Reset Conversation',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              subtitle: Text(
                                'Clear chat history with AI coach',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              onTap: () => _showResetChatConfirmation(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                if (state.status == SubjectsStatus.planGenerating)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.55),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40.0),
                            child: GlassCard(
                              padding: const EdgeInsets.all(28.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primary),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'AI Coach drafting your plan...',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.lightTextPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Personalizing your schedule using Gemini AI',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildChoiceSelector(
    BuildContext context, {
    required String label,
    required List<int> options,
    required int selectedValue,
    required ValueChanged<int> onSelected,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(
            color:
                isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        // Options buttons row
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgStart : AppColors.lightBgStart,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: options.map((option) {
              final isOptionSelected = option == selectedValue;
              return GestureDetector(
                onTap: () => onSelected(option),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOptionSelected
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    option.toString(),
                    style: TextStyle(
                      color: isOptionSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow(
    BuildContext context, {
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
