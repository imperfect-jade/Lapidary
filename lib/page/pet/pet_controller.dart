import 'dart:async';

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/model/pomodoro/pomodoro.dart';
import 'package:todolist/model/task/task.dart';

enum PetAction { idle, pet, feed, sleep, taskComplete, overdue }

class PetOverlayEvent {
  final String id;
  final PetAction action;
  final String message;
  final DateTime createdAt;
  final int moodDelta;

  const PetOverlayEvent({
    required this.id,
    required this.action,
    required this.message,
    required this.createdAt,
    required this.moodDelta,
  });
}

class PetFood {
  final String species;
  final String name;
  final int cost;
  final int hungerBoost;
  final int moodBoost;

  const PetFood({
    required this.species,
    required this.name,
    required this.cost,
    required this.hungerBoost,
    required this.moodBoost,
  });
}

class PetController extends GetxController {
  static const List<PetFood> shopFoods = [
    PetFood(
      species: PetSpecies.cat,
      name: '小鱼干',
      cost: 20,
      hungerBoost: 12,
      moodBoost: 4,
    ),
    PetFood(
      species: PetSpecies.cat,
      name: '猫罐头',
      cost: 45,
      hungerBoost: 28,
      moodBoost: 10,
    ),
    PetFood(
      species: PetSpecies.cat,
      name: '豪华猫饭',
      cost: 80,
      hungerBoost: 45,
      moodBoost: 18,
    ),
    PetFood(
      species: PetSpecies.dog,
      name: '小骨饼干',
      cost: 20,
      hungerBoost: 12,
      moodBoost: 4,
    ),
    PetFood(
      species: PetSpecies.dog,
      name: '鸡肉狗粮',
      cost: 45,
      hungerBoost: 28,
      moodBoost: 10,
    ),
    PetFood(
      species: PetSpecies.dog,
      name: '牛肉能量餐',
      cost: 80,
      hungerBoost: 45,
      moodBoost: 18,
    ),
  ];

  static List<PetFood> foodsForSpecies(String species) {
    return shopFoods.where((food) => food.species == species).toList();
  }

  static String speciesLabel(String species) {
    return species == PetSpecies.dog ? '小狗' : '小猫';
  }

  final Rxn<PetModel> pet = Rxn<PetModel>();
  final message = '今天也一起慢慢完成任务吧'.obs;
  final action = PetAction.idle.obs;
  final feedbackTick = 0.obs;
  final feedbackAction = PetAction.idle.obs;
  final overlayEvent = Rxn<PetOverlayEvent>();

  late Box<PetModel> petBox;
  Timer? _stateTimer;
  Timer? _messageResetTimer;

  int get expToNextLevel => (pet.value?.level ?? 1) * 40;

  double get expProgress {
    final currentPet = pet.value;
    if (currentPet == null) {
      return 0;
    }
    return (currentPet.exp / expToNextLevel).clamp(0, 1).toDouble();
  }

  @override
  void onInit() {
    super.onInit();
    petBox = Hive.box<PetModel>('pets');
    _loadPet();
    _startStateTimer();
  }

  Future<void> _loadPet() async {
    final savedPet = petBox.get('default_cat');
    if (savedPet == null) {
      final defaultPet = PetModel.defaultCat();
      await petBox.put(defaultPet.id, defaultPet);
      pet.value = defaultPet;
      message.value = _statusMessage(defaultPet);
      return;
    }

    pet.value = savedPet;
    await refreshPetState();
  }

  Future<void> refreshPetState() async {
    await _applyTimeDelta(DateTime.now());
  }

  Future<void> _applyTimeDelta(DateTime now) async {
    final currentPet = pet.value;
    if (currentPet == null) {
      return;
    }

    final elapsedMinutes = now
        .difference(currentPet.lastInteractionAt)
        .inMinutes;

    if (elapsedMinutes <= 0) {
      return;
    }

    currentPet.hunger = _clampStat(currentPet.hunger - elapsedMinutes);
    currentPet.mood = _clampStat(currentPet.mood - elapsedMinutes);
    currentPet.energy = currentPet.isSleeping
        ? _clampStat(currentPet.energy + elapsedMinutes * 2)
        : _clampStat(currentPet.energy - (elapsedMinutes ~/ 3));
    currentPet.lastInteractionAt = now;

    if (currentPet.energy >= 100 && currentPet.isSleeping) {
      currentPet.isSleeping = false;
      action.value = PetAction.idle;
      _showTemporaryMessage('${currentPet.name}睡醒啦，精神很好');
    } else if (_messageResetTimer == null || !_messageResetTimer!.isActive) {
      _restoreStatusMessage();
    }

    await _saveAndNotify();
  }

  Future<void> petCat() async {
    final currentPet = pet.value;
    if (currentPet == null) {
      return;
    }

    await refreshPetState();
    currentPet.isSleeping = false;
    currentPet.mood = _clampStat(currentPet.mood + 1);
    currentPet.energy = _clampStat(currentPet.energy - 2);
    currentPet.lastInteractionAt = DateTime.now();
    action.value = PetAction.pet;
    _emitFeedback(PetAction.pet);
    _showTemporaryMessage('${currentPet.name}蹭了蹭你的手');
    await _saveAndNotify();
    _resetActionLater();
  }

