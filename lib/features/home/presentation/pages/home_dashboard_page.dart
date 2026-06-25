import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../bloc/navigation_bloc.dart';
import '../../../bloc/subjects_bloc.dart';
import '../../../bloc/theme_bloc.dart';

class HomeDashboardPage extends StatelessWidget {
  const HomeDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: GradientBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TUESDAY, JUNE 17',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Good morning, Alex',
                        style: AppTextStyles.headingMedium.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Settings Theme Toggle Button
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 1.5,
                      ),
                      color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                      onPressed: () {
                        context.read<ThemeBloc>().add(ToggleThemeEvent());
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Streak Card
              GlassCard(
                child: Row(
                  children: [
                    // Flame icon container
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFECE5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF8551).withOpacity(0.2),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.local_fire_department_rounded,
                          color: Color(0xFFFF5100),
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Streak text and progress
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '12 Day Streak',
                            style: AppTextStyles.headingSmall.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Level 7 Scholar',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.subjectGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // XP progress indicators
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'XP PROGRESS',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                '68%',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: const LinearProgressIndicator(
                              value: 0.68,
                              backgroundColor: AppColors.darkBorder,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Today's Agenda header
              Text(
                "Today's Agenda",
                style: AppTextStyles.headingSmall.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Agenda list
              Expanded(
                child: BlocBuilder<SubjectsBloc, SubjectsState>(
                  builder: (context, state) {
                    final items = state.agendaItems;
                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return GestureDetector(
                          onTap: () {
                            context.read<SubjectsBloc>().add(
                                  ToggleAgendaItemEvent(item.id),
                                );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: item.isCompleted
                                    ? AppColors.subjectGreen.withOpacity(0.4)
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Checkbox Circle
                                Icon(
                                  item.isCompleted
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: item.isCompleted
                                      ? AppColors.subjectGreen
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  size: 24,
                                ),
                                const SizedBox(width: 16),
                                // Title & Subject Pills
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: item.isCompleted
                                              ? (isDark ? AppColors.darkTextSecondary.withOpacity(0.6) : AppColors.lightTextSecondary.withOpacity(0.6))
                                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                          decoration: item.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: item.tagColor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              item.tag,
                                              style: TextStyle(
                                                color: item.tagColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '${item.durationMinutes} min',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Quick Start Session Button
              PrimaryButton(
                text: 'Quick Start Session',
                icon: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {
                  context.read<NavigationBloc>().add(
                        NavigateToScreenEvent(AppScreen.focusTimer),
                      );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
