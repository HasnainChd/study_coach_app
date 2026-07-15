import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:study_coach_app/core/services/usage_limit_service.dart';

void main() {
  late Box testBox;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);
    testBox = await Hive.openBox('test_usage_limits');
  });

  tearDown(() async {
    await testBox.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('canPerformAction respects limit and recordAction increments', () async {
    final service = UsageLimitService(testBox);
    final type = UsageType.planGenerate; // Limit: 1

    expect(await service.canPerformAction(type), isTrue);
    expect(await service.remainingToday(type), 1);

    await service.recordAction(type);

    expect(await service.canPerformAction(type), isFalse);
    expect(await service.remainingToday(type), 0);
  });

  test('date-based reset resets counters', () async {
    final service = UsageLimitService(testBox);
    final type = UsageType.planRegenerate; // Limit: 2

    expect(await service.canPerformAction(type), isTrue);
    expect(await service.remainingToday(type), 2);

    await service.recordAction(type);
    expect(await service.remainingToday(type), 1);

    await service.recordAction(type);
    expect(await service.remainingToday(type), 0);
    expect(await service.canPerformAction(type), isFalse);

    // Simulate date change by modifying the date key in the box directly
    final dateKey = '${type.name}_date';
    await testBox.put(dateKey, '2020-01-01');

    // Next check should trigger reset
    expect(await service.canPerformAction(type), isTrue);
    expect(await service.remainingToday(type), 2);
  });
}
