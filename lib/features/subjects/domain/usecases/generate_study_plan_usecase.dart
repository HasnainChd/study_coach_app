import 'dart:convert';
import 'dart:io';

import '../../../../core/config/api_config.dart';
import '../../../../core/constants/grade_bands.dart';
import '../entities/agenda_item.dart';
import '../entities/subject.dart';
import '../entities/study_plan_result.dart';
import '../repositories/subject_repository.dart';
import 'study_plan_normalizer.dart';

class GenerateStudyPlanUseCase {
  final SubjectRepository repository;

  GenerateStudyPlanUseCase(this.repository);

  Future<StudyPlanResult> call({
    required int dailyMinutes,
    required String preferredTime,
  }) async {
    if (ApiConfig.geminiApiKey.isEmpty) {
      throw Exception(
        'Gemini API key is missing. Add API_KEY to your .env file.',
      );
    }

    final subjects = await repository.getSubjects();
    if (subjects.isEmpty) {
      throw ArgumentError(
          'Please add at least one subject before generating a plan.');
    }

    final settings = await repository.getSettingsPreferences();
    final gradeLevel = settings.gradeLevel;

    String gradeConstraintPrompt = '';
    if (gradeLevel != null && gradeLevel.trim().isNotEmpty) {
      final gradeBand = getGradeBandForGrade(gradeLevel);
      if (gradeBand != null) {
        final subjectTopicGuidelines = <String>[];
        for (final s in subjects) {
          final topics = gradeBand.getTopicsForSubject(s.name);
          if (topics != null && topics.isNotEmpty) {
            subjectTopicGuidelines.add(
                '- ${s.name}: Suggested topics include ${topics.join(', ')}');
          }
        }

        final topicsSection = subjectTopicGuidelines.isNotEmpty
            ? 'Subject Topic Suggestions for $gradeLevel:\n${subjectTopicGuidelines.join('\n')}'
            : 'Subject Topic Suggestions: (For custom subjects, choose topics strictly aligned with the difficulty guideline below).';

        gradeConstraintPrompt = '''

GRADE LEVEL & DIFFICULTY CONSTRAINTS (STRICTLY REQUIRED):
- Student Grade / Level: $gradeLevel (${gradeBand.name})
- Grade Difficulty Guideline: ${gradeBand.guideline}
$topicsSection

CRITICAL GRADE-LEVEL RULES:
1. Choose study tasks ONLY from grade-appropriate content matching $gradeLevel.
2. NEVER introduce advanced theoretical concepts or topics beyond the student's grade level (e.g., no Big-O notation, multivariable calculus, or complex organic synthesis unless at Undergraduate/Postgraduate level).
3. When unsure of topic depth, prefer standard fundamental topics suitable for $gradeLevel.
4. DO NOT mention or reference any specific country's curriculum, educational board, or nation-specific exam names (keep it universal and curriculum-agnostic).
''';
      }
    }

    // Sort subjects by exam date proximity (closer exams = higher priority)
    final now = DateTime.now();
    final sortedSubjects = List<Subject>.from(subjects);
    sortedSubjects.sort((a, b) {
      if (a.examDate == null && b.examDate == null) return 0;
      if (a.examDate == null) return 1; // b comes first (has exam date)
      if (b.examDate == null) return -1; // a comes first (has exam date)
      return a.examDate!.compareTo(b.examDate!); // closer date comes first
    });

    final subjectsWithPriority = sortedSubjects.map((s) {
      final daysLeft = s.examDate?.difference(now).inDays;
      final examStr =
          daysLeft != null ? 'Exam in $daysLeft days' : 'No exam scheduled';
      return '- ${s.name} ($examStr)';
    }).join('\n');

    final prompt = '''
You are an expert Study Coach AI.
Generate a daily study plan (list of study tasks) for a student studying these subjects, listed in priority order (highest priority first, based on how close their exam dates are):
$subjectsWithPriority

Daily study budget: $dailyMinutes minutes.
Preferred time of study: $preferredTime.
$gradeConstraintPrompt
CRITICAL TIME BUDGET RULES — MUST FOLLOW:
1. The TOTAL of all durationMinutes values MUST equal EXACTLY $dailyMinutes minutes. Not more. Not less.
2. Calculate total before returning. Adjust durations if total is wrong.
3. Minimum task duration: 10 minutes.
4. Maximum task duration: 30 minutes (research-backed optimal focus window).
5. Distribute total daily study time proportionally and fairly across ALL subjects that have tasks. Give MORE time to subjects with closer exam dates, but EVERY subject included MUST be allocated a non-zero, meaningful duration (at least 10 minutes per task). NEVER assign 0 minutes to any task or subject, and NEVER assign 100% of the total budget to a single subject if other subjects have tasks.
6. TASK DURATION & SPLITTING RULE: Keep individual task durations capped at a maximum of 30 minutes. When total daily study budget is large (e.g. 60, 90, 120 minutes), split the study time into more, shorter tasks (e.g. 20-30 min each) rather than fewer, longer ones — even if that means splitting a single subject into separate 30-minute sessions (e.g., "Part 1" / "Part 2" or distinct subtopics).
7. INTERLEAVING RULE: Interleave tasks from different subjects throughout the plan (e.g. alternate Computer Science and English tasks) rather than grouping all tasks of one subject together consecutively.

Return ONLY a raw JSON array of objects representing study tasks. Do not include markdown code block formatting (such as ```json). The JSON structure must match this schema:
[
  {
    "title": "Specific topic to review or practice based on the subject. Emphasize practice questions/focus if this subject has a close exam.",
    "subjectName": "Name of the subject matching one of the subjects provided",
    "durationMinutes": duration
  }
]
Provide specific, actionable study tasks rather than generic ones.
''';

    final client = HttpClient();
    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=${ApiConfig.geminiApiKey}');

    final request = await client.postUrl(uri);
    request.headers.contentType = ContentType.json;

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
      },
    });

    request.write(body);
    final response = await request.close();

    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to generate study plan: HTTP Status ${response.statusCode}');
    }
    final responseJson = jsonDecode(responseBody) as Map<String, dynamic>;

    final candidates = responseJson['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Invalid response from AI coach: No candidates found.');
    }

    final rawText = candidates[0]['content']['parts'][0]['text'] as String?;
    if (rawText == null || rawText.trim().isEmpty) {
      throw Exception(
          'Invalid response from AI coach: Empty content returned.');
    }

    // Clean up markdown block if returned or extract JSON array [...]
    var cleanText = rawText.trim();
    final jsonMatch =
        RegExp(r'\[\s*\{.*\}\s*\]', dotAll: true).firstMatch(cleanText);
    if (jsonMatch != null) {
      cleanText = jsonMatch.group(0)!;
    } else {
      if (cleanText.startsWith('```')) {
        final firstLineBreak = cleanText.indexOf('\n');
        if (firstLineBreak != -1) {
          cleanText = cleanText.substring(firstLineBreak + 1);
        }
      }
      if (cleanText.endsWith('```')) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }
    }
    cleanText = cleanText.trim();

    final List<dynamic> parsedList;
    try {
      parsedList = jsonDecode(cleanText) as List<dynamic>;
    } catch (e) {
      throw Exception('AI coach returned invalid JSON. Please try again.');
    }

    if (parsedList.isEmpty) {
      throw Exception(
          'AI coach returned an empty study plan. Please try again.');
    }

    List<AgendaItem> agendaItems = [];

    // Capture timestamp once so all generated IDs in this batch are unique
    final batchTimestamp = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < parsedList.length; i++) {
      final itemMap = parsedList[i] as Map<String, dynamic>;
      final title = itemMap['title'] as String? ?? 'Study session';
      final subjectName = itemMap['subjectName'] as String? ?? '';
      // Use (as num?)?.toInt() to safely handle both int and double JSON values.
      // Casting directly `as int?` throws a runtime error when Gemini returns
      // a floating-point literal such as 45.0 instead of 45.
      final rawDuration = (itemMap['durationMinutes'] as num?)?.toInt() ?? 30;
      final duration = rawDuration.clamp(
        studyPlanMinTaskDurationMinutes,
        studyPlanMaxTaskDurationMinutes,
      );

      // Find matching subject to resolve color
      var matchedSubject = subjects.first;
      for (final s in subjects) {
        if (s.name.toLowerCase().trim() == subjectName.toLowerCase().trim()) {
          matchedSubject = s;
          break;
        }
      }

      agendaItems.add(
        AgendaItem(
          id: 'gen_${batchTimestamp}_$i',
          title: title,
          tag: matchedSubject.name,
          durationMinutes: duration,
          tagColor: matchedSubject.color,
          isCompleted: false,
        ),
      );
    }

    return finalizeStudyPlan(
      geminiItems: agendaItems,
      subjects: subjects,
      dailyMinutes: dailyMinutes,
      batchTimestamp: batchTimestamp,
    );
  }
}
