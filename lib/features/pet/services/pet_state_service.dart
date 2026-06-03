import 'package:todolist/features/pet/domain/pet_food.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/model/pomodoro/pomodoro.dart';
import 'package:todolist/model/task/task.dart';

/// 宠物时间流逝计算结果。
///
/// Controller 根据 `changed` 决定是否保存，根据 `wokeUp` 决定是否展示醒来文案。
class PetTimeDeltaResult {
  final bool changed;
  final bool wokeUp;

  const PetTimeDeltaResult({required this.changed, required this.wokeUp});
}

/// 宠物经验变更结果，用于喂食或任务奖励后判断是否展示升级反馈。
class PetExperienceResult {
  final bool leveledUp;
  final int level;

  const PetExperienceResult({required this.leveledUp, required this.level});
}

/// 宠物自动经验增长结果，用于在线达标累计后保存和展示升级反馈。
class PetAutoExpGrowthResult {
  final bool changed;
  final int gainedExp;
  final bool leveledUp;
  final int level;

  const PetAutoExpGrowthResult({
    required this.changed,
    required this.gainedExp,
    required this.leveledUp,
    required this.level,
  });
}

/// 宠物数值规则服务。
///
/// 该服务只修改传入的 `PetModel`，不访问 Hive、GetX 或 UI；保存和刷新由
/// `PetController` 统一处理。所有心情、饱腹、精力和经验规则都应收口到这里。
class PetStateService {
  // 清醒状态每 10 分钟扣 1 点精力，余数记录在模型中，避免频繁刷新时丢失累计时间。
  static const int awakeEnergyDecayIntervalMinutes = 10;
  // 专注番茄钟每 5 分钟消耗 1 点精力，最短有效专注也至少消耗 1 点。
  static const int focusEnergyCostIntervalMinutes = 5;
  // 完成休息每 2 分钟恢复 1 点精力，鼓励用户在专注后休息。
  static const int breakEnergyRestoreIntervalMinutes = 2;
  // 饱腹、心情和精力都达到该阈值时，在线分钟才会累计自动经验进度。
  static const int autoExpGrowthStatThreshold = 70;
  // 在线达标累计满 30 分钟获得 1 点经验，保持自动成长的轻量感。
  static const int autoExpGrowthIntervalMinutes = 30;

  /// 当前等级升级所需经验值。
  int expToNextLevel(PetModel pet) {
    return pet.level * 40;
  }

  /// 当前等级经验进度，返回 0-1 供 UI 进度条使用。
  double expProgress(PetModel pet) {
    return (pet.exp / expToNextLevel(pet)).clamp(0, 1).toDouble();
  }

  /// 应用离线/在线时间差。
  ///
  /// 饱腹和心情按分钟下降；睡眠时精力按分钟恢复，清醒时精力按固定间隔下降。
  /// 精力睡满后会自动醒来，返回值用于 Controller 展示醒来提示并保存模型。
  PetTimeDeltaResult applyTimeDelta(PetModel pet, DateTime now) {
    final elapsedMinutes = now.difference(pet.lastInteractionAt).inMinutes;
    if (elapsedMinutes <= 0) {
      return const PetTimeDeltaResult(changed: false, wokeUp: false);
    }

    pet.hunger = _clampStat(pet.hunger - elapsedMinutes);
    pet.mood = _clampStat(pet.mood - elapsedMinutes);
    if (pet.isSleeping) {
      // 睡眠恢复精力时清空清醒衰减余数，醒来后重新累计。
      pet.energy = _clampStat(pet.energy + elapsedMinutes * 2);
      pet.energyDecayRemainderMinutes = 0;
    } else {
      // 清醒精力衰减按间隔扣点，余数保存在模型中跨刷新延续。
      final accumulatedMinutes =
          pet.energyDecayRemainderMinutes + elapsedMinutes;
      final energyCost = accumulatedMinutes ~/ awakeEnergyDecayIntervalMinutes;
      pet.energyDecayRemainderMinutes =
          accumulatedMinutes % awakeEnergyDecayIntervalMinutes;
      if (energyCost > 0) {
        pet.energy = _clampStat(pet.energy - energyCost);
      }
    }
    pet.lastInteractionAt = now;

    final wokeUp = pet.energy >= 100 && pet.isSleeping;
    if (wokeUp) {
      pet.isSleeping = false;
    }
    return PetTimeDeltaResult(changed: true, wokeUp: wokeUp);
  }

  /// 抚摸宠物：唤醒宠物、少量提升心情并消耗精力。
  void applyPetting(PetModel pet, DateTime now) {
    pet.isSleeping = false;
    pet.mood = _clampStat(pet.mood + 1);
    pet.energy = _clampStat(pet.energy - 2);
    pet.lastInteractionAt = now;
  }

  /// 喂食宠物：提升饱腹和心情，并按食物价值增加经验。
  ///
  /// 食物库存不在这里扣减，保持状态规则和奖励钱包边界独立。
  PetExperienceResult applyFeeding(PetModel pet, PetFood food, DateTime now) {
    pet.isSleeping = false;
    pet.hunger = _clampStat(pet.hunger + food.hungerBoost);
    pet.mood = _clampStat(pet.mood + food.moodBoost);
    pet.lastInteractionAt = now;
    return gainExp(pet, 10 + food.cost ~/ 10);
  }

