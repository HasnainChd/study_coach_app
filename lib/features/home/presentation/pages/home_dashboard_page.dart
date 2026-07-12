import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../bloc/navigation_bloc.dart';
import '../../../bloc/subjects_bloc.dart';
import '../../../bloc/theme_bloc.dart';
import '../../../bloc/timer_bloc.dart';

class HomeDashboardPage extends StatelessWidget {
  const HomeDashboardPage({super.key});

  static final ValueNotifier<String?> userNameNotifier =
      ValueNotifier<String?>(null);
  static final ValueNotifier<int?> levelUpNotifier =
      ValueNotifier<int?>(null);
  static int? _lastLevel;

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
                  const SizedBox(height: 20),

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
                  const SizedBox(height: 20),

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
                  const SizedBox(height: 12),                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      final dayNum = index + 1; // 1 = Monday
                      final isToday = dayNum == currentWeekday;
                      
                      bool isChecked = false;
                      if (state.streak > 0 && state.lastStreakClaimedDate.isNotEmpty) {
                        try {
                          final lastClaimed = DateTime.parse(state.lastStreakClaimedDate);
                          final daysDiff = dayNum - currentWeekday;
                          final dayDate = now.add(Duration(days: daysDiff));
                          
                          final dayDateNormalized = DateTime(dayDate.year, dayDate.month, dayDate.day);
                          final lastClaimedNormalized = DateTime(lastClaimed.year, lastClaimed.month, lastClaimed.day);
                          
                          final diffInDays = lastClaimedNormalized.difference(dayDateNormalized).inDays;
                          
                          if (diffInDays >= 0 && diffInDays < state.streak) {
                            isChecked = true;
                          }
                        } catch (_) {}
                      }

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
            (previous.status == SubjectsStatus.planGenerating &&
                current.status == SubjectsStatus.planGenerated) ||
            (previous.status == SubjectsStatus.success &&
                previous.level < current.level) ||
            (!previous.streakResetTriggered && current.streakResetTriggered),
        listener: (context, state) {
          if (state.status == SubjectsStatus.planGenerated) {
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
              title: "Plan Ready!",
              message: "Your study schedule has been generated.",
            );
          }

          if (_lastLevel != null && state.level > _lastLevel!) {
            levelUpNotifier.value = state.level;
            Future.delayed(const Duration(seconds: 2), () {
              levelUpNotifier.value = null;
            });
          }
          _lastLevel = state.level;

          if (state.streakResetTriggered) {
            AppSnackbar.show(
              context,
              type: SnackbarType.warning,
              title: 'Streak Reset',
              message: 'Your streak was reset. Start a new one today!',
            );
          }
        },
        child: Stack(
          children: [
            GradientBackground(
              child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                            if (name == null || name.isEmpty) {
                              return Text(
                                '$prefix 👋',
                                style: AppTextStyles.headingMedium.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              );
                            } else if (name.length <= 9) {
                              return Text(
                                '$prefix, $name',
                                style: AppTextStyles.headingMedium.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              );
                            } else {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$prefix,',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              );
                            }
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
                        color: isDark
                            ? AppColors.darkCardBg
                            : AppColors.lightCardBg,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          color: isDark
                              ? Colors.white
                              : AppColors.lightTextPrimary,
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
                                        style:
                                            AppTextStyles.labelSmall.copyWith(
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        '${(state.xpProgress * 100).toInt()}%',
                                        style:
                                            AppTextStyles.labelSmall.copyWith(
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
                const SizedBox(height: 24),

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
                      if (state.subjects.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  color: isDark ? Colors.white30 : Colors.black26,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Subjects Added',
                                  style: AppTextStyles.headingSmall.copyWith(
                                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add your subjects first to generate a personalized daily study plan!',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    context.read<NavigationBloc>().add(SwitchDashboardTabEvent(3));
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                                  label: const Text('Go to Subjects'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
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
                                          : Icons
                                              .radio_button_unchecked_rounded,
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
                                            context.read<TimerBloc>().add(
                                                  StartTimerEvent(
                                                    taskId: item.id,
                                                    durationSeconds:
                                                        item.durationMinutes *
                                                            60,
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
                                                  style: AppTextStyles
                                                      .bodyMedium
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
                                                    (() {
                                                      final matchedSubject = state.subjects.firstWhere(
                                                        (s) => s.name.toLowerCase() == item.tag.toLowerCase(),
                                                        orElse: () => Subject(id: '', name: '', color: Colors.transparent),
                                                      );
                                                      bool showRedChip = false;
                                                      if (matchedSubject.id.isNotEmpty && matchedSubject.examDate != null) {
                                                        final today = DateTime(
                                                          DateTime.now().year,
                                                          DateTime.now().month,
                                                          DateTime.now().day,
                                                        );
                                                        final examDay = DateTime(
                                                          matchedSubject.examDate!.year,
                                                          matchedSubject.examDate!.month,
                                                          matchedSubject.examDate!.day,
                                                        );
                                                        final daysUntilExam = examDay.difference(today).inDays;
                                                        if (daysUntilExam <= 7) {
                                                          showRedChip = true;
                                                        }
                                                      }
                                                      final displayColor = showRedChip ? const Color(0xFFFF4D6A) : item.tagColor;
                                                      return Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: displayColor.withValues(alpha: 0.12),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          item.tag,
                                                          style: AppTextStyles.bodySmall.copyWith(
                                                            color: displayColor,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                      );
                                                    })(),
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
                                                  : AppColors
                                                      .lightTextSecondary,
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
                const SizedBox(height: 20),

                // Quick Start Session Button
                BlocBuilder<SubjectsBloc, SubjectsState>(
                  builder: (context, state) {
                    final uncompletedItems = state.agendaItems
                        .where((item) => !item.isCompleted)
                        .toList();

                    final allCompleted = state.agendaItems.isNotEmpty &&
                        uncompletedItems.isEmpty;

                    if (allCompleted) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.subjectGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                AppColors.subjectGreen.withValues(alpha: 0.3),
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
                        context.read<TimerBloc>().add(
                              StartTimerEvent(
                                taskId: activeItem?.id,
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
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
        ValueListenableBuilder<int?>(
          valueListenable: HomeDashboardPage.levelUpNotifier,
          builder: (context, level, _) {
            if (level == null) return const SizedBox.shrink();
            return Positioned.fill(
              child: LevelUpOverlay(level: level),
            );
          },
        ),
      ],
    ),
  ),
);
  }
}

class LevelUpOverlay extends StatelessWidget {
  final int level;
  LevelUpOverlay({super.key, required this.level}) {
    Future.microtask(() {
      _opacityNotifier.value = 1.0;
    });
    Future.delayed(const Duration(milliseconds: 1700), () {
      _opacityNotifier.value = 0.0;
    });
  }

  final ValueNotifier<double> _opacityNotifier = ValueNotifier<double>(0.0);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _opacityNotifier,
      builder: (context, opacity, child) {
        return AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(milliseconds: 300),
          child: child,
        );
      },
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF151528),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.15),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.amber,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'LEVEL UP!',
                style: AppTextStyles.headingMedium.copyWith(
                  color: Colors.white,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Level $level Scholar! 🎉',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.subjectGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Keep up the amazing work!',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.darkTextSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
