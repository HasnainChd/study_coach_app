import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../bloc/navigation_bloc.dart';

class CoachEmptyStatePage extends StatelessWidget {
  const CoachEmptyStatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: GradientBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 48), // spacer
                  const Spacer(),
                  Text(
                    'AI Coach',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  // History button
                  IconButton(
                    icon: Icon(
                      Icons.history_rounded,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Orbiting Robot Logo Stack
              SizedBox(
                height: 180,
                width: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glowing orb
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? AppColors.primary.withOpacity(0.12)
                            : AppColors.primary.withOpacity(0.08),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? AppColors.primary.withOpacity(0.8)
                                : AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.smart_toy_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    // Floating orbits / dots
                    // Green Dot top-left
                    Positioned(
                      top: 24,
                      left: 36,
                      child: _buildFloatingDot(AppColors.subjectGreen, 10),
                    ),
                    // Purple Dot middle-right
                    Positioned(
                      bottom: 72,
                      right: 18,
                      child: _buildFloatingDot(AppColors.subjectPurple, 8),
                    ),
                    // Orange Dot bottom-center
                    Positioned(
                      bottom: 24,
                      left: 80,
                      child: _buildFloatingDot(AppColors.subjectOrange, 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Title & Subtitle
              Text(
                'Your AI Coach is Ready',
                style: AppTextStyles.headingMedium.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Add your subjects to get a personalised study plan and targeted practice.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Checklist Cards
              _buildFeatureCard(
                context,
                icon: Icons.auto_awesome_rounded,
                iconColor: AppColors.subjectPurple,
                text: 'Personalized study plan',
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                context,
                icon: Icons.bar_chart_rounded,
                iconColor: AppColors.subjectGreen,
                text: 'Track your progress',
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                context,
                icon: Icons.notifications_active_rounded,
                iconColor: AppColors.subjectOrange,
                text: 'Smart reminders',
                isDark: isDark,
              ),

              const Spacer(),

              // Button: Set Up My Subjects
              PrimaryButton(
                text: 'Set Up My Subjects',
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  // Switch to onboarding addSubjects page
                  context.read<NavigationBloc>().add(
                        NavigateToScreenEvent(AppScreen.addSubjects),
                      );
                },
              ),
              const SizedBox(height: 12),
              Text(
                'TAKES LESS THAN 2 MINUTES',
                style: AppTextStyles.labelSmall.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: size,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String text,
    required bool isDark,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 16),
          Text(
            text,
            style: AppTextStyles.bodyLarge.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
