import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/features/schedule/services/schedule_color_service.dart';
import 'package:todolist/features/schedule/services/schedule_date_service.dart';
import 'package:todolist/features/schedule/services/schedule_layout_service.dart';
import 'package:todolist/features/schedule/services/schedule_time_service.dart';
import 'package:todolist/model/schedule/schedule.dart';

void main() {
  group('ScheduleDateService', () {
    test('builds half-day tables across weeks', () {
      final table = ScheduleDateService.buildDayOfWeekToDays(
        firstHalfStart: DateTime(2026, 5, 6),
        firstHalfEnd: DateTime(2026, 5, 13),
        secondHalfStart: DateTime(2026, 6, 1),
        secondHalfEnd: DateTime(2026, 6, 7),
      );

      expect(table[0][0][3].single, DateTime(2026, 5, 6));
      expect(table[0][0][7].single, DateTime(2026, 5, 10));
      expect(table[0][1][1].single, DateTime(2026, 5, 11));
      expect(table[0][1][3].single, DateTime(2026, 5, 13));
      expect(table[1][0][1].single, DateTime(2026, 6));
      expect(table[1][0][7].single, DateTime(2026, 6, 7));
    });

    test('finds day context and week label for dates', () {
      final semester = _semester();

      final firstWeek = ScheduleDateService.dayContextForDate(
        semester,
        DateTime(2026, 5, 6, 18),
      );
      final secondWeek = ScheduleDateService.dayContextForDate(
        semester,
        DateTime(2026, 5, 11),
      );
      final outside = ScheduleDateService.dayContextForDate(
        semester,
        DateTime(2026, 7),
      );

      expect(firstWeek, isNotNull);
      expect(firstWeek!.halfIndex, 0);
      expect(firstWeek.oddEvenIndex, 0);
      expect(firstWeek.weekNumber, 1);
      expect(firstWeek.weekLabel, '上半一周');
      expect(secondWeek, isNotNull);
      expect(secondWeek!.oddEvenIndex, 1);
      expect(secondWeek.weekNumber, 2);
      expect(outside, isNull);
    });

    test('filters sessions for a date', () {
      final semester = _semester(
        sessions: [
          _session(id: 'odd', name: '单周课', time: [3], oddWeek: true),
          _session(
            id: 'custom',
            name: '自定义周课',
            time: [1],
            customRepeat: true,
            customRepeatWeeks: [1, 3, 5],
          ),
          _session(
            id: 'unconfirmed',
            name: '未确认',
            time: [2],
            confirmed: false,
            oddWeek: true,
          ),
          _session(id: 'other-day', name: '周四课', dayOfWeek: 4, time: [1]),
          _session(
            id: 'second-half',
            name: '下半学期课',
            time: [1],
            firstHalf: false,
            secondHalf: true,
            oddWeek: true,
          ),
          _session(id: 'even', name: '双周课', time: [1], evenWeek: true),
          _session(
            id: 'hidden-custom',
            name: '隐藏自定义周课',
            time: [1],
            customRepeat: true,
            customRepeatWeeks: [1],
          ),
          _session(
            id: 'custom-miss',
            name: '未命中自定义周课',
            time: [1],
            customRepeat: true,
            customRepeatWeeks: [3, 5, 7],
          ),
        ],
      );

      final sessions = ScheduleDateService.sessionsForDate(
        semester,
        DateTime(2026, 5, 6),
      );

      expect(sessions.map((session) => session.id), ['custom', 'odd']);
    });
  });

  group('ScheduleTimeService', () {
    test('formats section and session time ranges', () {
      final semester = _semester();

      expect(ScheduleTimeService.sectionStartTime(semester, 1), '08:00');
      expect(ScheduleTimeService.sectionEndTime(semester, 2), '09:35');
      expect(ScheduleTimeService.sectionStartTime(semester, 99), '--:--');
      expect(ScheduleTimeService.sectionEndTime(semester, 0), '--:--');
      expect(
        ScheduleTimeService.sessionTimeRange(semester, _session(time: [1, 2])),
        '08:00 - 09:35',
      );
      expect(
        ScheduleTimeService.sessionTimeRange(semester, _session(time: [])),
        '未设置时间',
      );
    });
  });

  group('ScheduleLayoutService', () {
    test('merges overlapping blocks and deduplicates sessions by id', () {
      final blocks = ScheduleLayoutService.buildBlocks([
        _session(id: 'a', name: 'A', time: [1, 2]),
        _session(id: 'b', name: 'B', time: [4]),
        _session(id: 'c', name: 'C', time: [2, 3]),
        _session(id: 'same', name: 'D', time: [8]),
        _session(id: 'same', name: 'D', time: [8, 9]),
        _session(id: 'empty', name: '空时间', time: []),
      ]);

      expect(blocks, hasLength(3));
      expect(blocks[0].start, 1);
      expect(blocks[0].end, 3);
      expect(blocks[0].sessions.map((session) => session.id), ['a', 'c']);
      expect(blocks[1].start, 4);
      expect(blocks[1].end, 4);
      expect(blocks[1].sessions.single.id, 'b');
      expect(blocks[2].start, 8);
      expect(blocks[2].end, 9);
      expect(blocks[2].sessions.single.id, 'same');
      expect(blocks[2].sessions.single.time, [8, 9]);
    });
  });

  group('ScheduleColorService', () {
    test('returns stable usable colors for sessions and themes', () {
      final session = _session(id: 'color-1', name: '颜色课', time: [1]);
      final green = _palette('green');
      final dark = _palette('dark');

      final first = ScheduleColorService.colorForSession(session, green);
      final second = ScheduleColorService.colorForSession(session, green);
      final darkColor = ScheduleColorService.colorForSession(session, dark);

      expect(first, second);
      expect(first, isA<Color>());
      expect(darkColor, isA<Color>());
      expect(ThemeData.estimateBrightnessForColor(first), isA<Brightness>());
      expect(
        ThemeData.estimateBrightnessForColor(darkColor),
        isA<Brightness>(),
      );
    });
  });
}

ScheduleSemesterModel _semester({List<ScheduleSessionModel>? sessions}) {
  return ScheduleSemesterModel(
    id: 'semester-1',
    name: '短名',
    sessions: sessions,
    dayOfWeekToDays: ScheduleDateService.buildDayOfWeekToDays(
      firstHalfStart: DateTime(2026, 5, 6),
      firstHalfEnd: DateTime(2026, 5, 13),
      secondHalfStart: DateTime(2026, 6, 1),
      secondHalfEnd: DateTime(2026, 6, 7),
    ),
  );
}

ScheduleSessionModel _session({
  String? id = 'session-1',
  String name = '测试课程',
  String teacher = '测试老师',
  int dayOfWeek = 3,
  List<int>? time,
  bool confirmed = true,
  bool firstHalf = true,
  bool secondHalf = false,
  bool oddWeek = false,
  bool evenWeek = false,
  bool customRepeat = false,
  List<int>? customRepeatWeeks,
}) {
  return ScheduleSessionModel(
    id: id,
    name: name,
    teacher: teacher,
    confirmed: confirmed,
    dayOfWeek: dayOfWeek,
    time: time ?? [1],
    firstHalf: firstHalf,
    secondHalf: secondHalf,
    oddWeek: oddWeek,
    evenWeek: evenWeek,
    customRepeat: customRepeat,
    customRepeatWeeks: customRepeatWeeks,
  );
}

AppThemePalette _palette(String key) {
  return ThemeController.palettes.firstWhere((palette) => palette.key == key);
}
