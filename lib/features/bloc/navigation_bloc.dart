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
  /// Duration in seconds for the focus timer when opening [AppScreen.focusTimer].
  final int? focusDurationSeconds;

  NavigationState({
    required this.currentScreen,
    required this.activeTabIndex,
    this.focusDurationSeconds,
  });

  NavigationState copyWith({
    AppScreen? currentScreen,
    int? activeTabIndex,
    int? focusDurationSeconds,
    bool clearFocusDuration = false,
  }) {
    return NavigationState(
      currentScreen: currentScreen ?? this.currentScreen,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      focusDurationSeconds: clearFocusDuration
          ? null
          : (focusDurationSeconds ?? this.focusDurationSeconds),
    );
  }
}

// EVENTS
abstract class NavigationEvent {}

class NavigateToScreenEvent extends NavigationEvent {
  final AppScreen screen;
  final int? focusDurationSeconds;

  NavigateToScreenEvent(this.screen, {this.focusDurationSeconds});
}

class SwitchDashboardTabEvent extends NavigationEvent {
  final int tabIndex;
  SwitchDashboardTabEvent(this.tabIndex);
}

// BLOC
class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  /// Latest focus-session duration requested before navigation completes.
  int? pendingFocusDurationSeconds;

  NavigationBloc({AppScreen initialScreen = AppScreen.welcome})
      : super(NavigationState(currentScreen: initialScreen, activeTabIndex: 0)) {
    on<NavigateToScreenEvent>((event, emit) {
      final openingFocusTimer = event.screen == AppScreen.focusTimer;
      if (openingFocusTimer && event.focusDurationSeconds != null) {
        pendingFocusDurationSeconds = event.focusDurationSeconds;
      } else if (!openingFocusTimer) {
        pendingFocusDurationSeconds = null;
      }

      emit(state.copyWith(
        currentScreen: event.screen,
        focusDurationSeconds: openingFocusTimer
            ? event.focusDurationSeconds
            : null,
        clearFocusDuration: !openingFocusTimer,
      ));
    });

    on<SwitchDashboardTabEvent>((event, emit) {
      emit(state.copyWith(activeTabIndex: event.tabIndex));
    });
  }

  void openFocusTimer({required int durationSeconds}) {
    pendingFocusDurationSeconds = durationSeconds;
    add(
      NavigateToScreenEvent(
        AppScreen.focusTimer,
        focusDurationSeconds: durationSeconds,
      ),
    );
  }
}
