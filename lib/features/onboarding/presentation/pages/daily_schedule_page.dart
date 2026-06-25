import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../bloc/navigation_bloc.dart';
import '../../../bloc/subjects_bloc.dart';

class DailySchedulePage extends StatelessWidget {
  const DailySchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            // Header with back button & Step indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                    onPressed: () {
                      context.read<NavigationBloc>().add(
                            NavigateToScreenEvent(AppScreen.addSubjects),
                          );
                    },
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Step 3 of 3',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Title section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Study\nSchedule',
                      style: AppTextStyles.headingMedium.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Help us build your personalized plan',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: BlocBuilder<SubjectsBloc, SubjectsState>(
                  builder: (context, state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Daily Study Time Slider Card
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Daily Study Time',
                              style: AppTextStyles.headingSmall.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              '${state.dailyStudyMinutes} min',
                              style: TextStyle(
                                color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Slider(
                          value: state.dailyStudyMinutes.toDouble(),
                          min: 15,
                          max: 240,
                          divisions: 15,
                          onChanged: (val) {
                            context.read<SubjectsBloc>().add(
                                  UpdateDailyMinutesEvent(val.toInt()),
                                );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '15 min',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              Text(
                                '4 hrs',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Preferred Study Time Section
                        Text(
                          'Preferred Study Time',
                          style: AppTextStyles.headingSmall.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Time slots list
                        _buildTimeSlotCard(
                          context,
                          label: 'Morning (8 AM - 12 PM)',
                          value: 'Morning',
                          selectedValue: state.preferredTime,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildTimeSlotCard(
                          context,
                          label: 'Afternoon (1 PM - 5 PM)',
                          value: 'Afternoon',
                          selectedValue: state.preferredTime,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildTimeSlotCard(
                          context,
                          label: 'Evening (6 PM - 10 PM)',
                          value: 'Evening',
                          selectedValue: state.preferredTime,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 32),

                        // Notifications Card
                        GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Row(
                            children: [
                              Text(
                                'Notification Reminders',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: state.notificationsEnabled,
                                onChanged: (val) {
                                  context.read<SubjectsBloc>().add(
                                        ToggleNotificationsEvent(val),
                                      );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    );
                  },
                ),
              ),
            ),
            // Bottom Button & Indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: PrimaryButton(
                text: 'Generate My Plan',
                icon: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  context.read<NavigationBloc>().add(
                        NavigateToScreenEvent(AppScreen.dashboard),
                      );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Dots Indicators (Page 3 active)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotCard(
    BuildContext context, {
    required String label,
    required String value,
    required String selectedValue,
    required bool isDark,
  }) {
    final isSelected = selectedValue == value;

    return GestureDetector(
      onTap: () {
        context.read<SubjectsBloc>().add(
              UpdatePreferredTimeEvent(value),
            );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primary.withOpacity(0.12) : AppColors.primary.withOpacity(0.08))
              : (isDark ? AppColors.darkCardBg : AppColors.lightCardBg),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Custom Radio Dot
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.lightTextSecondary.withOpacity(0.5)),
                  width: 2.0,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isSelected
                    ? (isDark ? AppColors.darkTextPrimary : AppColors.primaryDark)
                    : (isDark ? AppColors.darkTextPrimary.withOpacity(0.8) : AppColors.lightTextPrimary),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