  Future<void> feed() async {
    final currentPet = pet.value;
    final species = currentPet?.species ?? PetSpecies.cat;
    _showTemporaryMessage('请选择已购买的${speciesLabel(species)}食物来喂食');
  }

  Future<bool> feedWithFood(PetFood food) async {
    final currentPet = pet.value;
    if (currentPet == null) {
      return false;
    }

    await refreshPetState();
    currentPet.isSleeping = false;
    currentPet.hunger = _clampStat(currentPet.hunger + food.hungerBoost);
    currentPet.mood = _clampStat(currentPet.mood + food.moodBoost);
    currentPet.lastInteractionAt = DateTime.now();
    action.value = PetAction.feed;
    _emitFeedback(PetAction.feed);
    _showTemporaryMessage('${currentPet.name}吃了${food.name}，很满足');
    _gainExp(10 + food.cost ~/ 10);
    await _saveAndNotify();
    _resetActionLater();
    return true;
  }

  void startFocusCompanion({String? taskTitle}) {
    final currentPet = pet.value;
    if (currentPet == null) {
      return;
    }

    final target = taskTitle == null || taskTitle.isEmpty
        ? '这一轮'
        : '“$taskTitle”';
    _showTemporaryMessage('${currentPet.name}正在陪你专注，先守住$target。');
  }

  Future<void> celebrateFocusCompletion(
    PomodoroModel record,
    int reward,
  ) async {
    final currentPet = pet.value;
    if (currentPet == null) {
      return;
    }

    final wasSleeping = currentPet.isSleeping;
    await refreshPetState();
    if (wasSleeping) {
      currentPet.isSleeping = true;
    }
    const moodBoost = 6;
    currentPet.mood = _clampStat(currentPet.mood + moodBoost);
    currentPet.energy = _clampStat(currentPet.energy - 4);
    currentPet.lastInteractionAt = DateTime.now();
    _gainExp(8);

    final messageText = _focusCompletionMessage(currentPet, record, reward);
    action.value = PetAction.taskComplete;
    _emitFeedback(PetAction.taskComplete);
    _showTemporaryMessage(messageText);
    _emitOverlayEvent(
      PetAction.taskComplete,
      messageText,
      moodDelta: moodBoost,
    );
    await _saveAndNotify();
    _resetActionLater(restoreSleep: wasSleeping);
  }

  Future<void> celebrateTaskCompletion(TaskModel task) async {
    final currentPet = pet.value;
    if (currentPet == null) {
      return;
    }

    final wasSleeping = currentPet.isSleeping;
    await refreshPetState();
    if (wasSleeping) {
      currentPet.isSleeping = true;
    }
    final moodBoost = _taskMoodBoost(task);
    final messageText = _taskCompletionMessage(currentPet, task);
    currentPet.mood = _clampStat(currentPet.mood + moodBoost);
    currentPet.lastInteractionAt = DateTime.now();
    action.value = PetAction.taskComplete;
    _emitFeedback(PetAction.taskComplete);
    _showTemporaryMessage(messageText);
    _emitOverlayEvent(
      PetAction.taskComplete,
      messageText,
      moodDelta: moodBoost,
    );
    await _saveAndNotify();
    _resetActionLater(restoreSleep: wasSleeping);
  }

  Future<void> remindOverdueTasks(int count, String? title) async {
    if (count <= 0) {
      return;
    }
    final currentPet = pet.value;
    if (currentPet == null) {
      return;
    }

    final wasSleeping = currentPet.isSleeping;
    await refreshPetState();
    if (wasSleeping) {
      currentPet.isSleeping = true;
    }
    final penalty = (count * 2).clamp(0, 6).toInt();
    final messageText = _overdueMessage(count, title);
    currentPet.mood = _clampStat(currentPet.mood - penalty);
    currentPet.lastInteractionAt = DateTime.now();
    action.value = PetAction.overdue;
    _emitFeedback(PetAction.overdue);
    _showTemporaryMessage(messageText);
    _emitOverlayEvent(PetAction.overdue, messageText, moodDelta: -penalty);
    await _saveAndNotify();
    _resetActionLater(
      duration: const Duration(milliseconds: 1400),
      restoreSleep: wasSleeping,
    );
  }

  Future<void> selectPetSpecies(String species) async {
    final currentPet = pet.value;
    if (currentPet == null || currentPet.species == species) {
      return;
    }

    currentPet.species = species;
    currentPet.lastInteractionAt = DateTime.now();
    _showTemporaryMessage('已经切换为${speciesLabel(species)}');
    await _saveAndNotify();
  }

  Future<bool> renamePet(String name) async {
    final currentPet = pet.value;
    final trimmed = name.trim();
    if (currentPet == null || trimmed.isEmpty || trimmed.length > 8) {
      return false;
    }

    currentPet.name = trimmed;
    currentPet.lastInteractionAt = DateTime.now();
    _showTemporaryMessage('现在叫我$trimmed吧');
    await _saveAndNotify();
    return true;
  }

