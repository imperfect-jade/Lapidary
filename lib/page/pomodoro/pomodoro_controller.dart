import 'dart:async';
import 'package:get/get.dart';
import 'package:todolist/data/repositories/pomodoro_repository.dart';
import 'package:todolist/features/productivity/services/productivity_feedback_service.dart';
import 'package:todolist/model/pomodoro/pomodoro.dart';

/// 番茄钟业务控制器。
///
/// 负责计时状态、当前任务关联、今日统计、番茄钟记录保存，以及专注/休息完成后的奖励和宠物反馈编排。
class PomodoroController extends GetxController {
  PomodoroController(
    this.repository, [
    ProductivityFeedbackService? feedbackService,
  ]) : feedbackService = feedbackService ?? ProductivityFeedbackService.noop();

  final PomodoroRepository repository;
  final ProductivityFeedbackService feedbackService;

  // 计时状态：驱动页面在空闲态、运行态和暂停态之间切换。
  final isRunning = false.obs;
  final isPaused = false.obs;
  final remainingSeconds = 0.obs;

  // 当前模式：focus 表示专注，break 表示休息；模式决定时长、颜色、反馈和记录类型。
  final currentMode = 'focus'.obs;

  // 当前专注关联的待办任务；为空时表示自由专注。
  final currentTaskId = RxnString();
  final currentTaskTitle = RxnString();

  // 用户可在设置弹窗中调整的时长，单位为分钟，只影响后续新一轮计时。
  final focusDuration = 25.obs;
  final breakDuration = 5.obs;

  // 今日统计：由历史记录初始化，专注完成后即时累加用于运行期展示。
  final todayFocusMinutes = 0.obs;
  final todayPomodoroCount = 0.obs;

  // 内部计时器和计时快照，不直接暴露给 UI。
  Timer? _timer;
  DateTime? _startTime;
  int _accumulatedSeconds = 0;

  @override
  void onInit() {
    super.onInit();
    _loadTodayStats();
  }

