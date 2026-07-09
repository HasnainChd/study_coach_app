/// Holds the focus-session duration set synchronously before navigation.
///
/// Bloc events are processed asynchronously, so passing duration only through
/// [TimerBloc] or [NavigationBloc] can leave the Focus Timer showing a stale
/// value from a previously selected card.
class FocusSessionLaunch {
  FocusSessionLaunch._();

  static int? pendingDurationSeconds;

  static void prepare(int durationSeconds) {
    pendingDurationSeconds = durationSeconds;
  }

  static void clear() {
    pendingDurationSeconds = null;
  }
}
