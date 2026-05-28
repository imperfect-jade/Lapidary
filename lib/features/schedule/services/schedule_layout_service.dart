import 'package:todolist/model/schedule/schedule.dart';

/// 课表网格中的一个可渲染课程块。
///
/// start/end 表示该 block 覆盖的节次范围；sessions 可能包含多个重叠课程。
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

/// 课表布局服务，负责把同一天课程合并成可定位的网格块。
///
/// 这是纯逻辑服务，不依赖 Flutter Widget；UI 只根据输出 block 计算 top/bottom。
class ScheduleLayoutService {
  /// 将课程列表合并为非重叠 block。
  ///
  /// 重叠课程会合并成一个 block；同一课程多段时间按 id 去重并合并节次，
  /// 保持原有“冲突课程合并展示”的行为。
  static List<ScheduleLayoutBlock> buildBlocks(
    List<ScheduleSessionModel> sessions,
  ) {
    // 没有节次的课程无法定位到网格，直接排除。
    final validSessions = sessions
        .where((session) => session.time.isNotEmpty)
        .toList();
    final ranges = <_MutableScheduleBlock>[];
    for (final session in validSessions) {
      // 先用课程自身节次区间找到所有相交 block，并扩展成合并后的总区间。
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
      // block 内按课程 id 去重；没有 id 时使用课程名、星期和起始节兜底。
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
          // 同一课程拆成多段时合并节次列表，详情中仍作为一门课展示。
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

/// 内部可变布局区间，只用于 buildBlocks 合并计算。
class _MutableScheduleBlock {
  final int start;
  final int end;

  const _MutableScheduleBlock(this.start, this.end);
}
