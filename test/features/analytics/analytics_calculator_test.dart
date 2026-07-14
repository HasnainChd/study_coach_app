import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_coach_app/features/analytics/domain/analytics_calculator.dart';
import 'package:study_coach_app/features/analytics/domain/entities/study_history_entry.dart';
import 'package:study_coach_app/features/subjects/domain/entities/subject.dart';

void main() {
  final subjects = [
    Subject(id: 's_urdu', name: 'Urdu', color: Colors.green),
    Subject(id: 's_cs', name: 'Computer Science', color: Colors.blue),
  ];

  test('compute aggregates weekly hours, all-time XP, and subject breakdown', () {
    final today = DateTime(2026, 7, 12);
    final todayKey = AnalyticsCalculator.dateKey(today);
    final yesterdayKey = AnalyticsCalculator.dateKey(
      today.subtract(const Duration(days: 1)),
    );

    final entries = [
      StudyHistoryEntry(
        id: '1',
        agendaItemId: 'task_1',
        date: todayKey,
        subjectName: 'Urdu',
        subjectId: 's_urdu',
        durationMinutes: 60,
        xpAwarded: 0.5,
      ),
      StudyHistoryEntry(
        id: '2',
        agendaItemId: 'task_2',
        date: yesterdayKey,
        subjectName: 'Computer Science',
        subjectId: 's_cs',
        durationMinutes: 30,
        xpAwarded: 0.5,
      ),
    ];

    final snapshot = AnalyticsCalculator.compute(
      entries: entries,
      subjects: subjects,
      reference: today,
    );

    expect(snapshot.weeklyMinutes, 90);
    expect(snapshot.allTimeXpPoints, 100);
    expect(snapshot.hasWeeklyActivity, isTrue);
    expect(snapshot.breakdownRows.length, 2);
    expect(snapshot.breakdownRows.first.subjectName, 'Urdu');
    expect(snapshot.breakdownRows.first.color, Colors.green);
    expect(AnalyticsCalculator.formatHours(snapshot.weeklyMinutes), '1.5h');
  });

  test('compute reports empty weekly activity when no entries exist', () {
    final snapshot = AnalyticsCalculator.compute(
      entries: const [],
      subjects: subjects,
      reference: DateTime(2026, 7, 12),
    );

    expect(snapshot.weeklyMinutes, 0);
    expect(snapshot.allTimeXpPoints, 0);
    expect(snapshot.hasWeeklyActivity, isFalse);
    expect(snapshot.hasBreakdown, isFalse);
  });

  test('breakdown keeps snapshot subject name when subject was deleted', () {
    final entries = [
      StudyHistoryEntry(
        id: '1',
        agendaItemId: 'task_1',
        date: '2026-07-12',
        subjectName: 'Computer Science',
        subjectId: 's_cs',
        durationMinutes: 12,
        xpAwarded: 0.2,
      ),
    ];

    final snapshot = AnalyticsCalculator.compute(
      entries: entries,
      subjects: [
        Subject(id: 's_urdu', name: 'Urdu', color: Colors.green),
      ],
      reference: DateTime(2026, 7, 12),
    );

    expect(snapshot.breakdownRows.length, 1);
    expect(
      snapshot.breakdownRows.first.subjectName,
      'Computer Science (Deleted)',
    );
    expect(snapshot.breakdownRows.first.color, Colors.grey);
  });

  test(
    'breakdown labels deleted and live subjects with same name separately',
    () {
      final entries = [
        StudyHistoryEntry(
          id: '1',
          agendaItemId: 'task_1',
          date: '2026-07-12',
          subjectName: 'Computer Science',
          subjectId: 's_cs_old',
          durationMinutes: 12,
          xpAwarded: 0.2,
        ),
        StudyHistoryEntry(
          id: '2',
          agendaItemId: 'task_2',
          date: '2026-07-12',
          subjectName: 'Computer Science',
          subjectId: 's_cs_new',
          durationMinutes: 30,
          xpAwarded: 0.5,
        ),
      ];

      final snapshot = AnalyticsCalculator.compute(
        entries: entries,
        subjects: [
          Subject(id: 's_cs_new', name: 'Computer Science', color: Colors.blue),
        ],
        reference: DateTime(2026, 7, 12),
      );

      expect(snapshot.breakdownRows.length, 2);
      expect(snapshot.breakdownRows[0].subjectName, 'Computer Science');
      expect(snapshot.breakdownRows[0].color, Colors.blue);
      expect(snapshot.breakdownRows[1].subjectName, 'Computer Science (Deleted)');
      expect(snapshot.breakdownRows[1].color, Colors.grey);
    },
  );
}
