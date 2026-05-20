import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todolist/model/schedule/schedule.dart';

enum CalendarContentView { month, schedule }

class ScheduleController extends GetxController {
  static const String semesterBoxName = 'schedule_semesters';

  final viewMode = CalendarContentView.month.obs;
  final semesters = <ScheduleSemesterModel>[].obs;
  final selectedSemesterId = RxnString();
  final useFirstHalf = true.obs;
  final hideCourseInformation = false.obs;

  late Box<ScheduleSemesterModel> semesterBox;

  ScheduleSemesterModel? get selectedSemester {
    final id = selectedSemesterId.value;
    if (id == null) {
      return semesters.isEmpty ? null : semesters.first;
    }
    for (final semester in semesters) {
      if (semester.id == id) {
        return semester;
      }
    }
    return semesters.isEmpty ? null : semesters.first;
  }

  List<List<ScheduleSessionModel>> get sessionsByDayOfWeek {
    final semester = selectedSemester;
    if (semester == null) {
      return emptyDaySessionList();
    }
    return useFirstHalf.value
        ? semester.firstHalfTimetable
        : semester.secondHalfTimetable;
  }

  @override
  void onInit() {
    super.onInit();
    semesterBox = Hive.box<ScheduleSemesterModel>(semesterBoxName);
    loadSemesters();
  }

  void changeViewMode(CalendarContentView mode) {
    viewMode.value = mode;
  }

  void selectSemester(String id) {
    selectedSemesterId.value = id;
  }

  void selectHalf(bool firstHalf) {
    useFirstHalf.value = firstHalf;
  }

  void toggleHiddenInformation() {
    hideCourseInformation.toggle();
  }

  void loadSemesters() {
    final items = semesterBox.values.toList()
      ..sort((a, b) => b.id.compareTo(a.id));
    semesters.value = items;
    if (items.isEmpty) {
      selectedSemesterId.value = null;
      return;
    }
    final selectedId = selectedSemesterId.value;
    if (selectedId == null || !items.any((item) => item.id == selectedId)) {
      selectedSemesterId.value = items.first.id;
    }
  }

  Future<void> createSemester({
    required String name,
    required DateTime firstHalfStart,
    required DateTime firstHalfEnd,
    required DateTime secondHalfStart,
    required DateTime secondHalfEnd,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final semester = ScheduleSemesterModel(
      id: id,
      name: name,
      dayOfWeekToDays: _buildDayOfWeekToDays(
        firstHalfStart: firstHalfStart,
        firstHalfEnd: firstHalfEnd,
        secondHalfStart: secondHalfStart,
        secondHalfEnd: secondHalfEnd,
      ),
    );
    await semesterBox.put(id, semester);
    selectedSemesterId.value = id;
    useFirstHalf.value = true;
    loadSemesters();
  }

  Future<void> addSession(ScheduleSessionModel session) async {
    final semester = selectedSemester;
    if (semester == null) {
      return;
    }
    final sessionToSave = session.copyWith(
      id: session.id ?? 'local_${DateTime.now().microsecondsSinceEpoch}',
    );
    semester.sessions.add(sessionToSave);
    await _saveSemester(semester);
  }

  Future<void> updateSession(ScheduleSessionModel session) async {
    final semester = selectedSemester;
    if (semester == null) {
      return;
    }
    final index = semester.sessions.indexWhere((item) => item.id == session.id);
    if (index < 0) {
      return;
    }
    semester.sessions[index] = session;
    await _saveSemester(semester);
  }

  Future<void> deleteSession(ScheduleSessionModel session) async {
    final semester = selectedSemester;
    if (semester == null) {
      return;
    }
    semester.sessions.removeWhere((item) => item.id == session.id);
    await _saveSemester(semester);
  }

  List<List<ScheduleSessionModel>> emptyDaySessionList() {
    return <List<ScheduleSessionModel>>[[], [], [], [], [], [], [], []];
  }

  Future<void> _saveSemester(ScheduleSemesterModel semester) async {
    await semesterBox.put(semester.id, semester);
    loadSemesters();
    semesters.refresh();
  }

  List<List<List<List<DateTime>>>> _buildDayOfWeekToDays({
    required DateTime firstHalfStart,
    required DateTime firstHalfEnd,
    required DateTime secondHalfStart,
    required DateTime secondHalfEnd,
  }) {
    final result = ScheduleSemesterModel.emptyDayOfWeekToDays();
    _fillHalfDays(firstHalfStart, firstHalfEnd, result[0]);
    _fillHalfDays(secondHalfStart, secondHalfEnd, result[1]);
    return result;
  }

  void _fillHalfDays(
    DateTime start,
    DateTime end,
    List<List<List<DateTime>>> target,
  ) {
    var weekday = start.weekday;
    var oddEvenWeek = 0;
    for (
      var day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      target[oddEvenWeek][weekday].add(day);
      weekday++;
      if (weekday == 8) {
        weekday = 1;
        oddEvenWeek = 1 - oddEvenWeek;
      }
    }
  }
}
