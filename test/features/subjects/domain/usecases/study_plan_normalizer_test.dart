import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_coach_app/features/subjects/domain/entities/agenda_item.dart';
import 'package:study_coach_app/features/subjects/domain/entities/subject.dart';
import 'package:study_coach_app/features/subjects/domain/usecases/study_plan_normalizer.dart';

void main() {
  final subjects = [
    Subject(id: 's1', name: 'Urdu', color: Colors.green),
    Subject(id: 's2', name: 'English', color: Colors.blue),
    Subject(id: 's3', name: 'Islamic studies', color: Colors.orange),
    Subject(id: 's4', name: 'Computer Science', color: Colors.purple),
    Subject(id: 's5', name: 'Pakistan Study', color: Colors.red),
  ];

  AgendaItem task({
    required String id,
    required String subject,
    required int minutes,
    String? title,
  }) {
    return AgendaItem(
      id: id,
      title: title ?? '$subject session',
      tag: subject,
      durationMinutes: minutes,
      tagColor: Colors.grey,
    );
  }

  test('collapseDuplicateSubjectTasks merges duplicate subjects', () {
    final geminiItems = [
      task(id: '1', subject: 'Urdu', minutes: 20, title: 'Urdu grammar'),
      task(id: '2', subject: 'Urdu', minutes: 25, title: 'Urdu reading'),
      task(id: '3', subject: 'English', minutes: 45),
    ];

    final collapsed = collapseDuplicateSubjectTasks(geminiItems);

    expect(collapsed.length, 2);
    expect(collapsed.first.durationMinutes, 45);
    expect(collapsed.first.title, contains('Urdu'));
  });

  test('finalizeStudyPlan collapses 10 tasks to 5 and hits exact 90-min budget', () {
    final geminiItems = [
      task(id: '1', subject: 'Urdu', minutes: 18),
      task(id: '2', subject: 'Urdu', minutes: 18),
      task(id: '3', subject: 'English', minutes: 18),
      task(id: '4', subject: 'English', minutes: 18),
      task(id: '5', subject: 'Islamic studies', minutes: 18),
      task(id: '6', subject: 'Islamic studies', minutes: 18),
      task(id: '7', subject: 'Computer Science', minutes: 18),
      task(id: '8', subject: 'Computer Science', minutes: 18),
      task(id: '9', subject: 'Pakistan Study', minutes: 18),
      task(id: '10', subject: 'Pakistan Study', minutes: 18),
    ];

    const dailyMinutes = 90;
    final result = finalizeStudyPlan(
      geminiItems: geminiItems,
      subjects: subjects,
      dailyMinutes: dailyMinutes,
      batchTimestamp: 12345,
    );

    expect(result.budgetWarningMessage, isNull);
    expect(result.agendaItems.length, 5);
    expect(
      result.agendaItems.map((item) => item.tag).toSet(),
      subjects.map((subject) => subject.name).toSet(),
    );
    expect(
      result.agendaItems.fold<int>(0, (sum, item) => sum + item.durationMinutes),
      dailyMinutes,
    );
    expect(
      result.agendaItems.every(
        (item) => item.durationMinutes >= studyPlanMinTaskDurationMinutes,
      ),
      isTrue,
    );
  });

  test('finalizeStudyPlan keeps multiple tasks per subject when budget has room', () {
    final geminiItems = [
      task(id: '1', subject: 'Urdu', minutes: 45),
      task(id: '2', subject: 'Urdu', minutes: 45),
      task(id: '3', subject: 'English', minutes: 45),
      task(id: '4', subject: 'English', minutes: 45),
    ];

    const dailyMinutes = 90;
    final result = finalizeStudyPlan(
      geminiItems: geminiItems,
      subjects: subjects.take(2).toList(),
      dailyMinutes: dailyMinutes,
      batchTimestamp: 99,
    );

    expect(result.budgetWarningMessage, isNull);
    expect(result.agendaItems.length, 4);
    expect(
      result.agendaItems.fold<int>(0, (sum, item) => sum + item.durationMinutes),
      dailyMinutes,
    );
  });

  test('finalizeStudyPlan caps impossible budgets and returns warning', () {
    final manySubjects = List.generate(
      10,
      (index) => Subject(
        id: 's$index',
        name: 'Subject $index',
        color: Colors.teal,
      ),
    );
    final geminiItems = manySubjects
        .map(
          (subject) => task(
            id: subject.id,
            subject: subject.name,
            minutes: 12,
          ),
        )
        .toList();

    const dailyMinutes = 90;
    final result = finalizeStudyPlan(
      geminiItems: geminiItems,
      subjects: manySubjects,
      dailyMinutes: dailyMinutes,
      batchTimestamp: 77,
    );

    expect(result.budgetWarningMessage, isNotNull);
    expect(
      result.agendaItems.fold<int>(0, (sum, item) => sum + item.durationMinutes),
      manySubjects.length * studyPlanMinTaskDurationMinutes,
    );
    expect(
      result.agendaItems.every(
        (item) => item.durationMinutes == studyPlanMinTaskDurationMinutes,
      ),
      isTrue,
    );
  });

  test('ensureEverySubjectHasTask appends 10-min tasks for missing subjects', () {
    final geminiItems = [
      task(id: '1', subject: 'Urdu', minutes: 30),
      task(id: '2', subject: 'English', minutes: 30),
      task(id: '3', subject: 'Islamic studies', minutes: 30),
    ];

    final updated = ensureEverySubjectHasTask(
      agendaItems: geminiItems,
      subjects: subjects,
      batchTimestamp: 12345,
    );

    expect(updated.length, 5);
    expect(
      updated.map((item) => item.tag).toSet(),
      subjects.map((subject) => subject.name).toSet(),
    );
  });

  test('finalizeStudyPlan allocates time to 0-minute tasks and maintains exact budget', () {
    final geminiItems = [
      task(id: '1', subject: 'Computer Science', minutes: 45),
      task(id: '2', subject: 'Computer Science', minutes: 45),
      task(id: '3', subject: 'English', minutes: 0),
      task(id: '4', subject: 'English', minutes: 0),
    ];

    const dailyMinutes = 90;
    final result = finalizeStudyPlan(
      geminiItems: geminiItems,
      subjects: [
        Subject(id: 'cs', name: 'Computer Science', color: Colors.purple),
        Subject(id: 'eng', name: 'English', color: Colors.blue),
      ],
      dailyMinutes: dailyMinutes,
      batchTimestamp: 456,
    );

    expect(
      result.agendaItems.fold<int>(0, (sum, item) => sum + item.durationMinutes),
      dailyMinutes,
    );
    expect(
      result.agendaItems.every((item) => item.durationMinutes >= studyPlanMinTaskDurationMinutes),
      isTrue,
    );

    final englishTasks = result.agendaItems.where((item) => item.tag == 'English');
    expect(englishTasks.every((item) => item.durationMinutes > 0), isTrue);
  });

  test('normalizeAgendaToDailyBudget enforces min task duration when initial total equals dailyMinutes', () {
    final items = [
      task(id: '1', subject: 'Computer Science', minutes: 45),
      task(id: '2', subject: 'Computer Science', minutes: 45),
      task(id: '3', subject: 'English', minutes: 0),
      task(id: '4', subject: 'English', minutes: 0),
    ];

    const dailyMinutes = 90;
    final normalized = normalizeAgendaToDailyBudget(items, dailyMinutes);

    expect(
      normalized.fold<int>(0, (sum, item) => sum + item.durationMinutes),
      dailyMinutes,
    );
    expect(
      normalized.every((item) => item.durationMinutes >= studyPlanMinTaskDurationMinutes),
      isTrue,
    );
    expect(
      normalized.every((item) => item.durationMinutes <= studyPlanMaxTaskDurationMinutes),
      isTrue,
    );
  });

  test('splitOverlongTasks splits tasks over 30 minutes into multiple <= 30 min tasks', () {
    final items = [
      task(id: '1', subject: 'Computer Science', minutes: 60, title: 'Data Structures'),
      task(id: '2', subject: 'English', minutes: 25, title: 'Essay Writing'),
    ];

    final split = splitOverlongTasks(items);

    expect(split.length, 3);
    expect(split[0].title, contains('Part 1'));
    expect(split[0].durationMinutes, 30);
    expect(split[1].title, contains('Part 2'));
    expect(split[1].durationMinutes, 30);
    expect(split[2].title, 'Essay Writing');
    expect(split[2].durationMinutes, 25);
  });

  test('finalizeStudyPlan caps individual task durations at 30 minutes for large daily budget (120 min)', () {
    final geminiItems = [
      task(id: '1', subject: 'Computer Science', minutes: 60),
      task(id: '2', subject: 'English', minutes: 60),
    ];

    const dailyMinutes = 120;
    final result = finalizeStudyPlan(
      geminiItems: geminiItems,
      subjects: [
        Subject(id: 'cs', name: 'Computer Science', color: Colors.purple),
        Subject(id: 'eng', name: 'English', color: Colors.blue),
      ],
      dailyMinutes: dailyMinutes,
      batchTimestamp: 789,
    );

    expect(
      result.agendaItems.fold<int>(0, (sum, item) => sum + item.durationMinutes),
      dailyMinutes,
    );
    expect(
      result.agendaItems.every((item) => item.durationMinutes <= studyPlanMaxTaskDurationMinutes),
      isTrue,
    );
    expect(
      result.agendaItems.every((item) => item.durationMinutes >= studyPlanMinTaskDurationMinutes),
      isTrue,
    );
    expect(result.agendaItems.length, 4); // 2 CS (30+30) + 2 Eng (30+30) = 120 min
  });

  test('interleaveTasksBySubject keeps Part N tasks of the same topic contiguous as atomic unit', () {
    final items = [
      task(id: '1', subject: 'Computer Science', minutes: 30, title: 'Trees (Part 1)'),
      task(id: '2', subject: 'Computer Science', minutes: 30, title: 'Trees (Part 2)'),
      task(id: '3', subject: 'English', minutes: 30, title: 'Essay (Part 1)'),
      task(id: '4', subject: 'English', minutes: 30, title: 'Essay (Part 2)'),
    ];

    final interleaved = interleaveTasksBySubject(items);

    expect(
      interleaved.map((item) => item.title).toList(),
      ['Trees (Part 1)', 'Trees (Part 2)', 'Essay (Part 1)', 'Essay (Part 2)'],
    );
  });

  test('interleaveTasksBySubject alternates between distinct topics while keeping same-topic parts contiguous', () {
    final items = [
      task(id: '1', subject: 'Computer Science', minutes: 30, title: 'Trees (Part 1)'),
      task(id: '2', subject: 'Computer Science', minutes: 30, title: 'Trees (Part 2)'),
      task(id: '3', subject: 'Computer Science', minutes: 30, title: 'Algorithms (Part 1)'),
      task(id: '4', subject: 'English', minutes: 30, title: 'Essay (Part 1)'),
      task(id: '5', subject: 'English', minutes: 30, title: 'Essay (Part 2)'),
    ];

    final interleaved = interleaveTasksBySubject(items);

    expect(
      interleaved.map((item) => item.title).toList(),
      [
        'Trees (Part 1)',
        'Trees (Part 2)',
        'Essay (Part 1)',
        'Essay (Part 2)',
        'Algorithms (Part 1)',
      ],
    );
  });

  test('simulates 50+ min topic split into Part 1/Part 2 and verifies parts remain consecutive after interleaving with other subjects', () {
    final initialItems = [
      task(id: '1', subject: 'Computer Science', minutes: 60, title: 'Data Structures'),
      task(id: '2', subject: 'English', minutes: 30, title: 'Grammar Review'),
      task(id: '3', subject: 'Pakistan Study', minutes: 30, title: 'History Notes'),
    ];

    final splitItems = splitOverlongTasks(initialItems);
    final finalAgenda = interleaveTasksBySubject(splitItems);

    final titles = finalAgenda.map((item) => item.title).toList();
    expect(titles, [
      'Data Structures (Part 1)',
      'Data Structures (Part 2)',
      'Grammar Review',
      'History Notes',
    ]);

    final part1Index = finalAgenda.indexWhere((item) => item.title == 'Data Structures (Part 1)');
    final part2Index = finalAgenda.indexWhere((item) => item.title == 'Data Structures (Part 2)');

    expect(part1Index, isNot(-1));
    expect(part2Index, equals(part1Index + 1));
  });

  test('finalizeStudyPlan with 60-min task keeps split parts consecutive when interleaved with other subjects', () {
    final geminiItems = [
      task(id: '1', subject: 'Computer Science', minutes: 60, title: 'Data Structures'),
      task(id: '2', subject: 'English', minutes: 30, title: 'Grammar Review'),
      task(id: '3', subject: 'Pakistan Study', minutes: 30, title: 'History Notes'),
    ];

    final result = finalizeStudyPlan(
      geminiItems: geminiItems,
      subjects: [
        Subject(id: 'cs', name: 'Computer Science', color: Colors.purple),
        Subject(id: 'eng', name: 'English', color: Colors.blue),
        Subject(id: 'ps', name: 'Pakistan Study', color: Colors.red),
      ],
      dailyMinutes: 120,
      batchTimestamp: 999,
    );

    final titles = result.agendaItems.map((item) => item.title).toList();
    final csPart1Index = titles.indexOf('Data Structures (Part 1)');
    final csPart2Index = titles.indexOf('Data Structures (Part 2)');

    expect(csPart1Index, isNot(-1));
    expect(csPart2Index, equals(csPart1Index + 1));
  });
}
