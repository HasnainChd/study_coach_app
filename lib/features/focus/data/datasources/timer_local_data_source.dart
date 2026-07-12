import 'package:hive/hive.dart';

import '../models/timer_persisted_state_model.dart';

abstract class TimerLocalDataSource {
  Future<TimerPersistedStateModel?> getSavedState();
  Future<void> saveState(TimerPersistedStateModel state);
  Future<void> clearState();
}

class TimerLocalDataSourceImpl implements TimerLocalDataSource {
  final Box _box;

  TimerLocalDataSourceImpl(this._box);

  static const String _keyTimerState = 'activeTimerState';

  @override
  Future<TimerPersistedStateModel?> getSavedState() async {
    final raw = _box.get(_keyTimerState);
    if (raw == null) return null;
    return TimerPersistedStateModel.fromMap(
      Map<String, dynamic>.from(raw as Map),
    );
  }

  @override
  Future<void> saveState(TimerPersistedStateModel state) async {
    await _box.put(_keyTimerState, state.toMap());
  }

  @override
  Future<void> clearState() async {
    await _box.delete(_keyTimerState);
  }
}
