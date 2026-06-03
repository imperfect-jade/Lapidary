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

/// 宠物状态控制器，统一管理宠物模型、页面消息、动作动画和全局浮层事件。
///
/// Controller 负责 GetX 状态、保存时机和跨模块公开 API；具体数值规则交给
/// `PetStateService`，文案交给 `PetMessageService`，浮层事件交给 `PetFeedbackService`。
class PetController extends GetxController implements PetFeedbackPort {
  PetController(
    this.repository,
    this.stateService,
    this.messageService,
    this.feedbackService,
  );

  // 当前默认宠物模型，由 Repository 从 Hive 读取或创建，页面通过 Obx 监听刷新。
  final Rxn<PetModel> pet = Rxn<PetModel>();
  // 顶部气泡文案，临时反馈结束后会恢复为 PetMessageService 计算出的状态文案。
  final message = '今天也一起慢慢完成任务吧'.obs;
  // 主舞台动作：驱动精灵帧动画在 idle、抚摸、喂食、睡眠、任务完成等状态间切换。
  final action = PetAction.idle.obs;
  // 局部漂浮反馈用 tick 强制刷新动画，避免连续同类事件因为枚举值相同而不重播。
  final feedbackTick = 0.obs;
  final feedbackAction = PetAction.idle.obs;
  // 全局宠物浮层事件，首页等页面监听后展示轻量反馈，不强制跳转到宠物页。
  final overlayEvent = Rxn<PetOverlayEvent>();

  // 持久化和业务规则都通过注入获得，便于单元测试独立验证 Controller 行为。
  final PetRepository repository;
  final PetStateService stateService;
  final PetMessageService messageService;
  final PetFeedbackService feedbackService;
  // 定时器分别负责周期性状态衰减和临时文案恢复，onClose 必须取消。
  Timer? _stateTimer;
  Timer? _messageResetTimer;

  /// 当前等级升级所需经验值，由状态服务统一计算，避免 UI 复制公式。
  int get expToNextLevel {
    final currentPet = pet.value;
    return currentPet == null ? 40 : stateService.expToNextLevel(currentPet);
  }

