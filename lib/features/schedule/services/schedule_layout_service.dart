import 'package:todolist/model/schedule/schedule.dart';

class ScheduleLayoutBlock {
  final int start;
  final int end;
  final List<ScheduleSessionModel> sessions;

  const ScheduleLayoutBlock({
    required this.start,
    required this.end,
    required this.sessions,
  });
}

class ScheduleLayoutService {
  static List<ScheduleLayoutBlock> buildBlocks(
    List<ScheduleSessionModel> sessions,
  ) {
    final validSessions = sessions
        .where((session) => session.time.isNotEmpty)
        .toList();
    final ranges = <_MutableScheduleBlock>[];
    for (final session in validSessions) {
      var start = session.time.first;
      var end = session.time.last;
      final overlapping = ranges
          .where((block) => !(block.end < start || end < block.start))
          .toList();
      for (final block in overlapping) {
        if (block.start < start) {
          start = block.start;
        }
        if (block.end > end) {
          end = block.end;
        }
      }
      ranges.removeWhere((block) => overlapping.contains(block));
      ranges.add(_MutableScheduleBlock(start, end));
    }
    ranges.sort((a, b) => a.start.compareTo(b.start));
    return ranges.map((block) {
      final byId = <String, ScheduleSessionModel>{};
      for (final session in validSessions) {
        final start = session.time.first;
        final end = session.time.last;
        if (block.end < start || end < block.start) {
          continue;
        }
        final key = session.id ?? '${session.name}_${session.dayOfWeek}_$start';
        final existing = byId[key];
        if (existing == null) {
          byId[key] = session.copyWith(time: List<int>.from(session.time));
        } else {
          final timeSet = <int>{...existing.time, ...session.time}.toList()
            ..sort();
          byId[key] = existing.copyWith(time: timeSet);
        }
      }
      return ScheduleLayoutBlock(
        start: block.start,
        end: block.end,
        sessions: List.unmodifiable(byId.values),
      );
    }).toList();
  }
}

class _MutableScheduleBlock {
  final int start;
  final int end;

  const _MutableScheduleBlock(this.start, this.end);
}
