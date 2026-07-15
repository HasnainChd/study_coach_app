import 'package:hive/hive.dart';

enum UsageType {
  planGenerate(1),
  planRegenerate(2),
  coachMessage(18);

  final int limit;
  const UsageType(this.limit);
}

class UsageLimitService {
  final Box _box;

  UsageLimitService(this._box);

  String _dateKey(UsageType type) => '${type.name}_date';
  String _countKey(UsageType type) => '${type.name}_count';

  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<bool> canPerformAction(UsageType type) async {
    final today = _getTodayString();
    final storedDate = _box.get(_dateKey(type)) as String?;

    if (storedDate != today) {
      await _box.put(_dateKey(type), today);
      await _box.put(_countKey(type), 0);
    }

    final count = _box.get(_countKey(type), defaultValue: 0) as int;
    return count < type.limit;
  }

  Future<void> recordAction(UsageType type) async {
    final today = _getTodayString();
    final storedDate = _box.get(_dateKey(type)) as String?;

    // Safety check: if date shifted before recording, reset first
    if (storedDate != today) {
      await _box.put(_dateKey(type), today);
      await _box.put(_countKey(type), 0);
    }

    final currentCount = _box.get(_countKey(type), defaultValue: 0) as int;
    await _box.put(_countKey(type), currentCount + 1);
  }

  Future<int> remainingToday(UsageType type) async {
    final today = _getTodayString();
    final storedDate = _box.get(_dateKey(type)) as String?;

    if (storedDate != today) {
      return type.limit;
    }

    final count = _box.get(_countKey(type), defaultValue: 0) as int;
    final remaining = type.limit - count;
    return remaining < 0 ? 0 : remaining;
  }
}
