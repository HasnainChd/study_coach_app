import 'package:flutter_test/flutter_test.dart';
import 'package:study_coach_app/features/focus/focus_agenda_session.dart';
import 'package:study_coach_app/features/subjects/domain/entities/agenda_item.dart';
import 'package:flutter/material.dart';

void main() {
  final items = [
    AgendaItem(
      id: 'a',
      title: 'A',
      tag: 'X',
      durationMinutes: 10,
      tagColor: Colors.red,
    ),
    AgendaItem(
      id: 'b',
      title: 'B',
      tag: 'X',
      durationMinutes: 10,
      tagColor: Colors.red,
    ),
    AgendaItem(
      id: 'c',
      title: 'C',
      tag: 'X',
      durationMinutes: 10,
      tagColor: Colors.red,
    ),
  ];

  test('skip path index+1 never selects earlier agenda item', () {
    final currentId = 'b';
    final currentIndex = items.indexWhere((i) => i.id == currentId);
    final next = agendaItemAtIndex(items, currentIndex + 1);

    expect(currentIndex, 1);
    expect(next?.id, 'c');
    expect(next?.id, isNot('a'));
  });

  test('forward scan skips completed tasks without restarting from index 0', () {
    final withBComplete = [
      items[0],
      items[1].copyWith(isCompleted: true),
      items[2],
    ];

    expect(
      agendaNextIncompleteItemForward(withBComplete, 'a')?.id,
      'c',
    );
    expect(agendaSessionNumber(withBComplete, 'c'), 3);
  });

  test('forward scan returns null when only completed tasks remain ahead', () {
    final allAheadComplete = [
      items[0],
      items[1].copyWith(isCompleted: true),
      items[2].copyWith(isCompleted: true),
    ];

    expect(agendaNextIncompleteItemForward(allAheadComplete, 'a'), isNull);

    final onlyCLeft = [
      items[0].copyWith(isCompleted: true),
      items[1].copyWith(isCompleted: true),
      items[2],
    ];

    expect(agendaNextIncompleteItemForward(onlyCLeft, 'b')?.id, 'c');
    expect(agendaNextIncompleteItemForward(onlyCLeft, 'c'), isNull);
  });

  test('forward scan never picks an earlier item when middle task is current', () {
    final withAComplete = [
      items[0].copyWith(isCompleted: true),
      items[1],
      items[2],
    ];

    expect(
      agendaNextIncompleteItemForward(withAComplete, 'b')?.id,
      'c',
    );
    expect(
      agendaNextIncompleteItemForward(withAComplete, 'b')?.id,
      isNot('a'),
    );
  });

  test('derived session number stable across repeated skip flows', () {
    expect(agendaSessionNumber(items, 'a'), 1);
    expect(agendaSessionNumber(items, 'b'), 2);
    expect(agendaSessionNumber(items, 'c'), 3);
    expect(agendaTotalSessions(items), 3);

    // Simulate second pass through same agenda — derivation unchanged
    expect(agendaSessionNumber(items, 'a'), 1);
    expect(agendaSessionNumber(items, 'b'), 2);
    expect(agendaSessionNumber(items, 'c'), 3);
  });
}
