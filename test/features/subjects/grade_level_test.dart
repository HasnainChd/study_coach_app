import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_coach_app/core/constants/grade_bands.dart';
import 'package:study_coach_app/features/subjects/data/models/settings_preferences_model.dart';
import 'package:study_coach_app/features/subjects/domain/entities/settings_preferences.dart';
import 'package:study_coach_app/features/subjects/domain/entities/subject.dart';
import 'package:study_coach_app/features/subjects/domain/entities/agenda_item.dart';
import 'package:study_coach_app/features/subjects/domain/repositories/subject_repository.dart';

class FakeSubjectRepository implements SubjectRepository {
  SettingsPreferences settings = SettingsPreferences(gradeLevel: 'Grade 9');

  @override
  Future<List<Subject>> getSubjects() async => [
        Subject(id: '1', name: 'Mathematics', color: Colors.blue),
      ];
  @override
  Future<void> saveSubjects(List<Subject> subjects) async {}
  @override
  Future<List<AgendaItem>> getAgendaItems() async => [];
  @override
  Future<void> saveAgendaItems(List<AgendaItem> items) async {}
  @override
  Future<SettingsPreferences> getSettingsPreferences() async => settings;
  @override
  Future<void> saveSettingsPreferences(SettingsPreferences s) async {
    settings = s;
  }
  @override
  Future<int> getDailyStudyMinutes() async => 60;
  @override
  Future<void> saveDailyStudyMinutes(int minutes) async {}
  @override
  Future<String> getPreferredTime() async => 'Morning';
  @override
  Future<void> savePreferredTime(String time) async {}
  @override
  Future<bool> getNotificationsEnabled() async => true;
  @override
  Future<void> saveNotificationsEnabled(bool enabled) async {}
  @override
  Future<bool> getHasCompletedOnboarding() async => true;
  @override
  Future<void> saveHasCompletedOnboarding(bool completed) async {}
  @override
  Future<int> getStreak() async => 0;
  @override
  Future<void> saveStreak(int streak) async {}
  @override
  Future<double> getXpProgress() async => 0.0;
  @override
  Future<void> saveXpProgress(double xp) async {}
  @override
  Future<int> getLevel() async => 1;
  @override
  Future<void> saveLevel(int level) async {}
  @override
  Future<String> getLastStreakClaimedDate() async => '';
  @override
  Future<void> saveLastStreakClaimedDate(String dateStr) async {}
  @override
  Future<int> getCoins() async => 0;
  @override
  Future<void> saveCoins(int coins) async {}
  @override
  Future<List<String>> getUnlockedRewards() async => [];
  @override
  Future<void> saveUnlockedRewards(List<String> rewardIds) async {}
  @override
  Future<String?> getActiveThemeId() async => null;
  @override
  Future<void> saveActiveThemeId(String? id) async {}
  @override
  Future<String?> getActiveBadgeId() async => null;
  @override
  Future<void> saveActiveBadgeId(String? id) async {}
}

void main() {
  group('GradeBands Reference Data', () {
    test('kGradeOptions contains expected 9 options', () {
      expect(kGradeOptions.length, 9);
      expect(kGradeOptions.first, 'Grade 6');
      expect(kGradeOptions.last, 'Postgraduate / Professional');
    });

    test('getGradeBandForGrade maps grade options correctly to bands', () {
      expect(getGradeBandForGrade('Grade 6')?.name, 'Middle School (Grades 6–8)');
      expect(getGradeBandForGrade('Grade 7')?.name, 'Middle School (Grades 6–8)');
      expect(getGradeBandForGrade('Grade 8')?.name, 'Middle School (Grades 6–8)');

      expect(getGradeBandForGrade('Grade 9')?.name, 'Early High School (Grades 9–10)');
      expect(getGradeBandForGrade('Grade 10')?.name, 'Early High School (Grades 9–10)');

      expect(getGradeBandForGrade('Grade 11')?.name, 'Late High School (Grades 11–12)');
      expect(getGradeBandForGrade('Grade 12')?.name, 'Late High School (Grades 11–12)');

      expect(getGradeBandForGrade('Undergraduate')?.name, 'Undergraduate');
      expect(getGradeBandForGrade('Postgraduate / Professional')?.name, 'Postgraduate / Professional');

      expect(getGradeBandForGrade(null), isNull);
    });

    test('Computer Science returns CS topics in every band (not Science topics)', () {
      final allBands = [
        kBandMiddleSchool,
        kBandEarlyHighSchool,
        kBandLateHighSchool,
        kBandUndergraduate,
        kBandPostgraduate,
      ];

      for (final band in allBands) {
        final topics = band.getTopicsForSubject('Computer Science');
        final csTopics = band.subjectTopics['Computer Science'];
        final scienceTopics = band.subjectTopics['Science'];

        expect(topics, isNotNull);
        expect(topics, equals(csTopics));
        expect(topics, isNot(equals(scienceTopics)));
      }
    });

    test('Mathematics returns Math topics', () {
      final band = getGradeBandForGrade('Grade 9')!;
      final topics = band.getTopicsForSubject('Mathematics');
      expect(topics, equals(band.subjectTopics['Math']));
    });

    test('Data Science returns null (does not match generic Science topics)', () {
      final allBands = [
        kBandMiddleSchool,
        kBandEarlyHighSchool,
        kBandLateHighSchool,
        kBandUndergraduate,
        kBandPostgraduate,
      ];

      for (final band in allBands) {
        final topics = band.getTopicsForSubject('Data Science');
        expect(topics, isNull);
      }
    });

    test('Physics returns Physics topics in every band', () {
      final allBands = [
        kBandMiddleSchool,
        kBandEarlyHighSchool,
        kBandLateHighSchool,
        kBandUndergraduate,
        kBandPostgraduate,
      ];

      for (final band in allBands) {
        final topics = band.getTopicsForSubject('Physics');
        expect(topics, equals(band.subjectTopics['Physics']));
      }
    });
  });

  group('SettingsPreferences gradeLevel persistence', () {
    test('default gradeLevel is null', () {
      final prefs = SettingsPreferences();
      expect(prefs.gradeLevel, isNull);
    });

    test('copyWith gradeLevel and clearGradeLevel work as expected', () {
      final prefs = SettingsPreferences();
      final updated = prefs.copyWith(gradeLevel: 'Grade 10');
      expect(updated.gradeLevel, 'Grade 10');

      final cleared = updated.copyWith(clearGradeLevel: true);
      expect(cleared.gradeLevel, isNull);
    });

    test('SettingsPreferencesModel toMap and fromMap serialize gradeLevel', () {
      final model = SettingsPreferencesModel(gradeLevel: 'Undergraduate');
      final map = model.toMap();
      expect(map['gradeLevel'], 'Undergraduate');

      final restored = SettingsPreferencesModel.fromMap(map);
      expect(restored.gradeLevel, 'Undergraduate');
    });

    test('SettingsPreferencesModel fromMap with null gradeLevel defaults to null', () {
      final restored = SettingsPreferencesModel.fromMap({});
      expect(restored.gradeLevel, isNull);
    });
  });
}
