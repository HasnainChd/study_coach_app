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

  static const String _studyPlanUpdatedMessage =
      'Daily study time updated. Regenerate your plan in Settings when '
      "you're ready to apply it.";

  void _showStudyPlanUpdatedSnackbar(BuildContext context) {
    AppSnackbar.show(
      context,
      type: SnackbarType.info,
      title: 'Study plan setting updated',
      message: _studyPlanUpdatedMessage,
    );
  }

  void _showEditNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
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
                  'Edit Name',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    hintStyle: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkOverlayBg
                        : AppColors.lightBorder.withValues(alpha: 0.35),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
                      onTap: () async {
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
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
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
                          'Save',
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
            ),
          ),
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

                      // DAILY STUDY PLAN
                      Text(
                        'DAILY STUDY PLAN',
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
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Daily Study Time',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${state.dailyStudyMinutes} min',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.primaryLight
                                        : AppColors.primaryDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: state.dailyStudyMinutes.toDouble(),
                              min: 15,
                              max: 240,
                              divisions: 15,
                              onChanged: state.status ==
                                      SubjectsStatus.planGenerating
                                  ? null
                                  : (val) {
                                      context.read<SubjectsBloc>().add(
                                            UpdateDailyMinutesEvent(
                                              val.toInt(),
                                            ),
                                          );
                                    },
                              onChangeEnd: state.status ==
                                      SubjectsStatus.planGenerating
                                  ? null
                                  : (_) {
                                      _showStudyPlanUpdatedSnackbar(context);
                                    },
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '15 min',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  Text(
                                    '4 hrs',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Preferred Study Time',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildTimeSlotCard(
                              context,
                              label: 'Morning (8 AM - 12 PM)',
                              value: 'Morning',
                              selectedValue: state.preferredTime,
                              isDark: isDark,
                              isEnabled:
                                  state.status != SubjectsStatus.planGenerating,
                              onSelected: () {
                                if (state.preferredTime == 'Morning') return;
                                context.read<SubjectsBloc>().add(
                                      UpdatePreferredTimeEvent('Morning'),
                                    );
                                _showStudyPlanUpdatedSnackbar(context);
                              },
                            ),
                            const SizedBox(height: 10),
                            _buildTimeSlotCard(
                              context,
                              label: 'Afternoon (1 PM - 5 PM)',
                              value: 'Afternoon',
                              selectedValue: state.preferredTime,
                              isDark: isDark,
                              isEnabled:
                                  state.status != SubjectsStatus.planGenerating,
                              onSelected: () {
                                if (state.preferredTime == 'Afternoon') return;
                                context.read<SubjectsBloc>().add(
                                      UpdatePreferredTimeEvent('Afternoon'),
                                    );
                                _showStudyPlanUpdatedSnackbar(context);
                              },
                            ),
                            const SizedBox(height: 10),
                            _buildTimeSlotCard(
                              context,
                              label: 'Evening (6 PM - 10 PM)',
                              value: 'Evening',
                              selectedValue: state.preferredTime,
                              isDark: isDark,
                              isEnabled:
                                  state.status != SubjectsStatus.planGenerating,
                              onSelected: () {
                                if (state.preferredTime == 'Evening') return;
                                context.read<SubjectsBloc>().add(
                                      UpdatePreferredTimeEvent('Evening'),
                                    );
                                _showStudyPlanUpdatedSnackbar(context);
                              },
                            ),
                          ],
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
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 2),
                              child: Text(
                                'Task sessions use each agenda item\'s duration. '
                                'This applies only when no tasks are scheduled.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                  fontSize: 12,
                                ),
                              ),
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
                              label: 'Notification Reminders',
                              value: state.notificationsEnabled,
                              onChanged: (val) {
                                context.read<SubjectsBloc>().add(
                                      ToggleNotificationsEvent(val),
                                    );
                              },
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Divider(
                                color: Colors.transparent,
                                height: 1,
                              ),
                            ),
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

                      // AI COACH
                      Text(
                        'AI COACH',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => _showResetChatConfirmation(context),
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Reset Conversation',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    _showRegenerateConfirmation(context),
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Regenerate Study Plan',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),

                            ],
                          ),
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

  Widget _buildTimeSlotCard(
    BuildContext context, {
    required String label,
    required String value,
    required String selectedValue,
    required bool isDark,
    required bool isEnabled,
    required VoidCallback onSelected,
  }) {
    final isSelected = selectedValue == value;

    return GestureDetector(
      onTap: isEnabled ? onSelected : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.primary.withValues(alpha: 0.08))
              : (isDark ? AppColors.darkBgStart : AppColors.lightBgStart),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkBorder
                          : AppColors.lightTextSecondary
                              .withValues(alpha: 0.5)),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.primaryDark)
                      : (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
