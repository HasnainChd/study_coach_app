import '../entities/agenda_item.dart';
import '../entities/study_plan_result.dart';
import '../entities/subject.dart';

const int studyPlanMinTaskDurationMinutes = 10;
const int studyPlanMaxTaskDurationMinutes = 60;

List<AgendaItem> ensureEverySubjectHasTask({
  required List<AgendaItem> agendaItems,
  required List<Subject> subjects,
  required int batchTimestamp,
}) {
  final coveredSubjects = agendaItems
      .map((item) => item.tag.toLowerCase().trim())
      .toSet();

  final updated = List<AgendaItem>.from(agendaItems);
  var fallbackIndex = 0;

  for (final subject in subjects) {
    final key = subject.name.toLowerCase().trim();
    if (coveredSubjects.contains(key)) continue;

    updated.add(
      AgendaItem(
        id: 'gen_${batchTimestamp}_min_$fallbackIndex',
        title: 'Quick review session for ${subject.name}',
        tag: subject.name,
        durationMinutes: studyPlanMinTaskDurationMinutes,
        tagColor: subject.color,
        isCompleted: false,
      ),
    );
    coveredSubjects.add(key);
    fallbackIndex++;
  }

  return updated;
}

List<AgendaItem> collapseDuplicateSubjectTasks(List<AgendaItem> agendaItems) {
  final grouped = <String, List<AgendaItem>>{};
  final order = <String>[];

  for (final item in agendaItems) {
    final key = item.tag.toLowerCase().trim();
    grouped.putIfAbsent(key, () {
      order.add(key);
      return [];
    });
    grouped[key]!.add(item);
  }

  return order.map((key) {
    final items = grouped[key]!;
    if (items.length == 1) return items.first;

    final first = items.first;
    final totalDuration = items.fold<int>(
      0,
      (sum, item) => sum + item.durationMinutes,
    );
    return first.copyWith(
      title: _mergedTitle(items),
      durationMinutes: totalDuration,
    );
  }).toList();
}

String _mergedTitle(List<AgendaItem> items) {
  final titles = items
      .map((item) => item.title.trim())
      .where((title) => title.isNotEmpty)
      .toList();
  if (titles.isEmpty) return 'Study session';
  if (titles.length == 1) return titles.first;

  titles.sort((a, b) => b.length.compareTo(a.length));
  if (titles.length == 2) return '${titles[0]} · ${titles[1]}';
  return '${titles[0]} · ${titles[1]}';
}

List<AgendaItem> normalizeAgendaToDailyBudget(
  List<AgendaItem> agendaItems,
  int dailyMinutes,
) {
  if (agendaItems.isEmpty) return agendaItems;

  var normalized = List<AgendaItem>.from(agendaItems);

  final actualTotal = normalized.fold<int>(
    0,
    (sum, item) => sum + item.durationMinutes,
  );

  if (actualTotal != dailyMinutes) {
    normalized = normalized.map((item) {
      final scaled =
          (item.durationMinutes * dailyMinutes / actualTotal).round();
      return item.copyWith(
        durationMinutes: scaled.clamp(
          studyPlanMinTaskDurationMinutes,
          studyPlanMaxTaskDurationMinutes,
        ),
      );
    }).toList();
  }

  return _balanceToExactBudget(normalized, dailyMinutes);
}

List<AgendaItem> _balanceToExactBudget(
  List<AgendaItem> items,
  int dailyMinutes,
) {
  var result = List<AgendaItem>.from(items);

  for (var pass = 0; pass < 10000; pass++) {
    final total = result.fold<int>(0, (sum, item) => sum + item.durationMinutes);
    final diff = dailyMinutes - total;
    if (diff == 0) break;

    if (diff > 0) {
      final index = _indexWithMostAdjustRoom(
        result,
        increase: true,
      );
      if (index == null) break;
      final room =
          studyPlanMaxTaskDurationMinutes - result[index].durationMinutes;
      final delta = diff < room ? diff : room;
      result[index] = result[index].copyWith(
        durationMinutes: result[index].durationMinutes + delta,
      );
    } else {
      final index = _indexWithMostAdjustRoom(
        result,
        increase: false,
      );
      if (index == null) break;
      final room =
          result[index].durationMinutes - studyPlanMinTaskDurationMinutes;
      final delta = (-diff) < room ? -diff : room;
      result[index] = result[index].copyWith(
        durationMinutes: result[index].durationMinutes - delta,
      );
    }
  }

  return result;
}

int? _indexWithMostAdjustRoom(
  List<AgendaItem> items, {
  required bool increase,
}) {
  int? bestIndex;
  var bestRoom = 0;

  for (var i = 0; i < items.length; i++) {
    final room = increase
        ? studyPlanMaxTaskDurationMinutes - items[i].durationMinutes
        : items[i].durationMinutes - studyPlanMinTaskDurationMinutes;
    if (room > bestRoom) {
      bestRoom = room;
      bestIndex = i;
    }
  }

  return bestRoom > 0 ? bestIndex : null;
}

String buildBudgetTooSmallWarning({
  required int subjectCount,
  required int dailyMinutes,
}) {
  final minRequired = subjectCount * studyPlanMinTaskDurationMinutes;
  return 'Your $dailyMinutes-minute daily budget cannot fit all $subjectCount '
      'subjects (each needs at least $studyPlanMinTaskDurationMinutes minutes). '
      'Plan set to $minRequired minutes — try increasing daily study time in '
      'Settings.';
}

StudyPlanResult finalizeStudyPlan({
  required List<AgendaItem> geminiItems,
  required List<Subject> subjects,
  required int dailyMinutes,
  required int batchTimestamp,
}) {
  var items = List<AgendaItem>.from(geminiItems);

  if (items.length * studyPlanMinTaskDurationMinutes > dailyMinutes) {
    items = collapseDuplicateSubjectTasks(items);
  }

  items = ensureEverySubjectHasTask(
    agendaItems: items,
    subjects: subjects,
    batchTimestamp: batchTimestamp,
  );

  final maxTasksForBudget = dailyMinutes ~/ studyPlanMinTaskDurationMinutes;
  if (subjects.length > maxTasksForBudget) {
    final capped = items
        .map(
          (item) => item.copyWith(
            durationMinutes: studyPlanMinTaskDurationMinutes,
          ),
        )
        .toList();

    return StudyPlanResult(
      agendaItems: capped,
      budgetWarningMessage: buildBudgetTooSmallWarning(
        subjectCount: subjects.length,
        dailyMinutes: dailyMinutes,
      ),
    );
  }

  return StudyPlanResult(
    agendaItems: normalizeAgendaToDailyBudget(items, dailyMinutes),
  );
}