  /// 从历史记录中加载当天已完成专注统计。
  ///
  /// 只统计今日、focus 类型且已完成的记录；未完成和休息记录不会计入今日专注数据。
  void _loadTodayStats() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayRecords = repository.getAll().where(
      (r) =>
          r.startTime.isAfter(todayStart) && r.type == 'focus' && r.isCompleted,
    );
    todayFocusMinutes.value = todayRecords.fold(
      0,
      (sum, r) => sum + (r.actualSeconds ~/ 60),
    );
    todayPomodoroCount.value = todayRecords.length;
  }

  /// 开始一轮专注计时。
  ///
  /// 可选择关联一个任务；开始时会触发跨模块服务，让宠物进入专注陪伴反馈。
  void startFocus({String? taskId, String? taskTitle}) {
    currentTaskId.value = taskId;
    currentTaskTitle.value = taskTitle;
    currentMode.value = 'focus';
    _startTimer(focusDuration.value * 60);
    feedbackService.handleFocusStarted(taskTitle);
  }

  /// 开始一轮休息计时。
  ///
  /// 通常由专注完成后自动调用，也可以在后续扩展中作为手动休息入口复用。
  void startBreak() {
    currentMode.value = 'break';
    _startTimer(breakDuration.value * 60);
  }

  /// 启动内部秒级计时器。
  ///
  /// 每秒扣减剩余秒数并累加实际计时秒数；倒计时结束后统一进入完成处理流程。
  void _startTimer(int seconds) {
    remainingSeconds.value = seconds;
    isRunning.value = true;
    isPaused.value = false;
    _startTime = DateTime.now();
    _accumulatedSeconds = 0;

    // 开始新一轮计时前先取消旧计时器，避免多个 Timer 同时扣减剩余时间。
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
        _accumulatedSeconds++;
      } else {
        _onTimerComplete();
      }
    });
  }

  /// 处理一轮计时自然完成。
  ///
  /// 完成后会保存记录、触发奖励/宠物反馈；专注完成后自动进入休息，休息完成后回到下一轮专注准备态。
  Future<void> _onTimerComplete() async {
    _timer?.cancel();
    isRunning.value = false;
    isPaused.value = false;
    final completedMode = currentMode.value;
    final completedSeconds = _accumulatedSeconds;

    await _saveRecord(
      isCompleted: true,
      mode: completedMode,
      actualSeconds: completedSeconds,
    );

    if (completedMode == 'focus') {
      // 专注完成：即时更新今日统计，随后提示用户休息并自动启动休息计时。
      todayFocusMinutes.value += completedSeconds ~/ 60;
      todayPomodoroCount.value++;
      _accumulatedSeconds = 0;
      Get.snackbar('专注完成！', '休息一下吧~', snackPosition: SnackPosition.BOTTOM);
      startBreak();
    } else {
      // 休息完成：回到专注准备状态，不自动开始下一轮专注。
      Get.snackbar('休息结束', '准备好继续专注了吗？', snackPosition: SnackPosition.BOTTOM);
      _accumulatedSeconds = 0;
      currentMode.value = 'focus';
      remainingSeconds.value = focusDuration.value * 60;
    }
  }

  /// 暂停当前计时。
  ///
  /// 暂停只取消 Timer，不保存记录；继续时会从当前剩余秒数恢复。
  void pause() {
    isPaused.value = true;
    _timer?.cancel();
  }

  /// 从暂停状态继续计时。
  ///
  /// 如果当前没有处于暂停状态，调用会被忽略，避免重复创建计时器。
  void resume() {
    if (!isPaused.value) {
      return;
    }
    isPaused.value = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
        _accumulatedSeconds++;
      } else {
        _onTimerComplete();
      }
    });
  }

  /// 放弃当前计时。
  ///
  /// 放弃会保存一条未完成记录，用于保留历史；不会触发完成奖励，但仍交给反馈服务处理记录后的通用联动。
  Future<void> giveUp() async {
    final mode = currentMode.value;
    _timer?.cancel();
    isRunning.value = false;
    isPaused.value = false;

    await _saveRecord(isCompleted: false, mode: mode);
    _accumulatedSeconds = 0;
    currentMode.value = 'focus';
    remainingSeconds.value = focusDuration.value * 60;
    currentTaskId.value = null;
    currentTaskTitle.value = null;
  }

  /// 保存番茄钟记录，并通知跨模块反馈服务。
  ///
  /// 反馈服务会根据记录类型和完成状态处理奖励、宠物精力消耗或休息恢复。
  Future<void> _saveRecord({
    required bool isCompleted,
    required String mode,
    int? actualSeconds,
  }) async {
    final startedAt = _startTime;
    if (startedAt == null) {
      // 没有开始时间说明计时未真正启动，避免写入不完整记录。
      return;
    }
    final record = PomodoroModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taskId: currentTaskId.value,
      taskTitle: currentTaskTitle.value,
      durationMinutes: mode == 'focus'
          ? focusDuration.value
          : breakDuration.value,
      actualSeconds: actualSeconds ?? _accumulatedSeconds,
      startTime: startedAt,
      endTime: DateTime.now(),
      isCompleted: isCompleted,
      type: mode,
    );

    await repository.put(record);
    await feedbackService.handlePomodoroRecordSaved(record);
  }

  /// 当前剩余时间的 `MM:ss` 展示文本。
  String get formattedTime {
    final minutes = remainingSeconds.value ~/ 60;
    final seconds = remainingSeconds.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 当前计时进度，返回 0 到 1 之间的比例供环形进度条使用。
  double get progress {
    final total = currentMode.value == 'focus'
        ? focusDuration.value * 60
        : breakDuration.value * 60;
    return 1 - (remainingSeconds.value / total);
  }

  @override
  void onClose() {
    // Controller 销毁时取消计时器，避免页面退出后仍继续回调。
    _timer?.cancel();
    super.onClose();
  }
}
