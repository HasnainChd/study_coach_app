import '../subjects/domain/entities/agenda_item.dart';

/// Agenda-derived session position for focus timer UI (not stored in TimerBloc).
int agendaSessionNumber(List<AgendaItem> items, String? taskId) {
  if (items.isEmpty || taskId == null) return 1;
  final index = items.indexWhere((item) => item.id == taskId);
  return index < 0 ? 1 : index + 1;
}

int agendaTotalSessions(List<AgendaItem> items) {
  return items.isEmpty ? 1 : items.length;
}

AgendaItem? agendaItemAtIndex(List<AgendaItem> items, int index) {
  if (index < 0 || index >= items.length) return null;
  return items[index];
}

AgendaItem? agendaNextItemAtIndex(List<AgendaItem> items, String? taskId) {
  if (items.isEmpty || taskId == null) return null;
  final currentIndex = items.indexWhere((item) => item.id == taskId);
  if (currentIndex < 0) return null;
  return agendaItemAtIndex(items, currentIndex + 1);
}

/// Forward-only scan from [currentIndex + 1] for the next incomplete agenda item.
/// Never restarts from index 0.
AgendaItem? agendaNextIncompleteItemForward(
  List<AgendaItem> items,
  String? taskId,
) {
  if (items.isEmpty || taskId == null) return null;
  final currentIndex = items.indexWhere((item) => item.id == taskId);
  if (currentIndex < 0) return null;

  for (var i = currentIndex + 1; i < items.length; i++) {
    if (!items[i].isCompleted) {
      return items[i];
    }
  }
  return null;
}

/// Short break after sessions 1–3 of each Pomodoro group; long break after every 4th
/// agenda slot (position-based, not a lifetime counter).
bool isLongBreakForAgendaSession(int sessionNumber) {
  return sessionNumber > 0 && sessionNumber % 4 == 0;
}
