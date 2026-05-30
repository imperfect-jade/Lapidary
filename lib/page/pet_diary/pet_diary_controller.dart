import 'package:get/get.dart';
import 'package:todolist/data/repositories/pet_diary_repository.dart';
import 'package:todolist/data/repositories/pet_repository.dart';
import 'package:todolist/data/repositories/pomodoro_repository.dart';
import 'package:todolist/data/repositories/task_repository.dart';
import 'package:todolist/features/pet_diary/domain/pet_diary_stats.dart';
import 'package:todolist/features/pet_diary/services/pet_diary_template_service.dart';
import 'package:todolist/model/pet_diary/pet_diary.dart';
import 'package:todolist/model/pomodoro/pomodoro.dart';

class PetDiaryController extends GetxController {
  PetDiaryController(
    this.diaryRepository,
    this.taskRepository,
    this.pomodoroRepository,
    this.petRepository,
    this.templateService,
  );

  final PetDiaryRepository diaryRepository;
  final TaskRepository taskRepository;
  final PomodoroRepository pomodoroRepository;
  final PetRepository petRepository;
  final PetDiaryTemplateService templateService;

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
      final recentDiaryTexts = diaryRepository
          .latestFirst()
          .take(5)
          .map((diary) => diary.diaryText);
      final diary = PetDiaryModel(
        id: _dateId(day),
        date: day,
        completedTaskCount: stats.completedTaskCount,
        focusMinutes: stats.focusMinutes,
        focusSessionCount: stats.focusSessionCount,
        lateNightTaskCount: stats.lateNightTaskCount,
        diaryText: templateService.buildDiaryText(
          stats: stats,
          petName: pet.name,
          recentDiaryTexts: recentDiaryTexts,
        ),
        generatedAt: DateTime.now(),
      );

      await diaryRepository.put(diary);
      loadDiaries();
      return diary;
    } finally {
      isGenerating.value = false;
    }
  }

  PetDiaryStats _collectStats(DateTime day) {
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

    return PetDiaryStats(
      completedTaskCount: completedTasks.length,
      focusMinutes: _focusMinutes(focusRecords),
      focusSessionCount: focusRecords.length,
      lateNightTaskCount: completedTasks
          .where((task) => task.completedAt!.hour >= 21)
          .length,
    );
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
