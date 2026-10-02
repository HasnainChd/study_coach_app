import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/usage_limit_service.dart';
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
import '../../../../core/widgets/grade_hint_banner.dart';
import '../widgets/rewards_shop_modal.dart';
import '../widgets/streak_celebration_dialog.dart';

class HomeDashboardPage extends StatelessWidget {
  const HomeDashboardPage({super.key});

  static bool justCompletedOnboarding = false;
  static final ValueNotifier<String?> userNameNotifier =
      ValueNotifier<String?>(null);
  static final ValueNotifier<int?> levelUpNotifier = ValueNotifier<int?>(null);
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
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: 24 + MediaQuery.of(modalContext).padding.bottom,
              ),
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
                    state.streak == 0
                        ? 'Start Your Streak Today!'
                        : '${state.streak} Day Study Streak!',
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
                  const SizedBox(height: 12),

                  // Encouraging banner when streak is 0
                  if (state.streak == 0) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Text('🚀', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Start a new streak today! Every journey begins with a single step. Complete 1 study session to earn daily coins.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    // Multiplier Info Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD043).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFD043).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        state.streak >= 10
                            ? '🪙 2.0x Coins Multiplier Active (Day 10+)'
                            : (state.streak >= 5
                                ? '🪙 1.5x Coins Multiplier Active (Day 5-9)'
                                : '🪙 1.0x Base Multiplier (Reach 5 days for 1.5x!)'),
                        style: const TextStyle(
                          color: Color(0xFFFFD043),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

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
                      final isToday = dayNum == currentWeekday;

                      bool isChecked = false;
                      if (state.streak > 0 &&
                          state.lastStreakClaimedDate.isNotEmpty) {
                        try {
                          final lastClaimed =
                              DateTime.parse(state.lastStreakClaimedDate);
                          final daysDiff = dayNum - currentWeekday;
                          final dayDate = now.add(Duration(days: daysDiff));

                          final dayDateNormalized = DateTime(
                              dayDate.year, dayDate.month, dayDate.day);
                          final lastClaimedNormalized = DateTime(
                              lastClaimed.year,
                              lastClaimed.month,
                              lastClaimed.day);

                          final diffInDays = lastClaimedNormalized
                              .difference(dayDateNormalized)
                              .inDays;

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
                  const SizedBox(height: 16),
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
    if (justCompletedOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (justCompletedOnboarding) {
          justCompletedOnboarding = false;
          try {
            AnalyticsService.capture('onboarding_finished');
          } catch (_) {}
        }
      });
    }
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
        body: BlocListener<SubjectsBloc, SubjectsState>(
            listenWhen: (previous, current) =>
                (previous.status == SubjectsStatus.planGenerating &&
                    current.status == SubjectsStatus.planGenerated) ||
                (previous.status == SubjectsStatus.success &&
                    previous.level < current.level) ||
                (!previous.streakResetTriggered &&
                    current.streakResetTriggered) ||
                (previous.streakCelebrationMessage == null &&
                    current.streakCelebrationMessage != null),
            listener: (context, state) {
              if (state.streakCelebrationMessage != null &&
                  state.earnedCoinsLastAction != null) {
                StreakCelebrationDialog.show(
                  context,
                  streak: state.streak,
                  coinsEarned: state.earnedCoinsLastAction!,
                  message: state.streakCelebrationMessage!,
                  onDismiss: () {
                    context
                        .read<SubjectsBloc>()
                        .add(ClearStreakCelebrationEvent());
                  },
                );
              }
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
                  message: "Your new study plan is ready!",
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
                context.read<SubjectsBloc>().add(ClearStreakResetEvent());
              }
            },
            child: Container(
              color: isDark ? const Color(0xFF0F0E26) : const Color(0xFFF5F4FB),
              child: GradientBackground(
                child: CustomScrollView(
                  clipBehavior: Clip.hardEdge,
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      floating: false,
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      surfaceTintColor: Colors.transparent,
                      backgroundColor: isDark
                          ? const Color(0xFF0F0E26)
                          : const Color(0xFFF5F4FB),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          color: isDark
                              ? const Color(0xFF0F0E26)
                              : const Color(0xFFF5F4FB),
                        ),
                      ),
                      toolbarHeight: 76,
                      automaticallyImplyLeading: false,
                      titleSpacing: 16,
                      title: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
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
                                  valueListenable:
                                      HomeDashboardPage.userNameNotifier,
                                  builder: (context, name, _) {
                                    final prefix = _getTimeBasedGreeting();
                                    final text = (name == null || name.isEmpty)
                                        ? '$prefix 👋'
                                        : '$prefix, $name';
                                    return Text(
                                      text,
                                      style:
                                          AppTextStyles.headingMedium.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                      maxLines: 2,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Coins Pill Button
                          BlocBuilder<SubjectsBloc, SubjectsState>(
                            builder: (context, state) {
                              return GestureDetector(
                                  onTap: () => RewardsShopModal.show(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF222042)
                                          : const Color(0xFFFFF7E6),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFFFD043)
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text('🪙',
                                            style: TextStyle(fontSize: 14)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${state.coins}',
                                          style: const TextStyle(
                                            color: Color(0xFFFFD043),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ));
                            },
                          ),
                          const SizedBox(width: 8),
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
                                context
                                    .read<ThemeBloc>()
                                    .add(ToggleThemeEvent());
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ClipRect(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Bento Grid & Quick Start wrapped in BlocBuilder for real-time reactivity
                              BlocBuilder<SubjectsBloc, SubjectsState>(
                                builder: (context, state) {
                                  return Column(
                                    children: [
                                      GradeHintBanner(
                                        gradeLevel: state.settings.gradeLevel,
                                        isDark: isDark,
                                        onTapSetGrade: () {
                                          context
                                              .read<NavigationBloc>()
                                              .add(SwitchDashboardTabEvent(4));
                                        },
                                      ),
                                      BlocBuilder<TimerBloc, TimerState>(
                                        builder: (context, timerState) {
                                          return Column(
                                            children: [
                                              _buildBentoGrid(context, isDark, state),
                                              const SizedBox(height: 12),
                                              _buildQuickStartButton(
                                                  context, isDark, state, timerState),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 14),

                              // Active Session Indicator (if active)
                              BlocBuilder<TimerBloc, TimerState>(
                                builder: (context, timerState) {
                                  final isActive = timerState.status ==
                                          TimerStatus.running ||
                                      timerState.status == TimerStatus.paused ||
                                      timerState.status == TimerStatus.onBreak;

                                  if (!isActive) {
                                    return const SizedBox.shrink();
                                  }

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _ActiveTimerSessionCard(
                                        timerState: timerState,
                                        isDark: isDark,
                                      ),
                                      const SizedBox(height: 14),
                                    ],
                                  );
                                },
                              ),

                              // Today's Agenda header
                              Text(
                                "Today's Agenda",
                                style: AppTextStyles.headingSmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildAgendaSlivers(context, isDark),
                  ],
                ),
              ),
            )));
  }

  Widget _buildAgendaSlivers(BuildContext context, bool isDark) {
    return BlocBuilder<SubjectsBloc, SubjectsState>(
      builder: (context, state) {
        if (state.subjects.isEmpty) {
          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverToBoxAdapter(
              child: Center(
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
                          color: isDark
                              ? Colors.white
                              : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your subjects first to generate a personalized daily study plan!',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          context
                              .read<NavigationBloc>()
                              .add(SwitchDashboardTabEvent(3));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
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
              ),
            ),
          );
        }
        final items = state.agendaItems;
        if (items.isEmpty) {
          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverToBoxAdapter(
              child: FutureBuilder<bool>(
                future: context
                    .read<SubjectsBloc>()
                    .usageLimitService
                    .canPerformAction(UsageType.planRegenerate),
                builder: (context, snapshot) {
                  final limitReached = snapshot.hasData && !snapshot.data!;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              limitReached
                                  ? Icons.lock_clock_rounded
                                  : Icons.calendar_today_rounded,
                              color: isDark ? Colors.white30 : Colors.black26,
                              size: 56,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              limitReached
                                  ? 'Daily Limit Reached'
                                  : 'No Plan Generated Yet',
                              style: AppTextStyles.headingSmall.copyWith(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              limitReached
                                  ? 'Daily plan limit reached — try again tomorrow.'
                                  : 'No plan generated yet — go to Settings to create one.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                fontSize: 14,
                              ),
                            ),
                            if (!limitReached) ...[
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  context
                                      .read<NavigationBloc>()
                                      .add(SwitchDashboardTabEvent(4));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.settings_rounded,
                                    size: 18),
                                label: const Text('Go to Settings'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }

        final uncompletedItems =
            items.where((item) => !item.isCompleted).toList();
        final nextIncompleteId =
            uncompletedItems.isNotEmpty ? uncompletedItems.first.id : null;

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) {
              final currentItem = items[index];
              final nextItem = items[index + 1];

              final isSameSubject = currentItem.tag.toLowerCase().trim() ==
                  nextItem.tag.toLowerCase().trim();

              final cleanTitleCurrent = currentItem.title
                  .replaceAll(RegExp(r'\s*\(Part \d+\)$'), '')
                  .toLowerCase()
                  .trim();
              final cleanTitleNext = nextItem.title
                  .replaceAll(RegExp(r'\s*\(Part \d+\)$'), '')
                  .toLowerCase()
                  .trim();
              final isSameTopic = cleanTitleCurrent == cleanTitleNext;

              if (isSameSubject || isSameTopic) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFFFF9800).withValues(alpha: 0.14)
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              const Color(0xFFFF9800).withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.free_breakfast_rounded,
                            size: 16,
                            color: Color(0xFFFF9800),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Short break suggested (5 min) — rest before continuing',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFFFFB74D)
                                    : const Color(0xFFE65100),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                );
              }

              return const SizedBox(height: 10);
            },
            itemBuilder: (context, index) {
              final item = items[index];
              final isNextTask =
                  !item.isCompleted && item.id == nextIncompleteId;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: item.isCompleted
                        ? AppColors.subjectGreen.withValues(alpha: 0.4)
                        : (isNextTask
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder)),
                    width: isNextTask ? 1.8 : 1.2,
                  ),
                  boxShadow: isNextTask
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.18),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        final timerState = context.read<TimerBloc>().state;
                        if ((timerState.status == TimerStatus.running ||
                                timerState.status == TimerStatus.paused) &&
                            timerState.taskId == item.id) {
                          context.read<TimerBloc>().add(ResetTimerEvent());
                        }
                        context.read<SubjectsBloc>().add(
                              ToggleAgendaItemEvent(item.id),
                            );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 12.0),
                        child: Icon(
                          item.isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: item.isCompleted
                              ? AppColors.subjectGreen
                              : (isNextTask
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary)),
                          size: 22,
                        ),
                      ),
                    ),
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
                                            item.durationMinutes * 60,
                                        taskTitle: item.title,
                                        subjectName: item.tag,
                                        subjectColor: item.tagColor,
                                      ),
                                    );
                                context.read<NavigationBloc>().add(
                                      NavigateToScreenEvent(
                                          AppScreen.focusTimer),
                                    );
                              },
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 10.0, bottom: 10.0, right: 12.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: item.isCompleted
                                            ? (isDark
                                                ? AppColors.darkTextSecondary
                                                    .withValues(alpha: 0.6)
                                                : AppColors.lightTextSecondary
                                                    .withValues(alpha: 0.6))
                                            : (isDark
                                                ? AppColors.darkTextPrimary
                                                : AppColors.lightTextPrimary),
                                        decoration: item.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        (() {
                                          final matchedSubject =
                                              state.subjects.firstWhere(
                                            (s) =>
                                                s.name.toLowerCase() ==
                                                item.tag.toLowerCase(),
                                            orElse: () => Subject(
                                                id: '',
                                                name: '',
                                                color: Colors.transparent),
                                          );
                                          bool showRedChip = false;
                                          if (matchedSubject.id.isNotEmpty &&
                                              matchedSubject.examDate != null) {
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
                                            final daysUntilExam = examDay
                                                .difference(today)
                                                .inDays;
                                            if (daysUntilExam <= 7) {
                                              showRedChip = true;
                                            }
                                          }
                                          final displayColor = showRedChip
                                              ? const Color(0xFFFF4D6A)
                                              : item.tagColor;
                                          return Flexible(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: displayColor.withValues(
                                                    alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                item.tag,
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                  color: displayColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          );
                                        })(),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.schedule_rounded,
                                          size: 13,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${item.durationMinutes} min',
                                          style:
                                              AppTextStyles.bodySmall.copyWith(
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary,
                                            fontSize: 11,
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
                                  size: 20,
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
          ),
        );
      },
    );
  }

  Widget _buildBentoGrid(
      BuildContext context, bool isDark, SubjectsState state) {
    final uncompleted = state.agendaItems.where((item) => !item.isCompleted);
    final remainingMinutes = uncompleted.fold<int>(
      0,
      (sum, item) => sum + item.durationMinutes,
    );

    final completedCount =
        state.agendaItems.where((item) => item.isCompleted).length;
    final totalCount = state.agendaItems.length;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Card: Merged Streak + Level + XP Progress (55% width)
          Expanded(
            flex: 55,
            child: GestureDetector(
              onTap: () {
                _showStreakDetailsBottomSheet(context, isDark, state);
              },
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFECE5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8551)
                                    .withValues(alpha: 0.2),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.local_fire_department_rounded,
                              color: Color(0xFFFF5100),
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.streak == 0
                                    ? '0 Day Streak'
                                    : '${state.streak} Day Streak',
                                style: AppTextStyles.headingSmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Lvl ${state.level} Scholar',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.subjectGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'XP PROGRESS',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${(state.xpProgress * 100).toInt()}%',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: state.xpProgress,
                            backgroundColor:
                                isDark ? AppColors.darkBorder : Colors.black12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                            minHeight: 5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Right Column: Stacked 2 smaller cards (45% width)
          Expanded(
            flex: 45,
            child: Column(
              children: [
                // Top Card: Remaining Study Time
                Expanded(
                  child: GlassCard(
                    borderRadius: 14,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.schedule_rounded,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'REMAINING',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '$remainingMinutes min left',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Bottom Card: Tasks Completed
                Expanded(
                  child: GlassCard(
                    borderRadius: 14,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color:
                                AppColors.subjectGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.task_alt_rounded,
                            color: AppColors.subjectGreen,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'COMPLETED',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '$completedCount of $totalCount done',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartButton(BuildContext context, bool isDark,
      SubjectsState state, TimerState timerState) {
    final isSessionActive = timerState.status == TimerStatus.running ||
        timerState.status == TimerStatus.paused ||
        timerState.status == TimerStatus.onBreak;

    if (isSessionActive) {
      final isPaused = timerState.status == TimerStatus.paused;
      final buttonText = isPaused ? 'Resume Session' : 'Resume Active Session';
      final buttonIcon = isPaused
          ? const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 24,
            )
          : const Icon(
              Icons.timer_outlined,
              color: Colors.white,
              size: 22,
            );

      return PrimaryButton(
        text: buttonText,
        icon: buttonIcon,
        onPressed: () {
          if (isPaused) {
            context.read<TimerBloc>().add(StartTimerEvent());
          }
          context.read<NavigationBloc>().add(
                NavigateToScreenEvent(AppScreen.focusTimer),
              );
        },
      );
    }

    final uncompletedItems =
        state.agendaItems.where((item) => !item.isCompleted).toList();

    final allCompleted =
        state.agendaItems.isNotEmpty && uncompletedItems.isEmpty;

    if (allCompleted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
            Flexible(
              child: Text(
                'All done for today! Great work 🎉',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.subjectGreen,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
        : (state.agendaItems.isNotEmpty ? state.agendaItems.first : null);

    final showDivider = state.agendaItems.isEmpty;

    final button = PrimaryButton(
      text: 'Quick Start Session ($focusMinutes min)',
      icon: const Icon(
        Icons.play_arrow_rounded,
        color: Colors.white,
        size: 24,
      ),
      onPressed: () {
        try {
          AnalyticsService.capture('session_started');
        } catch (_) {}
        context.read<TimerBloc>().add(
              StartTimerEvent(
                taskId: activeItem?.id,
                durationSeconds: focusMinutes * 60,
                taskTitle: activeItem?.title,
                subjectName: activeItem?.tag,
                subjectColor: activeItem?.tagColor,
              ),
            );
        context.read<NavigationBloc>().add(
              NavigateToScreenEvent(AppScreen.focusTimer),
            );
      },
    );

    if (showDivider) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  thickness: 1.2,
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Or start a quick session without a plan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  thickness: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          button,
        ],
      );
    }

    return button;
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

class _ActiveTimerSessionCard extends StatelessWidget {
  final TimerState timerState;
  final bool isDark;

  const _ActiveTimerSessionCard({
    required this.timerState,
    required this.isDark,
  });

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isPaused = timerState.status == TimerStatus.paused;
    final isBreak = timerState.isBreakTime;
    final title = isBreak
        ? 'Active Break'
        : (timerState.taskTitle ?? timerState.subjectName ?? 'Focus Session');
    final subtitle = isBreak
        ? 'Take a breather'
        : (timerState.subjectName ?? 'Timer Session');
    final subjectColor = timerState.subjectColor ?? AppColors.primary;

    return GestureDetector(
      onTap: () {
        context.read<NavigationBloc>().add(
              NavigateToScreenEvent(AppScreen.focusTimer),
            );
      },
      child: GlassCard(
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isBreak
                    ? const Color(0xFFE5F6FF)
                    : (isPaused
                        ? const Color(0xFFFFF7E5)
                        : subjectColor.withValues(alpha: 0.15)),
              ),
              child: Center(
                child: Icon(
                  isBreak
                      ? Icons.coffee_rounded
                      : (isPaused
                          ? Icons.pause_circle_rounded
                          : Icons.timer_outlined),
                  color: isBreak
                      ? Colors.lightBlue
                      : (isPaused ? Colors.orange : subjectColor),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPaused
                              ? Colors.orange
                              : (isBreak ? Colors.lightBlue : Colors.green),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isPaused
                            ? 'PAUSED'
                            : (isBreak ? 'BREAK TIME' : 'FOCUSING NOW'),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isPaused
                              ? Colors.orange
                              : (isBreak ? Colors.lightBlue : Colors.green),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(timerState.remainingSeconds),
                  style: AppTextStyles.headingMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontSize: 18,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    timerState.isRunning
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: AppColors.primary,
                    size: 30,
                  ),
                  onPressed: () {
                    if (timerState.isRunning) {
                      context.read<TimerBloc>().add(PauseTimerEvent());
                    } else {
                      context.read<TimerBloc>().add(StartTimerEvent());
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
