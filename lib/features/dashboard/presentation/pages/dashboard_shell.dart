import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../analytics/presentation/pages/study_analytics_page.dart';
import '../../../analytics/presentation/bloc/analytics_bloc.dart';
import '../../../analytics/presentation/bloc/analytics_event.dart';
import '../../../bloc/navigation_bloc.dart';
import '../../../bloc/subjects_bloc.dart';
import '../../../chat/presentation/pages/coach_chat_page.dart';
import '../../../chat/presentation/pages/coach_empty_state_page.dart';
import '../../../home/presentation/pages/home_dashboard_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../subjects/presentation/pages/subject_manager_page.dart';

class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, navState) {
        return Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildPage(navState.activeTabIndex),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.2,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      context,
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: 'Home',
                      index: 0,
                      activeIndex: navState.activeTabIndex,
                      isDark: isDark,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.bar_chart_outlined,
                      activeIcon: Icons.bar_chart_rounded,
                      label: 'Analytics',
                      index: 1,
                      activeIndex: navState.activeTabIndex,
                      isDark: isDark,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.smart_toy_outlined,
                      activeIcon: Icons.smart_toy_rounded,
                      label: 'Coach',
                      index: 2,
                      activeIndex: navState.activeTabIndex,
                      isDark: isDark,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.menu_book_outlined,
                      activeIcon: Icons.menu_book_rounded,
                      label: 'Subjects',
                      index: 3,
                      activeIndex: navState.activeTabIndex,
                      isDark: isDark,
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.settings_outlined,
                      activeIcon: Icons.settings_rounded,
                      label: 'Settings',
                      index: 4,
                      activeIndex: navState.activeTabIndex,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const HomeDashboardPage(key: ValueKey('HomeTab'));
      case 1:
        return const StudyAnalyticsPage(key: ValueKey('AnalyticsTab'));
      case 2:
        return BlocBuilder<SubjectsBloc, SubjectsState>(
          builder: (context, state) {
            if (state.subjects.isEmpty) {
              return const CoachEmptyStatePage(key: ValueKey('CoachEmptyTab'));
            }
            return const CoachChatPage(key: ValueKey('CoachChatTab'));
          },
        );
      case 3:
        return const SubjectManagerPage(key: ValueKey('SubjectsTab'));
      case 4:
        return const SettingsPage(key: ValueKey('SettingsTab'));
      default:
        return const HomeDashboardPage(key: ValueKey('HomeTab'));
    }
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required int activeIndex,
    required bool isDark,
  }) {
    final isSelected = index == activeIndex;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          context.read<NavigationBloc>().add(SwitchDashboardTabEvent(index));
          if (index == 1) {
            final subjects = context.read<SubjectsBloc>().state.subjects;
            context.read<AnalyticsBloc>().add(LoadAnalyticsEvent(subjects));
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isSelected
                    ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08)
                    : Colors.transparent,
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 10,
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.primaryDark)
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
