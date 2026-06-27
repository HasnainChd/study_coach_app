import 'package:flutter_bloc/flutter_bloc.dart';

enum AppScreen {
  welcome,
  addSubjects,
  dailySchedule,
  dashboard,     // Dashboard contains Home, Analytics, Coach, Subjects, Settings
  focusTimer,
}

// STATE
class NavigationState {
  final AppScreen currentScreen;
  final int activeTabIndex; // 0=Home, 1=Analytics, 2=Coach, 3=Subjects, 4=Settings

  NavigationState({
    required this.currentScreen,
    required this.activeTabIndex,
  });

  NavigationState copyWith({
    AppScreen? currentScreen,
    int? activeTabIndex,
  }) {
    return NavigationState(
      currentScreen: currentScreen ?? this.currentScreen,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
    );
  }
}

// EVENTS
abstract class NavigationEvent {}

class NavigateToScreenEvent extends NavigationEvent {
  final AppScreen screen;
  NavigateToScreenEvent(this.screen);
}

class SwitchDashboardTabEvent extends NavigationEvent {
  final int tabIndex;
  SwitchDashboardTabEvent(this.tabIndex);
}

// BLOC
class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(NavigationState(currentScreen: AppScreen.welcome, activeTabIndex: 0)) {
    on<NavigateToScreenEvent>((event, emit) {
      emit(state.copyWith(currentScreen: event.screen));
    });

    on<SwitchDashboardTabEvent>((event, emit) {
      emit(state.copyWith(activeTabIndex: event.tabIndex));
    });
  }
}
