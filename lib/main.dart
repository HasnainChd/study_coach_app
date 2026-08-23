import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/services/notification_service.dart';
import 'core/services/usage_limit_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_snackbar.dart';
import 'core/widgets/glass_card.dart';
import 'features/analytics/data/datasources/study_history_local_data_source.dart';
import 'features/analytics/data/repositories/study_history_repository_impl.dart';
import 'features/analytics/domain/repositories/study_history_repository.dart';
import 'features/analytics/presentation/bloc/analytics_bloc.dart';
import 'features/bloc/chat_bloc.dart';
import 'features/bloc/navigation_bloc.dart';
import 'features/bloc/subjects_bloc.dart';
import 'features/bloc/theme_bloc.dart';
import 'features/bloc/timer_bloc.dart';
import 'features/chat/data/datasources/chat_local_data_source.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/domain/repositories/chat_repository.dart';
import 'features/dashboard/presentation/pages/dashboard_shell.dart';
import 'features/focus/data/datasources/timer_local_data_source.dart';
import 'features/focus/presentation/pages/focus_timer_page.dart';
import 'features/onboarding/presentation/pages/add_subjects_page.dart';
import 'features/onboarding/presentation/pages/daily_schedule_page.dart';
import 'features/onboarding/presentation/pages/welcome_page.dart';
import 'features/subjects/data/datasources/subject_local_data_source.dart';
import 'features/subjects/data/repositories/subject_repository_impl.dart';

import 'features/subjects/domain/repositories/subject_repository.dart';
import 'features/subjects/domain/usecases/add_subject_usecase.dart';
import 'features/subjects/domain/usecases/generate_study_plan_usecase.dart';
import 'features/subjects/domain/usecases/get_subjects_usecase.dart';
import 'features/subjects/domain/usecases/remove_subject_usecase.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();

  // Main app data box (subjects, agenda, settings, gamification)
  final box = await Hive.openBox('study_coach_box');

  // Dedicated box for chat message history
  final chatBox = await Hive.openBox('chat_messages_box');

  // Dedicated box for completed-task study history (analytics)
  final studyHistoryBox = await Hive.openBox('study_history_box');

  // Dedicated box for usage limit tracking
  final usageLimitsBox = await Hive.openBox('usage_limits');
  final usageLimitService = UsageLimitService(usageLimitsBox);

  // Initialize notifications service
  final notificationService = NotificationService();
  await notificationService.init();

  final localDataSource = SubjectLocalDataSourceImpl(box);
  final timerLocalDataSource = TimerLocalDataSourceImpl(box);
  final repository = SubjectRepositoryImpl(localDataSource);

  // Chat persistence layer
  final chatLocalDataSource = ChatLocalDataSourceImpl(chatBox);
  final chatRepository = ChatRepositoryImpl(chatLocalDataSource);

  final studyHistoryLocalDataSource =
      StudyHistoryLocalDataSourceImpl(studyHistoryBox);
  final studyHistoryRepository =
      StudyHistoryRepositoryImpl(studyHistoryLocalDataSource);

  // Read onboarding complete flag
  final hasCompletedOnboarding = await repository.getHasCompletedOnboarding();
  final initialScreen =
      hasCompletedOnboarding ? AppScreen.dashboard : AppScreen.welcome;

  runApp(MyApp(
    hiveBox: box,
    repository: repository,
    chatRepository: chatRepository,
    studyHistoryRepository: studyHistoryRepository,
    timerLocalDataSource: timerLocalDataSource,
    initialScreen: initialScreen,
    usageLimitService: usageLimitService,
  ));
}


class MyApp extends StatelessWidget {
  final Box hiveBox;
  final SubjectRepository repository;
  final ChatRepository chatRepository;
  final StudyHistoryRepository studyHistoryRepository;
  final TimerLocalDataSource timerLocalDataSource;
  final AppScreen initialScreen;
  final UsageLimitService usageLimitService;

