import 'package:get/get.dart';
import 'package:todolist/data/hive/box_names.dart';
import 'package:todolist/data/repositories/schedule_repository.dart';
import 'package:todolist/features/schedule/services/schedule_date_service.dart';
import 'package:todolist/model/schedule/schedule.dart';

/// 日历页内容模式：普通月历或课表网格。
enum CalendarContentView { month, schedule }

/// 课表控制器，管理学期列表、选中学期、半学期视图和课程增删改。
///
/// Controller 只负责 GetX 状态和通过 Repository 持久化学期模型；
/// 日期生成、课程过滤、布局合并和时间格式化都交给 feature 层服务。
class ScheduleController extends GetxController {
  ScheduleController(this.repository);

  static const String semesterBoxName = BoxNames.scheduleSemesters;

  // Repository 封装 Hive Box 读写，Controller 不直接持有 Box。
  final ScheduleRepository repository;
  // 当前日历内容模式，CalendarPage 根据它在月历和课表之间切换。
  final viewMode = CalendarContentView.month.obs;
  // 已保存的学期列表，loadSemesters 会按 id 倒序刷新。
  final semesters = <ScheduleSemesterModel>[].obs;
  // 当前选中学期 id；为空或失效时回退到列表第一项。
  final selectedSemesterId = RxnString();
  // 当前展示上半还是下半学期，影响 sessionsByDayOfWeek 派生结果。
  final useFirstHalf = true.obs;
  // 是否隐藏课程名称/地点，适合公共场景查看课表时保护隐私。
  final hideCourseInformation = false.obs;

  /// 当前选中的学期。
  ///
  /// 如果记录的 id 已不存在，会回退到第一个学期，避免 UI 因空选择崩溃。
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

  /// 当前半学期按星期分组后的课程列表。
  ///
  /// 课表网格直接读取该派生值，不在 UI 层重复判断上半/下半学期。
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
    // 初始化时从本地仓储加载学期，保持应用启动后课表页可直接展示。
    loadSemesters();
  }

  /// 切换日历页内容模式，月历和课表共用同一个 CalendarPage。
  void changeViewMode(CalendarContentView mode) {
    viewMode.value = mode;
  }

  /// 选择当前学期，只更新选中 id，不改变学期内容。
  void selectSemester(String id) {
    selectedSemesterId.value = id;
  }

  /// 切换上半/下半学期视图。
  void selectHalf(bool firstHalf) {
    useFirstHalf.value = firstHalf;
  }

  /// 切换课程信息隐藏状态，只影响课表卡片展示，不修改课程模型。
  void toggleHiddenInformation() {
    hideCourseInformation.toggle();
  }

  /// 从 Repository 重新加载学期列表。
  ///
  /// 新增、编辑、删除课程后都会调用它，确保派生课表和菜单选项同步刷新。
  void loadSemesters() {
    final items = repository.getAll()..sort((a, b) => b.id.compareTo(a.id));
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

  /// 创建学期并生成上下半学期的日期映射表。
  ///
  /// 日期表生成由 `ScheduleDateService` 负责；保存成功后自动选中新学期并回到上半学期。
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
      dayOfWeekToDays: ScheduleDateService.buildDayOfWeekToDays(
        firstHalfStart: firstHalfStart,
        firstHalfEnd: firstHalfEnd,
        secondHalfStart: secondHalfStart,
        secondHalfEnd: secondHalfEnd,
      ),
    );
    await repository.put(semester);
    selectedSemesterId.value = id;
    useFirstHalf.value = true;
    loadSemesters();
  }

  /// 向当前学期新增课程。
  ///
  /// 新课程若没有 id，会在这里补本地 id；保存后刷新学期列表和课表 UI。
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

  /// 更新当前学期中的已有课程。
  ///
  /// 通过 session id 查找原课程，未找到时直接返回，避免误写其他课程。
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

  /// 删除当前学期中的课程。
  ///
  /// 这里只删除课表课程，不影响任务、系统日历事件或其他学期。
  Future<void> deleteSession(ScheduleSessionModel session) async {
    final semester = selectedSemester;
    if (semester == null) {
      return;
    }
    semester.sessions.removeWhere((item) => item.id == session.id);
    await _saveSemester(semester);
  }

  /// 返回空的星期分组列表。
  ///
  /// 列表保留 0-7 共 8 个位置，方便 UI 用 weekday 作为索引。
  List<List<ScheduleSessionModel>> emptyDaySessionList() {
    return <List<ScheduleSessionModel>>[[], [], [], [], [], [], [], []];
  }

  /// 保存学期并刷新课表状态。
  ///
  /// 所有课程增删改都收口到这里，保持持久化和响应式刷新顺序一致。
  Future<void> _saveSemester(ScheduleSemesterModel semester) async {
    await repository.put(semester);
    loadSemesters();
    semesters.refresh();
  }
}
