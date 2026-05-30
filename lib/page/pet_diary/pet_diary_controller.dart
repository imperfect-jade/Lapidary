import 'package:get/get.dart';
import 'package:todolist/data/repositories/pet_diary_repository.dart';
import 'package:todolist/data/repositories/pet_repository.dart';
import 'package:todolist/data/repositories/pomodoro_repository.dart';
import 'package:todolist/data/repositories/task_repository.dart';
import 'package:todolist/model/pet_diary/pet_diary.dart';
import 'package:todolist/model/pomodoro/pomodoro.dart';

class PetDiaryController extends GetxController {
  PetDiaryController(
    this.diaryRepository,
    this.taskRepository,
    this.pomodoroRepository,
    this.petRepository,
  );

  final PetDiaryRepository diaryRepository;
  final TaskRepository taskRepository;
  final PomodoroRepository pomodoroRepository;
  final PetRepository petRepository;

  final RxList<PetDiaryModel> diaries = <PetDiaryModel>[].obs;
  final Rxn<PetDiaryModel> todayDiary = Rxn<PetDiaryModel>();
  final isGenerating = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDiaries();
  }

  void loadDiaries() {
    final today = DateTime.now();
    final todayId = _dateId(today);
    final latestDiaries = diaryRepository.latestFirst();
    if (!hasDiarySourceDataForDate(today)) {
      todayDiary.value = null;
      diaries.assignAll(latestDiaries.where((diary) => diary.id != todayId));
      return;
    }

    diaries.assignAll(latestDiaries);
    todayDiary.value = diaryRepository.getById(todayId);
  }

  Future<PetDiaryModel?> ensureTodayDiary() async {
    final now = DateTime.now();
    final todayId = _dateId(now);
    if (!hasDiarySourceDataForDate(now)) {
      todayDiary.value = null;
      diaries.assignAll(
        diaryRepository.latestFirst().where((diary) => diary.id != todayId),
      );
      return null;
    }

    final existing = diaryRepository.getById(todayId);
    if (existing != null) {
      _syncDiaryState(existing);
      return existing;
    }
    return _generateAndSave(now);
  }

  Future<PetDiaryModel?> regenerateTodayDiary() {
    return _generateAndSave(DateTime.now());
  }

  PetDiaryModel? diaryForDate(DateTime date) {
    return diaryRepository.getById(_dateId(date));
  }

  bool hasDiarySourceDataForDate(DateTime date) {
    return _collectStats(_dayStart(date)).hasSourceData;
  }

  Future<PetDiaryModel?> _generateAndSave(DateTime date) async {
    isGenerating.value = true;
    try {
      final day = _dayStart(date);
      final stats = _collectStats(day);
      if (!stats.hasSourceData) {
        final diaryId = _dateId(day);
        if (diaryId == _dateId(DateTime.now())) {
          todayDiary.value = null;
          diaries.assignAll(
            diaryRepository.latestFirst().where((diary) => diary.id != diaryId),
          );
          return null;
        }
        return diaryRepository.getById(diaryId);
      }

      final pet = await petRepository.getDefaultPet();
      final diary = PetDiaryModel(
        id: _dateId(day),
        date: day,
        completedTaskCount: stats.completedTaskCount,
        focusMinutes: stats.focusMinutes,
        focusSessionCount: stats.focusSessionCount,
        lateNightTaskCount: stats.lateNightTaskCount,
        diaryText: _buildDiaryText(stats, pet.name),
        generatedAt: DateTime.now(),
      );

      await diaryRepository.put(diary);
      loadDiaries();
      return diary;
    } finally {
      isGenerating.value = false;
    }
  }

  _PetDiaryStats _collectStats(DateTime day) {
    final nextDay = day.add(const Duration(days: 1));
    final completedTasks = taskRepository.getAll().where((task) {
      final completedAt = task.completedAt;
      return task.isCompleted &&
          completedAt != null &&
          _isInRange(completedAt, day, nextDay);
    }).toList();

    final focusRecords = pomodoroRepository.getAll().where((record) {
      return record.type == 'focus' &&
          record.isCompleted &&
          _isInRange(record.startTime, day, nextDay);
    }).toList();

    return _PetDiaryStats(
      completedTaskCount: completedTasks.length,
      focusMinutes: _focusMinutes(focusRecords),
      focusSessionCount: focusRecords.length,
      lateNightTaskCount: completedTasks
          .where((task) => task.completedAt!.hour >= 21)
          .length,
    );
  }

  String _buildDiaryText(_PetDiaryStats stats, String petName) {
    final summary = _summaryLine(stats);
    final response = _responseLine(stats, petName);
    return '$summary\n$response';
  }

  String _summaryLine(_PetDiaryStats stats) {
    final taskPart = stats.completedTaskCount > 0
        ? '今天你完成了 ${stats.completedTaskCount} 个任务'
        : '今天还没有完成任务';
    if (stats.focusMinutes > 0) {
      return '$taskPart，还专注了 ${stats.focusMinutes} 分钟。';
    }
    return '$taskPart。';
  }

  String _responseLine(_PetDiaryStats stats, String petName) {
    if (stats.lateNightTaskCount > 0) {
      return '我看见你晚上也在努力，不过现在该让自己慢慢停下来了，$petName陪你休息一会儿。';
    }
    if (stats.completedTaskCount >= 4) {
      return '我觉得你真的很努力。明天我们也从一个小目标开始吧。';
    }
    if (stats.focusSessionCount >= 2 || stats.focusMinutes >= 50) {
      return '$petName一直在旁边陪着你，一点一点推进，也是在认真生活。';
    }
    if (stats.completedTaskCount == 1) {
      return '能开始就已经很好了。明天我们继续慢慢来。';
    }
    if (stats.completedTaskCount >= 2) {
      return '今天你稳稳推进了几件事，已经很不错了。明天我们继续照顾好自己的节奏。';
    }
    if (stats.focusMinutes > 0) {
      return '不是每一天都要立刻有结果，愿意坐下来就很棒。';
    }
    return '没关系，我们明天先从一个很小的任务开始。';
  }

  void _syncDiaryState(PetDiaryModel diary) {
    diaries.assignAll(diaryRepository.latestFirst());
    if (diary.id == _dateId(DateTime.now())) {
      todayDiary.value = diary;
    }
  }

  bool _isInRange(DateTime value, DateTime start, DateTime end) {
    return !value.isBefore(start) && value.isBefore(end);
  }

  DateTime _dayStart(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _dateId(DateTime date) {
    final day = _dayStart(date);
    return '${day.year}-${_two(day.month)}-${_two(day.day)}';
  }

  String _two(int value) {
    return value.toString().padLeft(2, '0');
  }

  int _focusMinutes(Iterable<PomodoroModel> records) {
    return records.fold(0, (sum, record) => sum + (record.actualSeconds ~/ 60));
  }
}

class _PetDiaryStats {
  final int completedTaskCount;
  final int focusMinutes;
  final int focusSessionCount;
  final int lateNightTaskCount;

  bool get hasSourceData => completedTaskCount > 0 || focusSessionCount > 0;

  const _PetDiaryStats({
    required this.completedTaskCount,
    required this.focusMinutes,
    required this.focusSessionCount,
    required this.lateNightTaskCount,
  });
}
