import '../../../subjects/domain/entities/subject.dart';

abstract class AnalyticsEvent {}

class LoadAnalyticsEvent extends AnalyticsEvent {
  final List<Subject> subjects;

  LoadAnalyticsEvent(this.subjects);
}

class SelectAnalyticsDayEvent extends AnalyticsEvent {
  final int dayIndex;

  SelectAnalyticsDayEvent(this.dayIndex);
}
