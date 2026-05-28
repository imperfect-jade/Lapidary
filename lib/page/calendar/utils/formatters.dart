import 'package:flutter/material.dart';
import 'package:todolist/model/schedule/schedule.dart';

/// 根据任务优先级返回月历任务标记色。
///
/// 这里只做展示映射，不修改任务优先级或主题配置。
Color calendarPriorityColor(int? priority) {
  return switch (priority) {
    1 => Colors.red,
    2 => Colors.orange,
    3 => Colors.blue,
    4 => Colors.grey,
    _ => Colors.grey,
  };
}

/// 格式化日历时间为 `HH:mm`，供事项卡片和详情展示使用。
String formatCalendarTime(DateTime dt) {
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

/// 格式化日历日期时间为 `M月D日 HH:mm`。
String formatCalendarDateTime(DateTime dt) {
  return '${dt.month}月${dt.day}日 ${formatCalendarTime(dt)}';
}

/// 展示可选课程字段，空值统一回退为“未填写”。
String scheduleValueOrFallback(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) {
    return '未填写';
  }
  return text;
}

/// 格式化课程重复规则。
///
/// 自定义周优先展示具体周次；否则按单双周组合展示。
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

/// 格式化课程所属半学期范围。
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

/// 格式化课程学分，整数不显示小数位。
String formatScheduleCredit(double credit) {
  if (credit == credit.roundToDouble()) {
    return credit.toInt().toString();
  }
  return credit.toStringAsFixed(1);
}