  Future<void> toggleSleep() async {
    final currentPet = pet.value;
    if (currentPet == null) {
      return;
    }

    await refreshPetState();
    currentPet.isSleeping = !currentPet.isSleeping;
    currentPet.lastInteractionAt = DateTime.now();
    action.value = currentPet.isSleeping ? PetAction.sleep : PetAction.idle;
    _emitFeedback(currentPet.isSleeping ? PetAction.sleep : PetAction.idle);
    _showTemporaryMessage(
      currentPet.isSleeping
          ? '${currentPet.name}蜷起来睡觉了'
          : '${currentPet.name}醒来陪你啦',
    );
    if (!currentPet.isSleeping) {
      _gainExp(4);
    }
    await _saveAndNotify();
  }

  void _gainExp(int amount) {
    final currentPet = pet.value;
    if (currentPet == null) {
      return;
    }

    currentPet.exp += amount;
    while (currentPet.exp >= expToNextLevel) {
      currentPet.exp -= expToNextLevel;
      currentPet.level++;
      currentPet.mood = _clampStat(currentPet.mood + 10);
      _showTemporaryMessage('${currentPet.name}升级到 Lv.${currentPet.level} 啦');
    }
  }

  Future<void> _saveAndNotify() async {
    final currentPet = pet.value;
    if (currentPet == null) {
      return;
    }

    await currentPet.save();
    pet.refresh();
  }

  void _resetActionLater({
    Duration duration = const Duration(milliseconds: 900),
    bool restoreSleep = false,
  }) {
    final pendingAction = action.value;
    Future.delayed(duration, () {
      if (action.value != pendingAction) {
        return;
      }
      action.value = restoreSleep ? PetAction.sleep : PetAction.idle;
    });
  }

  void _startStateTimer() {
    _stateTimer?.cancel();
    _stateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      refreshPetState();
    });
  }

  void _showTemporaryMessage(String text) {
    message.value = text;
    _messageResetTimer?.cancel();
    _messageResetTimer = Timer(const Duration(milliseconds: 2600), () {
      _restoreStatusMessage();
    });
  }

  void _restoreStatusMessage() {
    final currentPet = pet.value;
    if (currentPet == null) {
      return;
    }
    message.value = _statusMessage(currentPet);
  }

  void _emitFeedback(PetAction nextAction) {
    feedbackAction.value = nextAction;
    feedbackTick.value++;
  }

  void _emitOverlayEvent(
    PetAction nextAction,
    String text, {
    required int moodDelta,
  }) {
    final now = DateTime.now();
    overlayEvent.value = PetOverlayEvent(
      id: '${now.microsecondsSinceEpoch}_${nextAction.name}',
      action: nextAction,
      message: text,
      createdAt: now,
      moodDelta: moodDelta,
    );
  }

  String _statusMessage(PetModel currentPet) {
    if (currentPet.isSleeping) {
      return '${currentPet.name}正在睡觉恢复精力';
    }
    if (currentPet.hunger < 35) {
      return '${currentPet.name}有点饿了';
    }
    if (currentPet.energy < 30) {
      return '${currentPet.name}想休息一下';
    }
    if (currentPet.mood < 35) {
      return '${currentPet.name}想要一点陪伴';
    }
    return '今天也一起慢慢完成任务吧';
  }

  int _taskMoodBoost(TaskModel task) {
    switch (task.priority) {
      case 1:
        return 10;
      case 3:
        return 8;
      case 2:
        return 6;
      case 4:
        return 4;
      default:
        return 5;
    }
  }

  String _taskCompletionMessage(PetModel currentPet, TaskModel task) {
    if (task.priority == 1 || task.priority == 3) {
      return '这件重要的事被你拿下了，${currentPet.name}超开心！';
    }
    return '${currentPet.name}开心地跳起来：任务完成啦，做得很好！';
  }

  String _overdueMessage(int count, String? title) {
    if (count == 1 && title != null && title.isNotEmpty) {
      return '“$title”超过时间了，我们先从一点点开始吧。';
    }
    return '有 $count 个任务超过时间了，我们先从一个小任务重新开始吧。';
  }

  String _focusCompletionMessage(
    PetModel currentPet,
    PomodoroModel record,
    int reward,
  ) {
    final minutes = record.actualSeconds ~/ 60;
    if (record.taskTitle != null && record.taskTitle!.isNotEmpty) {
      return '${currentPet.name}陪你专注了 $minutes 分钟，“${record.taskTitle}”向前推进啦！';
    }
    return '${currentPet.name}陪你守住了 $minutes 分钟专注，奖励 +$reward 积分！';
  }

  int _clampStat(int value) {
    return value.clamp(0, 100).toInt();
  }

  @override
  void onClose() {
    _stateTimer?.cancel();
    _messageResetTimer?.cancel();
    super.onClose();
  }
}
