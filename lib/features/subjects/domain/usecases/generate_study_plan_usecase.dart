import 'dart:convert';
import 'dart:io';

import '../../../../core/config/api_config.dart';
import '../entities/agenda_item.dart';
import '../entities/subject.dart';
import '../repositories/subject_repository.dart';

class GenerateStudyPlanUseCase {
  final SubjectRepository repository;

  GenerateStudyPlanUseCase(this.repository);

  Future<List<AgendaItem>> call({
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

CRITICAL TIME BUDGET RULES — MUST FOLLOW:
1. The TOTAL of all durationMinutes values MUST equal EXACTLY $dailyMinutes minutes. Not more. Not less.
2. Calculate total before returning. Adjust durations if total is wrong.
3. Minimum task duration: 10 minutes.
4. Maximum task duration: 60 minutes.
5. Give MORE time to subjects with closer exam dates.
6. Return tasks sorted by exam date proximity (closest exam first).

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
      ]
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

    // Clean up markdown block if returned
    var cleanText = rawText.trim();
    if (cleanText.startsWith('```')) {
      final firstLineBreak = cleanText.indexOf('\n');
      if (firstLineBreak != -1) {
        cleanText = cleanText.substring(firstLineBreak + 1);
      }
    }
    if (cleanText.endsWith('```')) {
      cleanText = cleanText.substring(0, cleanText.length - 3);
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
      final duration = (itemMap['durationMinutes'] as num?)?.toInt() ?? 30;

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
    // Step 1: Calculate actual total
    int actualTotal = agendaItems.fold(
      0, (sum, item) => sum + item.durationMinutes
    );

    // Step 2: If total != dailyMinutes, scale
    if (actualTotal != dailyMinutes) {
      agendaItems = agendaItems.map((item) {
        final scaled = (item.durationMinutes * 
          dailyMinutes / actualTotal).round();
        return item.copyWith(
          durationMinutes: scaled.clamp(10, 60)
        );
      }).toList();
    }

    // Step 3: Fix rounding remainder on last task
    int correctedTotal = agendaItems.fold(
      0, (sum, item) => sum + item.durationMinutes
    );
    int remainder = dailyMinutes - correctedTotal;
    if (remainder != 0) {
      final last = agendaItems.last;
      final correctedLast = (last.durationMinutes + 
        remainder).clamp(10, 60);
      agendaItems[agendaItems.length - 1] = 
        last.copyWith(durationMinutes: correctedLast);
    }

    // Step 4: Verify
    final finalTotal = agendaItems.fold(
      0, (sum, item) => sum + item.durationMinutes
    );

    return agendaItems;
  }
}
