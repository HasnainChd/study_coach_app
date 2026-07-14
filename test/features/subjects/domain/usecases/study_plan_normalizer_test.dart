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
}
