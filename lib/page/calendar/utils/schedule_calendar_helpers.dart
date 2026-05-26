import 'package:todolist/features/schedule/services/schedule_date_service.dart';
import 'package:todolist/features/schedule/services/schedule_time_service.dart';
import 'package:todolist/model/schedule/schedule.dart';
import 'package:todolist/page/schedule/schedule_controller.dart';

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

String? scheduleWeekLabelForDate(ScheduleController controller, DateTime date) {
  final semester = controller.selectedSemester;
  if (semester == null) {
    return null;
  }
  return ScheduleDateService.dayContextForDate(semester, date)?.weekLabel;
}

String scheduleSessionTimeRange(
  ScheduleSemesterModel semester,
  ScheduleSessionModel session,
) {
  return ScheduleTimeService.sessionTimeRange(semester, session);
}