  /// 当前经验进度，返回 0-1 之间的小数供进度条使用。
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
    // 初始化时先加载默认宠物，再启动分钟级状态刷新，保持离线衰减连续。
    _loadPet();
    _startStateTimer();
  }

  /// 从 Repository 读取默认宠物，并立即应用一次离线时间差。
  Future<void> _loadPet() async {
    pet.value = await repository.getDefaultPet();
    await refreshPetState();
  }

  /// 对外暴露的状态刷新入口，页面进入或跨模块操作前可调用。
  ///
  /// 该方法只应用时间流逝带来的数值变化；如有变化会通过 `_saveAndNotify()` 持久化。
  Future<void> refreshPetState() async {
    await _applyTimeDelta(DateTime.now());
  }

  /// 在线分钟刷新入口，会在时间衰减后追加一次自动经验累计。
  Future<void> _refreshOnlinePetState() async {
    await _applyTimeDelta(DateTime.now(), countOnlineAutoExp: true);
  }

  /// 根据上次交互到当前时间的差值更新饱腹、心情和精力。
  ///
  /// 睡眠时恢复精力，清醒时按固定间隔扣精力；若睡满自动醒来，需要同步动作和文案。
  Future<void> _applyTimeDelta(
    DateTime now, {
    bool countOnlineAutoExp = false,
  }) async {
    final currentPet = pet.value;
    if (currentPet == null) {
      return;
    }

    final result = stateService.applyTimeDelta(currentPet, now);
    final autoExpResult = countOnlineAutoExp
        ? stateService.applyAutoExpGrowth(currentPet, onlineMinutes: 1)
        : null;
    final autoExpChanged = autoExpResult?.changed ?? false;
    if (!result.changed && !autoExpChanged) {
      return;
    }

    if (result.wokeUp) {
      action.value = PetAction.idle;
      _showTemporaryMessage(messageService.wokeUp(currentPet));
    } else if (autoExpResult?.leveledUp ?? false) {
      _showTemporaryMessage(messageService.levelUp(currentPet));
    } else if (_messageResetTimer == null || !_messageResetTimer!.isActive) {
      _restoreStatusMessage();
    }

    await _saveAndNotify();
  }

  /// 抚摸宠物：先刷新离线状态，再增加心情、扣少量精力并触发局部反馈动画。
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

  /// 打开喂食入口前的轻量提示，不直接修改库存或宠物数值。
  Future<void> feed() async {
    final species = pet.value?.species ?? PetSpecies.cat;
    _showTemporaryMessage(messageService.feedPrompt(species));
  }

  /// 使用指定食物喂食宠物。
  ///
  /// 这里只修改宠物状态并保存；库存扣减由 `RewardController.consumeFood()` 负责，
  /// 因此调用方需要在喂食成功后再消耗食物，避免两个持久化边界混在一起。
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

  /// 番茄钟专注开始时的陪伴提示，只更新气泡文案，不消耗精力或保存记录。
  @override
  void startFocusCompanion({String? taskTitle}) {
    final currentPet = pet.value;
    if (currentPet == null) {
      return;
    }

    _showTemporaryMessage(messageService.focusCompanion(currentPet, taskTitle));
  }

  /// 专注记录保存后扣除宠物精力。
  ///
  /// 只处理 focus 类型记录；奖励发放和 Snackbar 由跨模块服务/奖励控制器负责。
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

  /// 休息完成后恢复宠物精力。
  ///
  /// 仅已完成的 break 记录生效，防止放弃或未完成记录误恢复状态。
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

  /// 专注完成且获得奖励时的宠物庆祝反馈。
  ///
  /// 会增加心情和经验、播放主舞台动画，并发出全局浮层事件；记录和积分已在其他层处理。
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

  /// 任务首次完成并获得奖励时的宠物庆祝反馈。
  ///
  /// 心情和经验奖励按任务优先级计算；如果宠物原本在睡觉，动画结束后会恢复睡眠动作。
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

  /// 任务逾期的一次性提醒入口，由任务模块确保同一任务只触发一次。
  ///
  /// 宠物侧只负责按数量降低心情、展示文案并发出全局浮层事件。
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

  /// 切换宠物物种，保持当前模型和 Hive schema 不变，只更新 species 字段。
  Future<void> selectPetSpecies(String species) async {
    final currentPet = pet.value;
    if (currentPet == null || currentPet.species == species) {
      return;
    }

    stateService.setSpecies(currentPet, species, DateTime.now());
    _showTemporaryMessage(messageService.speciesSelected(species));
    await _saveAndNotify();
  }

  /// 修改宠物名称。
  ///
  /// 输入校验由状态服务执行；返回值用于弹窗决定是否关闭或提示错误。
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

  /// 切换睡眠状态。
  ///
  /// 睡眠时暂停清醒精力衰减；醒来后恢复 idle 动作并保存当前交互时间。
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

  /// 统一保存宠物模型并刷新 Rx。
  ///
  /// Controller 内所有会改变宠物模型的路径都收口到这里，方便后续替换持久化实现。
  Future<void> _saveAndNotify() async {
    final currentPet = pet.value;
    if (currentPet == null) {
      return;
    }

    await repository.save(currentPet);
    pet.refresh();
  }

  /// 临时动作播放结束后恢复 idle 或 sleep，避免主舞台停留在一次性反馈动作。
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

  /// 启动分钟级状态刷新，用于持续应用饱腹/心情/精力随时间变化的规则。
  void _startStateTimer() {
    _stateTimer?.cancel();
    _stateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(_refreshOnlinePetState());
    });
  }

  /// 展示短暂反馈文案，并在计时结束后恢复为当前状态文案。
  void _showTemporaryMessage(String text) {
    message.value = text;
    _messageResetTimer?.cancel();
    _messageResetTimer = Timer(const Duration(milliseconds: 2600), () {
      _restoreStatusMessage();
    });
  }

  /// 根据当前宠物状态恢复默认气泡文案。
  void _restoreStatusMessage() {
    final currentPet = pet.value;
    if (currentPet == null) {
      return;
    }
    message.value = messageService.statusMessage(currentPet);
  }

  /// 触发宠物页内的漂浮图标动画，tick 用于连续同动作重新播放。
  void _emitFeedback(PetAction nextAction) {
    feedbackAction.value = nextAction;
    feedbackTick.value++;
  }

  /// 触发全局宠物浮层事件，供首页 Stack 上的 Overlay 监听并展示。
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
    // GetX 销毁控制器时必须取消计时器，避免页面退出后继续刷新或回调已释放对象。
    _stateTimer?.cancel();
    _messageResetTimer?.cancel();
    super.onClose();
  }
}
