part of '../calendar.dart';

List<ScheduleSessionModel> _scheduleSessionsForDate(
  ScheduleController controller,
  DateTime date,
) {
  final semester = controller.selectedSemester;
  if (semester == null) {
    return <ScheduleSessionModel>[];
  }
  return ScheduleDateService.sessionsForDate(semester, date);
}

String? _scheduleWeekLabelForDate(
  ScheduleController controller,
  DateTime date,
) {
  final semester = controller.selectedSemester;
  if (semester == null) {
    return null;
  }
  return ScheduleDateService.dayContextForDate(semester, date)?.weekLabel;
}

String _scheduleSessionTimeRange(
  ScheduleSemesterModel semester,
  ScheduleSessionModel session,
) {
  return ScheduleTimeService.sessionTimeRange(semester, session);
}
