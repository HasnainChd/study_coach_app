import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'features/bloc/theme_bloc.dart';
import 'features/bloc/navigation_bloc.dart';
import 'features/bloc/subjects_bloc.dart';
import 'features/bloc/timer_bloc.dart';
import 'features/bloc/chat_bloc.dart';
import 'features/onboarding/presentation/pages/welcome_page.dart';
import 'features/onboarding/presentation/pages/add_subjects_page.dart';
import 'features/onboarding/presentation/pages/daily_schedule_page.dart';
import 'features/dashboard/presentation/pages/dashboard_shell.dart';
import 'features/focus/presentation/pages/focus_timer_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(create: (context) => ThemeBloc()),
        BlocProvider<NavigationBloc>(create: (context) => NavigationBloc()),
        BlocProvider<SubjectsBloc>(create: (context) => SubjectsBloc()),
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
                    transitionBuilder: (Widget child, Animation<double> animation) {
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
        return const WelcomePage(
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
