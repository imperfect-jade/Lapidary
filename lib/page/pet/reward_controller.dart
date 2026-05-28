import 'dart:math';

import 'package:get/get.dart';
import 'package:todolist/data/repositories/reward_repository.dart';
import 'package:todolist/features/pet/domain/pet_food.dart';
import 'package:todolist/features/productivity/ports/productivity_feedback_ports.dart';
import 'package:todolist/model/pomodoro/pomodoro.dart';
import 'package:todolist/model/reward/reward_wallet.dart';
import 'package:todolist/model/task/task.dart';

/// 奖励钱包控制器，负责积分、食物库存和奖励幂等记录。
///
/// 这是跨模块奖励端口的实现：任务和番茄钟只通过公开方法申请奖励，
/// Controller 自己判断是否已发放并持久化钱包，避免重复完成/重复保存导致积分翻倍。
class RewardController extends GetxController implements RewardFeedbackPort {
  RewardController(this.repository);

  static const String walletKey = RewardRepository.walletKey;

  // 奖励钱包由 Repository 读取默认对象；页面通过 Obx 监听积分和库存变化。
  final RewardRepository repository;
  final Rxn<RewardWalletModel> wallet = Rxn<RewardWalletModel>();

  /// 当前可用积分，商城按钮和奖励提示都读取这个派生值。
  int get points => wallet.value?.points ?? 0;

  /// 查询指定食物库存数量，UI 用于库存展示和喂食前校验。
  int foodCount(String foodName) {
    return wallet.value?.foodInventory[foodName] ?? 0;
  }

  @override
  void onInit() {
    super.onInit();
    // 初始化只加载钱包，不主动发放奖励；奖励入口由任务/番茄钟流程显式触发。
    _loadWallet();
  }

  /// 从 Repository 获取默认钱包，首次不存在时由仓储层创建。
  Future<void> _loadWallet() async {
    wallet.value = await repository.getWallet();
  }

  /// 为完成的专注番茄钟发放积分。
  ///
  /// 只处理已完成的 focus 记录，并通过 `rewardedPomodoroIds` 保证同一记录幂等；
  /// 关联任务的实际专注秒数也在这里累计，供任务完成奖励计算加成。
  @override
  Future<int> awardPomodoro(PomodoroModel record) async {
    final currentWallet = wallet.value;
    if (currentWallet == null ||
        record.type != 'focus' ||
        !record.isCompleted ||
        currentWallet.rewardedPomodoroIds.contains(record.id)) {
      return 0;
    }

    final focusMinutes = record.actualSeconds ~/ 60;
    final reward = max(5, (focusMinutes ~/ 5) * 5);
    currentWallet.points += reward;
    currentWallet.rewardedPomodoroIds.add(record.id);
    _recordTaskFocus(record);
    await _saveAndNotify();
    return reward;
  }

  /// 为首次完成的任务发放积分。
  ///
  /// 基础奖励固定，额外加成来自之前累计到该任务上的专注时长；
  /// `rewardedTaskIds` 是幂等边界，确保取消完成再完成不会重复刷积分。
  @override
  Future<int> awardTaskCompletion(TaskModel task) async {
    final currentWallet = wallet.value;
    if (currentWallet == null ||
        currentWallet.rewardedTaskIds.contains(task.id)) {
      return 0;
    }

    final focusSeconds = currentWallet.taskFocusSeconds[task.id] ?? 0;
    final focusMinutes = focusSeconds ~/ 60;
    final reward = 20 + (focusMinutes ~/ 10) * 10;
    currentWallet.points += reward;
    currentWallet.rewardedTaskIds.add(task.id);
    await _saveAndNotify();
    return reward;
  }

  /// 消费指定积分，当前主要为未来装扮/扩展消费预留。
  ///
  /// 方法只在余额足够时保存并刷新钱包，调用方根据返回值决定是否提示失败。
  Future<bool> spendPoints(int cost) async {
    final currentWallet = wallet.value;
    if (currentWallet == null || currentWallet.points < cost) {
      return false;
    }

    currentWallet.points -= cost;
    await _saveAndNotify();
    return true;
  }

  /// 购买食物：扣积分并增加对应食物库存。
  ///
  /// 购买成功后立即持久化；宠物喂食数值变化不在这里处理，保持奖励钱包边界清晰。
  Future<bool> buyFood(PetFood food) async {
    final currentWallet = wallet.value;
    if (currentWallet == null || currentWallet.points < food.cost) {
      return false;
    }

    currentWallet.points -= food.cost;
    currentWallet.foodInventory[food.name] =
        (currentWallet.foodInventory[food.name] ?? 0) + 1;
    await _saveAndNotify();
    return true;
  }

  /// 消耗一份食物库存。
  ///
  /// 库存为 1 时移除键，避免保留 0 数量；宠物状态已由调用方在消耗前更新。
  Future<bool> consumeFood(PetFood food) async {
    final currentWallet = wallet.value;
    final count = currentWallet?.foodInventory[food.name] ?? 0;
    if (currentWallet == null || count <= 0) {
      return false;
    }

    if (count == 1) {
      currentWallet.foodInventory.remove(food.name);
    } else {
      currentWallet.foodInventory[food.name] = count - 1;
    }
    await _saveAndNotify();
    return true;
  }

  /// 累计某个任务关联的专注秒数。
  ///
  /// 该数据只影响之后任务完成奖励的加成，不直接刷新 UI 文案或宠物状态。
  void _recordTaskFocus(PomodoroModel record) {
    final currentWallet = wallet.value;
    final taskId = record.taskId;
    if (currentWallet == null || taskId == null || taskId.isEmpty) {
      return;
    }

    currentWallet.taskFocusSeconds[taskId] =
        (currentWallet.taskFocusSeconds[taskId] ?? 0) + record.actualSeconds;
  }

  /// 统一保存奖励钱包并刷新 Rx。
  ///
  /// 所有积分、库存和幂等集合的变更都通过这里落盘，方便后续替换 Repository。
  Future<void> _saveAndNotify() async {
    final currentWallet = wallet.value;
    if (currentWallet == null) {
      return;
    }

    await repository.save(currentWallet);
    wallet.refresh();
  }
}
