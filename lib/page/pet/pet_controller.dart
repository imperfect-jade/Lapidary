import 'dart:async';

import 'package:get/get.dart';
import 'package:todolist/data/repositories/pet_repository.dart';
import 'package:todolist/features/pet/domain/pet_action.dart';
import 'package:todolist/features/pet/domain/pet_food.dart';
import 'package:todolist/features/pet/domain/pet_overlay_event.dart';
import 'package:todolist/features/pet/services/pet_feedback_service.dart';
import 'package:todolist/features/pet/services/pet_message_service.dart';
import 'package:todolist/features/pet/services/pet_state_service.dart';
import 'package:todolist/features/productivity/ports/productivity_feedback_ports.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/model/pomodoro/pomodoro.dart';
import 'package:todolist/model/task/task.dart';

class PetController extends GetxController implements PetFeedbackPort {
  PetController(
    this.repository,
    this.stateService,
    this.messageService,
    this.feedbackService,
  );

  final Rxn<PetModel> pet = Rxn<PetModel>();
  final message = '今天也一起慢慢完成任务吧'.obs;
  final action = PetAction.idle.obs;
  final feedbackTick = 0.obs;
  final feedbackAction = PetAction.idle.obs;
  final overlayEvent = Rxn<PetOverlayEvent>();

  final PetRepository repository;
  final PetStateService stateService;
  final PetMessageService messageService;
  final PetFeedbackService feedbackService;
  Timer? _stateTimer;
  Timer? _messageResetTimer;

  int get expToNextLevel {
    final currentPet = pet.value;
    return currentPet == null ? 40 : stateService.expToNextLevel(currentPet);
  }

  double get expProgress {
    final currentPet = pet.value;
    if (currentPet == null) {
      return 0;
    }
    return stateService.expProgress(currentPet);
  }

  @override
  void onInit() {
    super.onInit();
    _loadPet();
    _startStateTimer();
  }

  Future<void> _loadPet() async {
    pet.value = await repository.getDefaultPet();
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

    final result = stateService.applyTimeDelta(currentPet, now);
    if (!result.changed) {
      return;
    }

    if (result.wokeUp) {
      action.value = PetAction.idle;
      _showTemporaryMessage(messageService.wokeUp(currentPet));
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
    stateService.applyPetting(currentPet, DateTime.now());
    action.value = PetAction.pet;
    _emitFeedback(PetAction.pet);
    _showTemporaryMessage(messageService.petting(currentPet));
    await _saveAndNotify();
    _resetActionLater();
  }

  Future<void> feed() async {
    final species = pet.value?.species ?? PetSpecies.cat;
    _showTemporaryMessage(messageService.feedPrompt(species));
  }

  Future<bool> feedWithFood(PetFood food) async {
    final currentPet = pet.value;
    if (currentPet == null) {
      return false;
    }

    await refreshPetState();
    final expResult = stateService.applyFeeding(
      currentPet,
      food,
      DateTime.now(),
    );
    action.value = PetAction.feed;
    _emitFeedback(PetAction.feed);
    _showTemporaryMessage(messageService.fed(currentPet, food));
    if (expResult.leveledUp) {
      _showTemporaryMessage(messageService.levelUp(currentPet));
    }
    await _saveAndNotify();
    _resetActionLater();
    return true;
  }

  @override
  void startFocusCompanion({String? taskTitle}) {
    final currentPet = pet.value;
    if (currentPet == null) {
      return;
    }

    _showTemporaryMessage(messageService.focusCompanion(currentPet, taskTitle));
  }

  @override
  Future<void> applyFocusEnergyCost(PomodoroModel record) async {
    if (record.type != 'focus') {
      return;
    }
    final currentPet = pet.value;
    if (currentPet == null) {
      return;
    }

    await refreshPetState();
    final changed = stateService.applyFocusEnergyCost(
      currentPet,
      record,
      DateTime.now(),
    );
    if (!changed) {
      return;
    }
    await _saveAndNotify();
  }

  @override
  Future<void> restoreBreakEnergy(PomodoroModel record) async {
    if (record.type != 'break' || !record.isCompleted) {
      return;
    }
    final currentPet = pet.value;
    if (currentPet == null) {
      return;
    }

    await refreshPetState();
    final changed = stateService.restoreBreakEnergy(
      currentPet,
      record,
      DateTime.now(),
    );
    if (!changed) {
      return;
    }
    await _saveAndNotify();
  }

  @override
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
    stateService.applyMoodDelta(currentPet, moodBoost, DateTime.now());
    stateService.gainExp(currentPet, 8);

    final messageText = messageService.focusCompletion(
      currentPet,
      record,
      reward,
    );
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

  @override
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
    final moodBoost = stateService.taskMoodBoost(task);
    final expReward = stateService.taskExpReward(task);
    stateService.applyMoodDelta(currentPet, moodBoost, DateTime.now());
    stateService.gainExp(currentPet, expReward);
    final messageText = messageService.taskCompletion(currentPet, task);

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

  @override
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
    final messageText = messageService.overdue(count, title);
    stateService.applyMoodDelta(currentPet, -penalty, DateTime.now());
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

    stateService.setSpecies(currentPet, species, DateTime.now());
    _showTemporaryMessage(messageService.speciesSelected(species));
    await _saveAndNotify();
  }

  Future<bool> renamePet(String name) async {
    final currentPet = pet.value;
    final trimmed = name.trim();
    if (currentPet == null) {
      return false;
    }

    final renamed = stateService.rename(currentPet, trimmed, DateTime.now());
    if (!renamed) {
      return false;
    }
    _showTemporaryMessage(messageService.renamed(trimmed));
    await _saveAndNotify();
    return true;
  }

  Future<void> toggleSleep() async {
    final currentPet = pet.value;
    if (currentPet == null) {
      return;
    }

    await refreshPetState();
    stateService.toggleSleep(currentPet, DateTime.now());
    action.value = currentPet.isSleeping ? PetAction.sleep : PetAction.idle;
    _emitFeedback(currentPet.isSleeping ? PetAction.sleep : PetAction.idle);
    _showTemporaryMessage(messageService.sleepToggled(currentPet));
    await _saveAndNotify();
  }

  Future<void> _saveAndNotify() async {
    final currentPet = pet.value;
    if (currentPet == null) {
      return;
    }

    await repository.save(currentPet);
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
    message.value = messageService.statusMessage(currentPet);
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
    overlayEvent.value = feedbackService.createOverlayEvent(
      nextAction,
      text,
      moodDelta: moodDelta,
    );
  }

  @override
  void onClose() {
    _stateTimer?.cancel();
    _messageResetTimer?.cancel();
    super.onClose();
  }
}
