import 'agenda_item.dart';

class StudyPlanResult {
  final List<AgendaItem> agendaItems;
  final String? budgetWarningMessage;

  const StudyPlanResult({
    required this.agendaItems,
    this.budgetWarningMessage,
  });
}
