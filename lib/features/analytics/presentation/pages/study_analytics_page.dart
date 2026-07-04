import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_background.dart';

class StudyAnalyticsPage extends StatefulWidget {
  const StudyAnalyticsPage({super.key});

  @override
  State<StudyAnalyticsPage> createState() => _StudyAnalyticsPageState();
}

class _StudyAnalyticsPageState extends State<StudyAnalyticsPage> {
  int _selectedDayIndex = 3; // Default select Thursday (index 3)

  final List<String> _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final List<double> _weeklyProgress = [
    0.35,
    0.55,
    0.30,
    0.85,
    0.48,
    0.22,
    0.15
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title
              const SizedBox(height: 12),
              Text(
                'Analytics',
                style: AppTextStyles.headingMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Summary Metrics Row
              Row(
                children: [
                  _buildMetricCard('4.5h', 'HOURS', isDark),
                  const SizedBox(width: 12),
                  _buildMetricCard('3', 'SUBJECTS', isDark),
                  const SizedBox(width: 12),
                  _buildMetricCard('180', 'XP EARNED', isDark),
                ],
              ),
              const SizedBox(height: 24),

              // Bar Chart Card: Activity This Week
              GlassCard(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity This Week',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Bars Layout
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(_days.length, (index) {
                        final day = _days[index];
                        final heightFactor = _weeklyProgress[index];
                        final isSelected = _selectedDayIndex == index;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDayIndex = index;
                            });
                          },
                          child: Column(
                            children: [
                              // The Bar Container
                              Container(
                                width: 28,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkBorder
                                          .withValues(alpha: 0.4)
                                      : AppColors.lightBorder
                                          .withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(6),
                                  border: isSelected
                                      ? Border.all(
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.primary,
                                          width: 1.2,
                                        )
                                      : null,
                                ),
                                child: FractionalTranslation(
                                  translation: const Offset(0, 0),
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: double.infinity,
                                      height: 110 * heightFactor,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.primary.withValues(
                                                alpha: isDark ? 0.35 : 0.45),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Day Label
                              Text(
                                day,
                                style: TextStyle(
                                  color: isSelected
                                      ? (isDark
                                          ? Colors.white
                                          : AppColors.primaryDark)
                                      : (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Subject Breakdown header
              Text(
                'Subject Breakdown',
                style: AppTextStyles.headingSmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),

              // Breakdown rows
              _buildBreakdownRow(
                  'CS', '8.5h', '40%', 0.40, AppColors.subjectGreen, isDark),
              const SizedBox(height: 20),
              _buildBreakdownRow(
                  'Math', '5.2h', '25%', 0.25, AppColors.subjectPurple, isDark),
              const SizedBox(height: 20),
              _buildBreakdownRow('Languages', '4.1h', '20%', 0.20,
                  AppColors.subjectOrange, isDark),
              const SizedBox(height: 20),
              _buildBreakdownRow('Physics', '3.1h', '15%', 0.15,
                  AppColors.subjectPink, isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String val, String label, bool isDark) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              val,
              style: TextStyle(
                color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(
    String subject,
    String hours,
    String percent,
    double progressValue,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              subject,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Text(
                  hours,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  percent,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressValue,
            backgroundColor:
                isDark ? AppColors.darkBorder : AppColors.lightBorder,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
