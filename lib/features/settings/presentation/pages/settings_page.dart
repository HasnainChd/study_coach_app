import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../bloc/navigation_bloc.dart';
import '../../../bloc/subjects_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: GradientBackground(
        child: BlocBuilder<SubjectsBloc, SubjectsState>(
          builder: (context, state) {
            final prefs = state.settings;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header Actions
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                        onPressed: () {
                          // Go back to Home tab (index 0)
                          context.read<NavigationBloc>().add(SwitchDashboardTabEvent(0));
                        },
                      ),
                      const Spacer(),
                      Text(
                        'Settings',
                        style: AppTextStyles.headingSmall.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
                          context.read<NavigationBloc>().add(SwitchDashboardTabEvent(0));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Profile Card
                  Center(
                    child: GlassCard(
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
                                child: const Center(
                                  child: Text(
                                    'A',
                                    style: TextStyle(
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
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Alex Johnson',
                            style: AppTextStyles.headingSmall.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'alex@example.com',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // STUDY PREFERENCES
                  Text(
                    'STUDY PREFERENCES',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Preferences Card
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      children: [
                        _buildChoiceSelector(
                          context,
                          label: 'Pomodoro Focus',
                          options: [25, 45, 60],
                          selectedValue: prefs.pomodoroFocus,
                          onSelected: (val) {
                            context.read<SubjectsBloc>().add(
                                  UpdateSettingsPreferencesEvent(pomodoroFocus: val),
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
                                  UpdateSettingsPreferencesEvent(shortBreak: val),
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
                                  UpdateSettingsPreferencesEvent(longBreak: val),
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
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Notifications settings Card
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      children: [
                        _buildSwitchRow(
                          label: 'Daily Reminder',
                          value: prefs.dailyReminder,
                          onChanged: (val) {
                            context.read<SubjectsBloc>().add(
                                  UpdateSettingsPreferencesEvent(dailyReminder: val),
                                );
                          },
                        ),
                        _buildSwitchRow(
                          label: 'Streak Alerts',
                          value: prefs.streakAlerts,
                          onChanged: (val) {
                            context.read<SubjectsBloc>().add(
                                  UpdateSettingsPreferencesEvent(streakAlerts: val),
                                );
                          },
                        ),
                        _buildSwitchRow(
                          label: 'Study Tips',
                          value: prefs.studyTips,
                          onChanged: (val) {
                            context.read<SubjectsBloc>().add(
                                  UpdateSettingsPreferencesEvent(studyTips: val),
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
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
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOptionSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    option.toString(),
                    style: TextStyle(
                      color: isOptionSelected
                          ? Colors.white
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
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

  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
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
