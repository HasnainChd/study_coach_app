import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/analytics_calculator.dart';
import '../../domain/repositories/study_history_repository.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final StudyHistoryRepository studyHistoryRepository;

  AnalyticsBloc({
    required this.studyHistoryRepository,
  }) : super(const AnalyticsState()) {
    on<LoadAnalyticsEvent>(_onLoadAnalytics);
    on<SelectAnalyticsDayEvent>(_onSelectDay);
  }

  Future<void> _onLoadAnalytics(
    LoadAnalyticsEvent event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(state.copyWith(status: AnalyticsStatus.loading, errorMessage: null));
    try {
      final entries = await studyHistoryRepository.getEntries();
      final snapshot = AnalyticsCalculator.compute(
        entries: entries,
        subjects: event.subjects,
      );

      final heightFactors = snapshot.minutesPerDay.map((minutes) {
        if (snapshot.maxDayMinutes <= 0) return 0.0;
        return minutes / snapshot.maxDayMinutes;
      }).toList();

      emit(
        state.copyWith(
          status: AnalyticsStatus.success,
          subjectCount: event.subjects.length,
          weekHoursLabel: AnalyticsCalculator.formatHours(snapshot.weeklyMinutes),
          allTimeXpLabel: '${snapshot.allTimeXpPoints}',
          dayLabels: snapshot.dayLabels,
          dayHeightFactors: heightFactors,
          selectedDayIndex: state.selectedDayIndex.clamp(0, 6),
          hasWeeklyActivity: snapshot.hasWeeklyActivity,
          hasBreakdown: snapshot.hasBreakdown,
          breakdownRows: snapshot.breakdownRows,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AnalyticsStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onSelectDay(
    SelectAnalyticsDayEvent event,
    Emitter<AnalyticsState> emit,
  ) {
    if (event.dayIndex < 0 || event.dayIndex > 6) return;
    emit(state.copyWith(selectedDayIndex: event.dayIndex));
  }
}
