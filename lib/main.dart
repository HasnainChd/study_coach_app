import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/bloc/chat_bloc.dart';
import 'features/bloc/navigation_bloc.dart';
import 'features/bloc/subjects_bloc.dart';
import 'features/bloc/theme_bloc.dart';
import 'features/bloc/timer_bloc.dart';
import 'features/dashboard/presentation/pages/dashboard_shell.dart';
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
  final box = await Hive.openBox('study_coach_box');

  // Initialize notifications service
  final notificationService = NotificationService();
  await notificationService.init();

  final localDataSource = SubjectLocalDataSourceImpl(box);
  final repository = SubjectRepositoryImpl(localDataSource);

  // Read onboarding complete flag
  final hasCompletedOnboarding = await repository.getHasCompletedOnboarding();
  final initialScreen =
      hasCompletedOnboarding ? AppScreen.dashboard : AppScreen.welcome;

  runApp(MyApp(
    repository: repository,
    initialScreen: initialScreen,
  ));
}

class MyApp extends StatelessWidget {
  final SubjectRepository repository;
  final AppScreen initialScreen;

  const MyApp({
    super.key,
    required this.repository,
    required this.initialScreen,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(create: (context) => ThemeBloc()),
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
          )..add(LoadSubjectsEvent()),
        ),
        BlocProvider<TimerBloc>(create: (context) => TimerBloc()),
        BlocProvider<ChatBloc>(create: (context) => ChatBloc()),
      ],
      child: BlocBuilder<ThemeBloc, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'StudyCoach AI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: Scaffold(
              body: BlocBuilder<NavigationBloc, NavigationState>(
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
