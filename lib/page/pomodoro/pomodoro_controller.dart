//番茄钟控制器
import 'dart:async';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:todolist/model/pomodoro/pomodoro.dart';

class PomodoroController extends GetxController
{
  // ========== 状态变量 ==========
  
  // 计时状态
  final isRunning = false.obs;
  final isPaused = false.obs;
  final remainingSeconds = 0.obs;
  
  // 模式：focus(专注) / break(休息)
  final currentMode = 'focus'.obs;
  
  // 当前专注的任务
  final currentTaskId = RxnString();
  final currentTaskTitle = RxnString();
  
  // 设置
  final focusDuration = 25.obs;   // 专注时长（分钟）
  final breakDuration = 5.obs;    // 休息时长（分钟）
  
  // 今日统计
  final todayFocusMinutes = 0.obs;
  final todayPomodoroCount = 0.obs;
  
  // ========== 内部变量 ==========
  Timer? _timer;
  DateTime? _startTime;
  int _accumulatedSeconds = 0;  // 累计专注秒数

  // Hive Box
  late Box<PomodoroModel> pomodoroBox;
  // 初始化
  @override
  void onInit() {
    super.onInit();
    pomodoroBox = Hive.box<PomodoroModel>('pomodoros');
    _loadTodayStats();
  }

  //加载今日统计
  void _loadTodayStats() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    // 过滤出今日完成的专注记录
    final todayRecords = pomodoroBox.values.where((r) => 
      r.startTime.isAfter(todayStart) && 
      r.type == 'focus' &&
      r.isCompleted
    );
    // 计算今日专注分钟数
    todayFocusMinutes.value = todayRecords.fold(0, (sum, r) => 
      sum + (r.actualSeconds ~/ 60)
    );
    // 计算今日专注次数
    todayPomodoroCount.value = todayRecords.length;
  }

  // 开始专注
  void startFocus({String? taskId, String? taskTitle}) {
    currentTaskId.value = taskId;
    currentTaskTitle.value = taskTitle;
    currentMode.value = 'focus';
    _startTimer(focusDuration.value * 60);
  }
  
  // 开始休息
  void startBreak() {
    currentMode.value = 'break';
    _startTimer(breakDuration.value * 60);
  }
  
  // 内部计时器
  void _startTimer(int seconds) {
    remainingSeconds.value = seconds;
    isRunning.value = true;
    isPaused.value = false;
    _startTime = DateTime.now();
    _accumulatedSeconds = 0;
    
    _timer?.cancel(); // 取消之前的定时器
    // 创建新的定时器
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) 
      {
        remainingSeconds.value--;
        if (currentMode.value == 'focus' && !isPaused.value) 
        { 
          // 累计专注秒数
          _accumulatedSeconds++;
        }
      } 
      else 
      {
        _onTimerComplete(); // 定时器完成
      }
    });
  }

  // 计时完成
  void _onTimerComplete() {
    _timer?.cancel();
    isRunning.value = false;
    
    // 保存记录
    _saveRecord(isCompleted: true);
    
    if (currentMode.value == 'focus') 
    {
      // 专注完成，更新统计
      todayFocusMinutes.value += _accumulatedSeconds ~/ 60;
      todayPomodoroCount.value++;
      _accumulatedSeconds = 0;
      // 自动开始休息
      Get.snackbar(
        '专注完成！',
        '休息一下吧~',
        snackPosition: SnackPosition.BOTTOM,
      );
      startBreak();
    } 
    else 
    {
      // 休息完成
      Get.snackbar(
        '休息结束',
        '准备好继续专注了吗？',
        snackPosition: SnackPosition.BOTTOM,
      );
      _accumulatedSeconds = 0;
      remainingSeconds.value = focusDuration.value * 60;
    }
  }

  // 暂停
  void pause() {
    isPaused.value = true;
    _timer?.cancel();
  }
  
  // 继续
  void resume() {
    if (!isPaused.value) 
    {
      return;
    }
    isPaused.value = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) 
      {
        remainingSeconds.value--;
        if (currentMode.value == 'focus') 
        {
          _accumulatedSeconds++;
        }
      } 
      else 
      {
        _onTimerComplete();
      }
    });
  }
  
  // 放弃
  void giveUp() {
    _timer?.cancel();
    isRunning.value = false;
    isPaused.value = false;
    
    // 保存未完成的记录
    _saveRecord(isCompleted: false);
    _accumulatedSeconds = 0;
    remainingSeconds.value = focusDuration.value * 60;
    currentTaskId.value = null;
    currentTaskTitle.value = null;
  }

  // 保存记录
  Future<void> _saveRecord({required bool isCompleted}) async {
    final record = PomodoroModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taskId: currentTaskId.value,
      taskTitle: currentTaskTitle.value,
      durationMinutes: currentMode.value == 'focus' 
        ? focusDuration.value 
        : breakDuration.value,
      actualSeconds: _accumulatedSeconds,
      startTime: _startTime!,
      endTime: DateTime.now(),
      isCompleted: isCompleted,
      type: currentMode.value,
    );
    
    await pomodoroBox.put(record.id, record);
  }

  // 格式化时间显示
  String get formattedTime {
    final minutes = remainingSeconds.value ~/ 60;
    final seconds = remainingSeconds.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  // 进度百分比
  double get progress {
    final total = currentMode.value == 'focus' 
      ? focusDuration.value * 60 
      : breakDuration.value * 60;
    return 1 - (remainingSeconds.value / total);
  }
  
  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}