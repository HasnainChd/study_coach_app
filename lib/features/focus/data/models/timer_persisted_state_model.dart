class TimerPersistedStateModel {
  final String taskId;
  final String? taskTitle;
  final String? subjectName;
  final int? subjectColorValue;
  final int remainingSeconds;
  final int totalSeconds;
  final bool isPaused;
  final int lastUpdatedTimestampMs;
  final int workDurationSeconds;

  const TimerPersistedStateModel({
    required this.taskId,
    this.taskTitle,
    this.subjectName,
    this.subjectColorValue,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isPaused,
    required this.lastUpdatedTimestampMs,
    required this.workDurationSeconds,
  });

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'taskTitle': taskTitle,
      'subjectName': subjectName,
      'subjectColorValue': subjectColorValue,
      'remainingSeconds': remainingSeconds,
      'totalSeconds': totalSeconds,
      'isPaused': isPaused,
      'lastUpdatedTimestampMs': lastUpdatedTimestampMs,
      'workDurationSeconds': workDurationSeconds,
    };
  }

  factory TimerPersistedStateModel.fromMap(Map<String, dynamic> map) {
    return TimerPersistedStateModel(
      taskId: map['taskId'] as String,
      taskTitle: map['taskTitle'] as String?,
      subjectName: map['subjectName'] as String?,
      subjectColorValue: map['subjectColorValue'] as int?,
      remainingSeconds: (map['remainingSeconds'] as num).toInt(),
      totalSeconds: (map['totalSeconds'] as num).toInt(),
      isPaused: map['isPaused'] as bool? ?? false,
      lastUpdatedTimestampMs: (map['lastUpdatedTimestampMs'] as num).toInt(),
      workDurationSeconds: (map['workDurationSeconds'] as num).toInt(),
    );
  }
}