  /// 专注完成后消耗精力。
  ///
  /// 只接受 focus 记录，消耗量由实际专注秒数按间隔换算。
  bool applyFocusEnergyCost(PetModel pet, PomodoroModel record, DateTime now) {
    if (record.type != 'focus') {
      return false;
    }
    final energyCost = timedStatUnits(
      actualSeconds: record.actualSeconds,
      intervalMinutes: focusEnergyCostIntervalMinutes,
    );
    if (energyCost <= 0) {
      return false;
    }

    pet.energy = _clampStat(pet.energy - energyCost);
    pet.lastInteractionAt = now;
    return true;
  }

  /// 休息完成后恢复精力。
  ///
  /// 只接受已完成的 break 记录，避免放弃休息时仍恢复精力。
  bool restoreBreakEnergy(PetModel pet, PomodoroModel record, DateTime now) {
    if (record.type != 'break' || !record.isCompleted) {
      return false;
    }
    final energyBoost = timedStatUnits(
      actualSeconds: record.actualSeconds,
      intervalMinutes: breakEnergyRestoreIntervalMinutes,
    );
    if (energyBoost <= 0) {
      return false;
    }

    pet.energy = _clampStat(pet.energy + energyBoost);
    pet.lastInteractionAt = now;
    return true;
  }

  /// 直接调整心情值，任务完成、专注完成和逾期提醒都会走这个入口。
  void applyMoodDelta(PetModel pet, int delta, DateTime now) {
    pet.mood = _clampStat(pet.mood + delta);
    pet.lastInteractionAt = now;
  }

  /// 切换宠物物种，只更新模型字段和交互时间，不重建宠物数据。
  void setSpecies(PetModel pet, String species, DateTime now) {
    pet.species = species;
    pet.lastInteractionAt = now;
  }

  /// 修改宠物名称，并在这里统一校验空值和最大长度。
  bool rename(PetModel pet, String name, DateTime now) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 8) {
      return false;
    }
    pet.name = trimmed;
    pet.lastInteractionAt = now;
    return true;
  }

  /// 切换睡眠状态。
  ///
  /// 进入睡眠时清空清醒精力衰减余数，避免醒来后立即扣除旧累计。
  void toggleSleep(PetModel pet, DateTime now) {
    pet.isSleeping = !pet.isSleeping;
    if (pet.isSleeping) {
      pet.energyDecayRemainderMinutes = 0;
    }
    pet.lastInteractionAt = now;
  }

  /// 增加经验并处理连续升级。
  ///
  /// 升级会额外提升心情；如果一次获得大量经验，会循环升级直到经验低于阈值。
  PetExperienceResult gainExp(PetModel pet, int amount) {
    var leveledUp = false;
    pet.exp += amount;
    while (pet.exp >= expToNextLevel(pet)) {
      pet.exp -= expToNextLevel(pet);
      pet.level++;
      pet.mood = _clampStat(pet.mood + 10);
      leveledUp = true;
    }
    return PetExperienceResult(leveledUp: leveledUp, level: pet.level);
  }

  /// 判断宠物当前状态是否满足自动经验增长条件。
  bool canGainAutoExp(PetModel pet) {
    return pet.hunger >= autoExpGrowthStatThreshold &&
        pet.mood >= autoExpGrowthStatThreshold &&
        pet.energy >= autoExpGrowthStatThreshold;
  }

  /// 累计在线达标分钟，并在满间隔时转化为经验。
  ///
  /// 该方法只接收在线计时器提供的分钟数，不根据离线时间补算；低于阈值时暂停累计，
  /// 但保留此前未满 30 分钟的进度。
  PetAutoExpGrowthResult applyAutoExpGrowth(
    PetModel pet, {
    required int onlineMinutes,
  }) {
    if (onlineMinutes <= 0 || !canGainAutoExp(pet)) {
      return PetAutoExpGrowthResult(
        changed: false,
        gainedExp: 0,
        leveledUp: false,
        level: pet.level,
      );
    }

    pet.autoExpGrowthRemainderMinutes += onlineMinutes;
    final expGain =
        pet.autoExpGrowthRemainderMinutes ~/ autoExpGrowthIntervalMinutes;
    if (expGain <= 0) {
      return PetAutoExpGrowthResult(
        changed: true,
        gainedExp: 0,
        leveledUp: false,
        level: pet.level,
      );
    }

    pet.autoExpGrowthRemainderMinutes =
        pet.autoExpGrowthRemainderMinutes % autoExpGrowthIntervalMinutes;
    final expResult = gainExp(pet, expGain);
    return PetAutoExpGrowthResult(
      changed: true,
      gainedExp: expGain,
      leveledUp: expResult.leveledUp,
      level: expResult.level,
    );
  }

  /// 根据任务优先级计算完成后的心情奖励。
  ///
  /// 重要/紧急任务奖励更高，普通或低优先级保持温和激励。
  int taskMoodBoost(TaskModel task) {
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

  /// 根据任务优先级计算完成后的经验奖励。
  int taskExpReward(TaskModel task) {
    switch (task.priority) {
      case 1:
        return 16;
      case 3:
        return 12;
      case 2:
        return 8;
      case 4:
        return 4;
      default:
        return 6;
    }
  }

  /// 将实际秒数换算为状态变化单位。
  ///
  /// 有效时长不足一个间隔时仍返回 1，保证短专注/短休息也有轻量反馈。
  int timedStatUnits({
    required int actualSeconds,
    required int intervalMinutes,
  }) {
    if (actualSeconds <= 0 || intervalMinutes <= 0) {
      return 0;
    }
    final secondsPerUnit = intervalMinutes * 60;
    final units = actualSeconds ~/ secondsPerUnit;
    return units > 0 ? units : 1;
  }

  /// 统一限制宠物数值在 0-100，避免 UI 进度条越界。
  int _clampStat(int value) {
    return value.clamp(0, 100).toInt();
  }
}
