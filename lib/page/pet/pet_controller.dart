import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:todolist/model/pet/pet.dart';

enum PetAction { idle, pet, feed, sleep }

class PetController extends GetxController {
  final Rxn<PetModel> pet = Rxn<PetModel>();
  final message = '今天也一起慢慢完成任务吧'.obs;
  final action = PetAction.idle.obs;

  late Box<PetModel> petBox;

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
  }

  Future<void> _loadPet() async {
    final savedPet = petBox.get('default_cat');
    if (savedPet == null) {
      final defaultPet = PetModel.defaultCat();
      await petBox.put(defaultPet.id, defaultPet);
      pet.value = defaultPet;
      return;
    }

    pet.value = savedPet;
    await refreshPetState();
  }

  Future<void> refreshPetState() async {
    final currentPet = pet.value;
    if (currentPet == null) {
      return;
    }

    final now = DateTime.now();
    final elapsedHours = now
        .difference(currentPet.lastInteractionAt)
        .inHours;

    if (elapsedHours <= 0) {
      return;
    }

    currentPet.hunger = _clampStat(currentPet.hunger - elapsedHours * 3);
    currentPet.mood = _clampStat(currentPet.mood - elapsedHours * 2);
    currentPet.energy = currentPet.isSleeping
        ? _clampStat(currentPet.energy + elapsedHours * 8)
        : _clampStat(currentPet.energy - elapsedHours);
    currentPet.lastInteractionAt = now;

    if (currentPet.energy >= 95 && currentPet.isSleeping) {
      currentPet.isSleeping = false;
      message.value = '${currentPet.name}睡醒啦，精神很好';
    } else {
      message.value = _statusMessage(currentPet);
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
    message.value = '${currentPet.name}蹭了蹭你的手';
    action.value = PetAction.pet;
    _gainExp(8);
    await _saveAndNotify();
    _resetActionLater();
  }

  Future<void> feed() async {
    final currentPet = pet.value;
    if (currentPet == null) {
      return;
    }

    await refreshPetState();
    currentPet.isSleeping = false;
    currentPet.hunger = _clampStat(currentPet.hunger + 18);
    currentPet.mood = _clampStat(currentPet.mood + 6);
    currentPet.lastInteractionAt = DateTime.now();
    message.value = '${currentPet.name}吃饱了，尾巴摇得很开心';
    action.value = PetAction.feed;
    _gainExp(6);
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
    message.value = currentPet.isSleeping
        ? '${currentPet.name}蜷起来睡觉了'
        : '${currentPet.name}醒来陪你啦';
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
      message.value = '${currentPet.name}升级到 Lv.${currentPet.level} 啦';
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

  String _statusMessage(PetModel currentPet) {
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
}
