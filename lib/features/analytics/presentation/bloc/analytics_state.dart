import '../../domain/analytics_calculator.dart';

enum AnalyticsStatus { initial, loading, success, failure }

class AnalyticsState {
  final AnalyticsStatus status;
  final int subjectCount;
  final String weekHoursLabel;
  final String allTimeXpLabel;
  final List<String> dayLabels;
  final List<double> dayHeightFactors;
  final int selectedDayIndex;
  final bool hasWeeklyActivity;
  final bool hasBreakdown;
  final List<SubjectBreakdownRow> breakdownRows;
  final String? errorMessage;

  const AnalyticsState({
    this.status = AnalyticsStatus.initial,
    this.subjectCount = 0,
    this.weekHoursLabel = '0h',
    this.allTimeXpLabel = '0',
    this.dayLabels = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
    this.dayHeightFactors = const [0, 0, 0, 0, 0, 0, 0],
    this.selectedDayIndex = 6,
    this.hasWeeklyActivity = false,
    this.hasBreakdown = false,
    this.breakdownRows = const [],
    this.errorMessage,
  });

  AnalyticsState copyWith({
    AnalyticsStatus? status,
    int? subjectCount,
    String? weekHoursLabel,
    String? allTimeXpLabel,
    List<String>? dayLabels,
    List<double>? dayHeightFactors,
    int? selectedDayIndex,
    bool? hasWeeklyActivity,
    bool? hasBreakdown,
    List<SubjectBreakdownRow>? breakdownRows,
    String? errorMessage,
  }) {
    return AnalyticsState(
      status: status ?? this.status,
      subjectCount: subjectCount ?? this.subjectCount,
      weekHoursLabel: weekHoursLabel ?? this.weekHoursLabel,
      allTimeXpLabel: allTimeXpLabel ?? this.allTimeXpLabel,
      dayLabels: dayLabels ?? this.dayLabels,
      dayHeightFactors: dayHeightFactors ?? this.dayHeightFactors,
      selectedDayIndex: selectedDayIndex ?? this.selectedDayIndex,
      hasWeeklyActivity: hasWeeklyActivity ?? this.hasWeeklyActivity,
      hasBreakdown: hasBreakdown ?? this.hasBreakdown,
      breakdownRows: breakdownRows ?? this.breakdownRows,
      errorMessage: errorMessage,
    );
  }
}
