import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../bloc/navigation_bloc.dart';
import '../../../bloc/subjects_bloc.dart';
import '../../../bloc/theme_bloc.dart';
import '../../../bloc/timer_bloc.dart';

class HomeDashboardPage extends StatelessWidget {
  const HomeDashboardPage({super.key});

  static final ValueNotifier<String?> userNameNotifier =
      ValueNotifier<String?>(null);

  static void loadName() {
    if (userNameNotifier.value == null) {
      SharedPreferences.getInstance().then((prefs) {
        final name = prefs.getString('userName');
        if (name != null) {
          userNameNotifier.value = name;
        }
      });
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY'
    ];
    final months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER'
    ];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else if (hour >= 17 && hour < 22) {
      return 'Good evening';
    } else {
      return 'Good night';
    }
  }

  void _showStreakDetailsBottomSheet(
      BuildContext context, bool isDark, SubjectsState state) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1 = Monday, 7 = Sunday
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        return BlocBuilder<SubjectsBloc, SubjectsState>(
          bloc: context.read<SubjectsBloc>(),
          builder: (context, state) {
            final todayClaimed = state.lastStreakClaimedDate == today;
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151433) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pull Handle
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Flame Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFECE5),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFFF5100),
                        size: 44,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Streak Title
                  Text(
                    '${state.streak} Day Study Streak!',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Level ${state.level} Scholar • ${(state.xpProgress * 100).toInt()}% towards Level ${state.level + 1}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.subjectGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Weekly checkmarks
                  Text(
                    'THIS WEEK\'S PROGRESS',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      final dayNum = index + 1; // 1 = Monday
                      final isPastOrToday = dayNum <= currentWeekday;
                      final isToday = dayNum == currentWeekday;
                      final isChecked =
                          isPastOrToday && (!isToday || todayClaimed);

                      return Column(
                        children: [
                          Text(
                            weekdays[index],
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isToday
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                              fontWeight:
                                  isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isChecked
                                  ? AppColors.subjectGreen
                                      .withValues(alpha: 0.15)
                                  : (isToday
                                      ? AppColors.primary.withValues(alpha: 0.1)
                                      : Colors.transparent),
                              border: Border.all(
                                color: isChecked
                                    ? AppColors.subjectGreen
                                    : (isToday
                                        ? AppColors.primary
                                        : (isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder)),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              isChecked
                                  ? Icons.check_rounded
                                  : (isToday ? Icons.schedule_rounded : null),
                              color: isChecked
                                  ? AppColors.subjectGreen
                                  : AppColors.primary,
                              size: 18,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: 28),

                  // Claim Button
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      text: todayClaimed
                          ? 'Streak Claimed Today!'
                          : 'Claim Today\'s Streak',
                      isLoading: false,
                      onPressed: () {
                        if (todayClaimed) return;
                        context.read<SubjectsBloc>().add(ClaimStreakEvent());
                        AppSnackbar.show(
                          context,
                          type: SnackbarType.success,
                          title: 'Streak Claimed! 🎉',
                          message: 'Awesome job keeping it up!',
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Motivational Tip Box
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBorder.withValues(alpha: 0.3)
                          : AppColors.lightBorder.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: Colors.amber,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '“Consistent daily study beats long weekend cramming. Keep the fire burning!”',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              fontStyle: FontStyle.italic,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    loadName();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: BlocListener<SubjectsBloc, SubjectsState>(
        listenWhen: (previous, current) =>
            previous.status == SubjectsStatus.planGenerating &&
            current.status == SubjectsStatus.planGenerated,
        listener: (context, state) {
          AppSnackbar.show(
            context,
            type: SnackbarType.success,
            title: "Plan Ready!",
            message: "Your study schedule has been generated.",
          );
        },
        child: GradientBackground(
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
                        _getFormattedDate(),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ValueListenableBuilder<String?>(
                        valueListenable: HomeDashboardPage.userNameNotifier,
                        builder: (context, name, _) {
                          final prefix = _getTimeBasedGreeting();
                          final greeting = name != null && name.isNotEmpty
                              ? '$prefix, $name'
                              : '$prefix 👋';
                          return Text(
                            greeting,
                            style: AppTextStyles.headingMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Dark/Light toggle
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                        width: 1.5,
                      ),
                      color:
                          isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        color:
                            isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                      onPressed: () {
                        context.read<ThemeBloc>().add(ToggleThemeEvent());
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Streak Card wrapped in BlocBuilder for real-time reactivity
              BlocBuilder<SubjectsBloc, SubjectsState>(
                builder: (context, state) {
                  return GestureDetector(
                    onTap: () {
                      _showStreakDetailsBottomSheet(context, isDark, state);
                    },
                    child: GlassCard(
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
                                  color: const Color(0xFFFF8551)
                                      .withValues(alpha: 0.2),
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
                                  '${state.streak} Day Streak',
                                  style: AppTextStyles.headingSmall.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Level ${state.level} Scholar',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.subjectGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // XP progress indicators
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'XP PROGRESS',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                        fontSize: 10,
                                      ),
                                    ),
                                    Text(
                                      '${(state.xpProgress * 100).toInt()}%',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: state.xpProgress,
                                    backgroundColor: AppColors.darkBorder,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            AppColors.primary),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Today's Agenda header
              Text(
                "Today's Agenda",
                style: AppTextStyles.headingSmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
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
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCardBg
                                : AppColors.lightCardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: item.isCompleted
                                  ? AppColors.subjectGreen
                                      .withValues(alpha: 0.4)
                                  : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Checkbox Circle (wrapped in GestureDetector to toggle checklist state)
                              GestureDetector(
                                onTap: () {
                                  context.read<SubjectsBloc>().add(
                                        ToggleAgendaItemEvent(item.id),
                                      );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Icon(
                                    item.isCompleted
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    color: item.isCompleted
                                        ? AppColors.subjectGreen
                                        : (isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary),
                                    size: 24,
                                  ),
                                ),
                              ),
                              // Rest of Card Details (wrapped in GestureDetector to launch Custom Duration Timer)
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: item.isCompleted
                                      ? null
                                      : () {
                                          // 1. Set specific countdown duration matching card minutes and start ticking
                                          context.read<TimerBloc>().add(
                                                StartTimerEvent(
                                                  durationSeconds:
                                                      item.durationMinutes * 60,
                                                  taskTitle: item.title,
                                                  subjectName: item.tag,
                                                  subjectColor: item.tagColor,
                                                ),
                                              );
                                          // 2. Transition screen navigation
                                          context.read<NavigationBloc>().add(
                                                NavigateToScreenEvent(
                                                    AppScreen.focusTimer),
                                              );
                                        },
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 16.0, bottom: 16.0, right: 16.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                style: AppTextStyles.bodyMedium
                                                    .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: item.isCompleted
                                                      ? (isDark
                                                          ? AppColors
                                                              .darkTextSecondary
                                                              .withValues(
                                                                  alpha: 0.6)
                                                          : AppColors
                                                              .lightTextSecondary
                                                              .withValues(
                                                                  alpha: 0.6))
                                                      : (isDark
                                                          ? AppColors
                                                              .darkTextPrimary
                                                          : AppColors
                                                              .lightTextPrimary),
                                                  decoration: item.isCompleted
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: item.tagColor
                                                          .withValues(
                                                              alpha: 0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: Text(
                                                      item.tag,
                                                      style: AppTextStyles
                                                          .bodySmall
                                                          .copyWith(
                                                        color: item.tagColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Icon(
                                                    Icons.schedule_rounded,
                                                    size: 14,
                                                    color: isDark
                                                        ? AppColors
                                                            .darkTextSecondary
                                                        : AppColors
                                                            .lightTextSecondary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${item.durationMinutes} min',
                                                    style: AppTextStyles
                                                        .bodySmall
                                                        .copyWith(
                                                      color: isDark
                                                          ? AppColors
                                                              .darkTextSecondary
                                                          : AppColors
                                                              .lightTextSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (!item.isCompleted)
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Quick Start Session Button
              BlocBuilder<SubjectsBloc, SubjectsState>(
                builder: (context, state) {
                  final uncompletedItems = state.agendaItems
                      .where((item) => !item.isCompleted)
                      .toList();

                  final allCompleted =
                      state.agendaItems.isNotEmpty && uncompletedItems.isEmpty;

                  if (allCompleted) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.subjectGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.subjectGreen.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.subjectGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'All done for today! Great work 🎉',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.subjectGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  int focusMinutes = 25;
                  if (uncompletedItems.isNotEmpty) {
                    focusMinutes = uncompletedItems.first.durationMinutes;
                  } else if (state.agendaItems.isNotEmpty) {
                    focusMinutes = state.agendaItems.first.durationMinutes;
                  } else {
                    focusMinutes = state.settings.pomodoroFocus;
                  }

                  final activeItem = uncompletedItems.isNotEmpty
                      ? uncompletedItems.first
                      : (state.agendaItems.isNotEmpty
                          ? state.agendaItems.first
                          : null);

                  return PrimaryButton(
                    text: 'Quick Start Session ($focusMinutes min)',
                    icon: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      // Start focus timer matching active card duration
                      context.read<TimerBloc>().add(
                            StartTimerEvent(
                              durationSeconds: focusMinutes * 60,
                              taskTitle: activeItem?.title,
                              subjectName: activeItem?.tag,
                              subjectColor: activeItem?.tagColor,
                            ),
                          );
                      // Navigate to Focus Timer Page
                      context.read<NavigationBloc>().add(
                            NavigateToScreenEvent(AppScreen.focusTimer),
                          );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
