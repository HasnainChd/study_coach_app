import 'package:flutter/material.dart';

import '../../subjects/domain/entities/subject.dart';
import 'entities/study_history_entry.dart';

class SubjectBreakdownRow {
  final String subjectName;
  final int totalMinutes;
  final double share;
  final Color color;

  const SubjectBreakdownRow({
    required this.subjectName,
    required this.totalMinutes,
    required this.share,
    required this.color,
  });
}

class AnalyticsSnapshot {
  final int weeklyMinutes;
  final int allTimeXpPoints;
  final List<String> dayLabels;
  final List<int> minutesPerDay;
  final int maxDayMinutes;
  final bool hasWeeklyActivity;
  final bool hasBreakdown;
  final List<SubjectBreakdownRow> breakdownRows;

  const AnalyticsSnapshot({
    required this.weeklyMinutes,
    required this.allTimeXpPoints,
    required this.dayLabels,
    required this.minutesPerDay,
    required this.maxDayMinutes,
    required this.hasWeeklyActivity,
    required this.hasBreakdown,
    required this.breakdownRows,
  });
}

class AnalyticsCalculator {
  static List<DateTime> lastSevenDays([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(
      7,
      (index) => today.subtract(Duration(days: 6 - index)),
    );
  }

  static String dateKey(DateTime date) {
    return date.toIso8601String().substring(0, 10);
  }

  static String dayLabel(DateTime date) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[date.weekday - 1];
  }

  static String formatHours(int minutes) {
    if (minutes <= 0) return '0h';
    final hours = minutes / 60.0;
    final rounded = (hours * 10).round() / 10;
    if (rounded == rounded.roundToDouble()) {
      return '${rounded.round()}h';
    }
    return '${rounded.toStringAsFixed(1)}h';
  }

  static AnalyticsSnapshot compute({
    required List<StudyHistoryEntry> entries,
    required List<Subject> subjects,
    DateTime? reference,
  }) {
    final days = lastSevenDays(reference);
    final dayKeys = days.map(dateKey).toList();
    final minutesPerDay = dayKeys.map((key) {
      return entries
          .where((entry) => entry.date == key)
          .fold<int>(0, (sum, entry) => sum + entry.durationMinutes);
    }).toList();

    final weeklyMinutes =
        minutesPerDay.fold<int>(0, (sum, minutes) => sum + minutes);
    final maxDayMinutes = minutesPerDay.fold<int>(
      0,
      (max, minutes) => minutes > max ? minutes : max,
    );

    final allTimeXp = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.xpAwarded,
    );

    final breakdownRows = _buildBreakdown(entries, subjects);

    return AnalyticsSnapshot(
      weeklyMinutes: weeklyMinutes,
      allTimeXpPoints: (allTimeXp * 100).round(),
      dayLabels: days.map(dayLabel).toList(),
      minutesPerDay: minutesPerDay,
      maxDayMinutes: maxDayMinutes,
      hasWeeklyActivity: weeklyMinutes > 0,
      hasBreakdown: breakdownRows.isNotEmpty,
      breakdownRows: breakdownRows,
    );
  }

  static List<SubjectBreakdownRow> _buildBreakdown(
    List<StudyHistoryEntry> entries,
    List<Subject> subjects,
  ) {
    if (entries.isEmpty) return [];

    final minutesBySubject = <String, int>{};
    final snapshotNamesBySubject = <String, String>{};
    for (final entry in entries) {
      final key = _subjectKey(entry);
      minutesBySubject[key] =
          (minutesBySubject[key] ?? 0) + entry.durationMinutes;
      if (entry.subjectName.trim().isNotEmpty) {
        snapshotNamesBySubject[key] = entry.subjectName.trim();
      }
    }

    final totalMinutes = minutesBySubject.values.fold<int>(
      0,
      (sum, minutes) => sum + minutes,
    );
    if (totalMinutes == 0) return [];

    final rows = minutesBySubject.entries.map((entry) {
      final subject = _matchSubject(subjects, entry.key);
      final snapshotName = snapshotNamesBySubject[entry.key];
      final baseName = snapshotName?.isNotEmpty == true
          ? snapshotName!
          : (subject?.name ?? _displayNameFromKey(entry.key));
      final displayName =
          subject == null ? '$baseName (Deleted)' : baseName;
      final color = subject?.color ?? Colors.grey;
      return SubjectBreakdownRow(
        subjectName: displayName,
        totalMinutes: entry.value,
        share: entry.value / totalMinutes,
        color: color,
      );
    }).toList();

    rows.sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));
    return rows;
  }

  static String _subjectKey(StudyHistoryEntry entry) {
    if (entry.subjectId != null && entry.subjectId!.isNotEmpty) {
      return 'id:${entry.subjectId}';
    }
    return 'name:${entry.subjectName.toLowerCase().trim()}';
  }

  static Subject? _matchSubject(List<Subject> subjects, String key) {
    if (key.startsWith('id:')) {
      final id = key.substring(3);
      for (final subject in subjects) {
        if (subject.id == id) return subject;
      }
      return null;
    }

    final name = key.substring(5);
    for (final subject in subjects) {
      if (subject.name.toLowerCase().trim() == name) {
        return subject;
      }
    }
    return null;
  }

  static String _displayNameFromKey(String key) {
    if (key.startsWith('name:')) {
      final raw = key.substring(5);
      if (raw.isEmpty) return 'Unknown';
      return raw[0].toUpperCase() + raw.substring(1);
    }
    return 'Unknown';
  }
}
