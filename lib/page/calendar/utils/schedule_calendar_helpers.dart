import 'package:todolist/features/schedule/services/schedule_date_service.dart';
import 'package:todolist/features/schedule/services/schedule_time_service.dart';
import 'package:todolist/model/schedule/schedule.dart';
import 'package:todolist/page/schedule/schedule_controller.dart';

/// 查询指定日期在当前选中学期中的课程。
///
/// helper 只把页面层的 Controller 状态转交给 `ScheduleDateService`，
/// 不在这里保存课表或修改选中日期。
List<ScheduleSessionModel> scheduleSessionsForDate(
  ScheduleController controller,
  DateTime date,
) {
  final semester = controller.selectedSemester;
  if (semester == null) {
    return <ScheduleSessionModel>[];
  }
  return ScheduleDateService.sessionsForDate(semester, date);
}

/// 查询指定日期对应的课表周标签，例如“上半三周”。
///
/// 日期不在当前学期范围内时返回 null，页面据此隐藏周次标题。
String? scheduleWeekLabelForDate(ScheduleController controller, DateTime date) {
  final semester = controller.selectedSemester;
  if (semester == null) {
    return null;
  }
  return ScheduleDateService.dayContextForDate(semester, date)?.weekLabel;
}

/// 格式化课程节次时间范围，保持月历课程卡和课表详情使用同一套时间规则。
String scheduleSessionTimeRange(
  ScheduleSemesterModel semester,
  ScheduleSessionModel session,
) {
  return ScheduleTimeService.sessionTimeRange(semester, session);
}
