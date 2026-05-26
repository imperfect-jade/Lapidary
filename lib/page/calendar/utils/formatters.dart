import 'package:flutter/material.dart';
import 'package:todolist/model/schedule/schedule.dart';

Color calendarPriorityColor(int? priority) {
  return switch (priority) {
    1 => Colors.red,
    2 => Colors.orange,
    3 => Colors.blue,
    4 => Colors.grey,
    _ => Colors.grey,
  };
}

String formatCalendarTime(DateTime dt) {
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

String formatCalendarDateTime(DateTime dt) {
  return '${dt.month}月${dt.day}日 ${formatCalendarTime(dt)}';
}

String scheduleValueOrFallback(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) {
    return '未填写';
  }
  return text;
}

String formatScheduleRepeat(ScheduleSessionModel session) {
  if (session.customRepeat) {
    if (session.customRepeatWeeks.isEmpty) {
      return '自定义周';
    }
    return '第${session.customRepeatWeeks.join('、')}周';
  }
  if (session.oddWeek && session.evenWeek) {
    return '每周';
  }
  if (session.oddWeek) {
    return '单周';
  }
  if (session.evenWeek) {
    return '双周';
  }
  return '未设置';
}

String formatScheduleHalfRange(ScheduleSessionModel session) {
  if (session.firstHalf && session.secondHalf) {
    return '上半学期、下半学期';
  }
  if (session.firstHalf) {
    return '上半学期';
  }
  if (session.secondHalf) {
    return '下半学期';
  }
  return '未设置';
}

String formatScheduleCredit(double credit) {
  if (credit == credit.roundToDouble()) {
    return credit.toInt().toString();
  }
  return credit.toStringAsFixed(1);
}
