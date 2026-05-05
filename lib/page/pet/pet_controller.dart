import 'dart:async';

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:todolist/model/pet/pet.dart';

enum PetAction { idle, pet, feed, sleep }

class PetFood {
  final String name;
  final int cost;
  final int hungerBoost;
  final int moodBoost;

  const PetFood({
    required this.name,
    required this.cost,
    required this.hungerBoost,
    required this.moodBoost,
  });
}

class PetController extends GetxController {
  static const List<PetFood> shopFoods = [
    PetFood(name: '小鱼干', cost: 20, hungerBoost: 12, moodBoost: 4),
    PetFood(name: '猫罐头', cost: 45, hungerBoost: 28, moodBoost: 10),
    PetFood(name: '豪华猫饭', cost: 80, hungerBoost: 45, moodBoost: 18),
  ];

  final Rxn<PetModel> pet = Rxn<PetModel>();
  final message = '今天也一起慢慢完成任务吧'.obs;
  final action = PetAction.idle.obs;
  final feedbackTick = 0.obs;
  final feedbackAction = PetAction.idle.obs;

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
    currentPet.mood = _clampStat(currentPet.mood + 12);
    currentPet.energy = _clampStat(currentPet.energy - 2);
    currentPet.lastInteractionAt = DateTime.now();
    action.value = PetAction.pet;
    _emitFeedback(PetAction.pet);
    _showTemporaryMessage('${currentPet.name}蹭了蹭你的手');
    _gainExp(8);
    await _saveAndNotify();
    _resetActionLater();
  }

  Future<void> feed() async {
    _showTemporaryMessage('请选择已购买的食物来喂小猫');
  }

  Future<void> feedWithFood(PetFood food) async {
    final currentPet = pet.value;
    if (currentPet == null) {
      return;
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

  void _resetActionLater() {
    Future.delayed(const Duration(milliseconds: 900), () {
      if (action.value != PetAction.sleep) {
        action.value = PetAction.idle;
      }
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
