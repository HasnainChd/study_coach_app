import 'package:study_coach_app/features/focus/data/datasources/timer_local_data_source.dart';
import 'package:study_coach_app/features/focus/data/models/timer_persisted_state_model.dart';

class FakeTimerLocalDataSource implements TimerLocalDataSource {
  TimerPersistedStateModel? saved;

  @override
  Future<void> clearState() async {
    saved = null;
  }

  @override
  Future<TimerPersistedStateModel?> getSavedState() async => saved;

  @override
  Future<void> saveState(TimerPersistedStateModel state) async {
    saved = state;
  }
}
