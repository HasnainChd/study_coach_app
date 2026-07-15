import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../bloc/subjects_bloc.dart';
import '../../domain/analytics_calculator.dart';
import '../bloc/analytics_bloc.dart';
import '../bloc/analytics_event.dart';
import '../bloc/analytics_state.dart';

class StudyAnalyticsPage extends StatelessWidget {
  const StudyAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SubjectsBloc, SubjectsState>(
      listener: (context, subjectsState) {
        context
            .read<AnalyticsBloc>()
            .add(LoadAnalyticsEvent(subjectsState.subjects));
      },
      child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        builder: (context, state) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          return Scaffold(
            body: GradientBackground(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Row(
                      children: [
                        _buildMetricCard(state.weekHoursLabel, 'HOURS', isDark),
                        const SizedBox(width: 12),
                        _buildMetricCard(
                          '${state.subjectCount}',
                          'SUBJECTS',
                          isDark,
                        ),
                        const SizedBox(width: 12),
                        _buildMetricCard(
                          state.allTimeXpLabel,
                          'XP EARNED',
                          isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
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
                          if (!state.hasWeeklyActivity) ...[
                            const SizedBox(height: 24),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bar_chart_rounded,
                                    size: 40,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Complete a few study sessions to see your activity here.',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 28),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(state.dayLabels.length, (index) {
                                final day = state.dayLabels[index];
                                final heightFactor = state.dayHeightFactors[index];
                                final isSelected = state.selectedDayIndex == index;

                                return GestureDetector(
                                  onTap: () {
                                    context.read<AnalyticsBloc>().add(
                                          SelectAnalyticsDayEvent(index),
                                        );
                                  },
                                  child: Column(
                                    children: [
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
                                        child: Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Container(
                                            width: double.infinity,
                                            height: 110 * heightFactor,
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.primary.withValues(
                                                      alpha: isDark ? 0.35 : 0.45,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
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
                    if (!state.hasBreakdown)
                      GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.donut_large_rounded,
                                size: 40,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Complete a few study sessions to see your breakdown.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...state.breakdownRows.asMap().entries.map((entry) {
                        final row = entry.value;
                        final isLast = entry.key == state.breakdownRows.length - 1;
                        return Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 24 : 20),
                          child: _buildBreakdownRow(
                            row.subjectName,
                            AnalyticsCalculator.formatHours(row.totalMinutes),
                            '${(row.share * 100).round()}%',
                            row.share,
                            row.color,
                            isDark,
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          );
        },
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