  const MyApp({
    super.key,
    required this.hiveBox,
    required this.repository,
    required this.chatRepository,
    required this.studyHistoryRepository,
    required this.timerLocalDataSource,
    required this.initialScreen,
    required this.usageLimitService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(create: (context) => ThemeBloc(hiveBox)),
        BlocProvider<NavigationBloc>(
          create: (context) => NavigationBloc(initialScreen: initialScreen),
        ),
        BlocProvider<SubjectsBloc>(
          create: (context) => SubjectsBloc(
            repository: repository,
            getSubjectsUseCase: GetSubjectsUseCase(repository),
            addSubjectUseCase: AddSubjectUseCase(repository),
            removeSubjectUseCase: RemoveSubjectUseCase(repository),
            generateStudyPlanUseCase: GenerateStudyPlanUseCase(repository),
            studyHistoryRepository: studyHistoryRepository,
            usageLimitService: usageLimitService,
          )..add(LoadSubjectsEvent()),
        ),
        BlocProvider<AnalyticsBloc>(
          create: (context) => AnalyticsBloc(
            studyHistoryRepository: studyHistoryRepository,
          ),
        ),
        BlocProvider<TimerBloc>(
          create: (context) => TimerBloc(timerDataSource: timerLocalDataSource),
        ),
        // ChatBloc reads the current SubjectsBloc state so it can build a
        // context-aware system prompt using real subjects / agenda / gamification.
        BlocProvider<ChatBloc>(
          create: (context) => ChatBloc(
            chatRepository: chatRepository,
            initialSubjectsState: context.read<SubjectsBloc>().state,
            initialTimerState: context.read<TimerBloc>().state,
            usageLimitService: usageLimitService,
          ),
        ),
      ],

      child: BlocBuilder<ThemeBloc, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'Study Coach AI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: Scaffold(
              body: BlocListener<SubjectsBloc, SubjectsState>(
                listenWhen: (previous, current) =>
                    !previous.showNotificationPermissionWarning &&
                    current.showNotificationPermissionWarning,
                listener: (context, state) {
                  AppSnackbar.show(
                    context,
                    type: SnackbarType.warning,
                    title: 'Notifications disabled',
                    message:
                        'Notifications are disabled in system settings. '
                        'Enable them to receive reminders.',
                  );
                  context.read<SubjectsBloc>().add(
                        ClearNotificationPermissionWarningEvent(),
                      );
                },
                child: BlocListener<TimerBloc, TimerState>(
                  listenWhen: (previous, current) =>
                      previous.pendingStartEvent != current.pendingStartEvent &&
                      current.pendingStartEvent != null,
                  listener: (context, state) {
                    _showActiveSessionConflictDialog(context, state);
                  },
                  child: BlocListener<NavigationBloc, NavigationState>(
                    listener: (context, navState) {
                      if (navState.currentScreen == AppScreen.focusTimer) {
                        context.read<TimerBloc>().add(SyncTimerEvent());
                      }
                    },
                    child: BlocBuilder<NavigationBloc, NavigationState>(
                      builder: (context, navState) {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            final slideAnimation = Tween<Offset>(
                              begin: const Offset(0.05, 0.0),
                              end: Offset.zero,
                            ).animate(animation);

                            return SlideTransition(
                              position: slideAnimation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: _buildScreen(navState.currentScreen),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showActiveSessionConflictDialog(
      BuildContext context, TimerState state) {
    final pending = state.pendingStartEvent;
    if (pending == null) return;

    final activeTaskTitle =
        state.taskTitle ?? state.subjectName ?? 'Active Session';
    final elapsedSecs =
        (state.totalSeconds - state.remainingSeconds).clamp(0, state.totalSeconds);
    final elapsedFormatted = _formatElapsed(elapsedSecs);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Discard Active Session?',
                        style: AppTextStyles.headingSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'You have an active session for "$activeTaskTitle" ($elapsedFormatted elapsed). Starting a new session will discard this progress. Discard and start new session?',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        context
                            .read<TimerBloc>()
                            .add(ClearPendingStartEvent());
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        context
                            .read<TimerBloc>()
                            .add(ClearPendingStartEvent());
                        context.read<TimerBloc>().add(StartTimerEvent(
                              taskId: pending.taskId,
                              durationSeconds: pending.durationSeconds,
                              taskTitle: pending.taskTitle,
                              subjectName: pending.subjectName,
                              subjectColor: pending.subjectColor,
                              isRunning: pending.isRunning,
                              force: true,
                            ));
                        context.read<NavigationBloc>().add(
                              NavigateToScreenEvent(AppScreen.focusTimer),
                            );
                      },
                      child: const Text(
                        'Discard & Start',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatElapsed(int elapsedSeconds) {
    final mins = elapsedSeconds ~/ 60;
    final secs = elapsedSeconds % 60;
    if (mins > 0) {
      return '$mins min ${secs > 0 ? '$secs sec' : ''}';
    } else {
      return '$secs sec';
    }
  }

  Widget _buildScreen(AppScreen screen) {
    switch (screen) {
      case AppScreen.welcome:
        return WelcomePage(
          key: ValueKey('WelcomePage'),
        );
      case AppScreen.addSubjects:
        return const AddSubjectsPage(
          key: ValueKey('AddSubjectsPage'),
        );
      case AppScreen.dailySchedule:
        return const DailySchedulePage(
          key: ValueKey('DailySchedulePage'),
        );
      case AppScreen.dashboard:
        return const DashboardShell(
          key: ValueKey('DashboardShell'),
        );
      case AppScreen.focusTimer:
        return const FocusTimerPage(
          key: ValueKey('FocusTimerPage'),
        );
    }
  }
}
