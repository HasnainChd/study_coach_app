import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/services/notification_service.dart';
import 'core/services/usage_limit_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_snackbar.dart';
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
          );
        },
      ),
    );
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
