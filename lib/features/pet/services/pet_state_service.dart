import 'package:todolist/features/pet/domain/pet_food.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/model/pomodoro/pomodoro.dart';
import 'package:todolist/model/task/task.dart';

class PetTimeDeltaResult {
  final bool changed;
  final bool wokeUp;

  const PetTimeDeltaResult({required this.changed, required this.wokeUp});
}

class PetExperienceResult {
  final bool leveledUp;
  final int level;

  const PetExperienceResult({required this.leveledUp, required this.level});
}

class PetStateService {
  static const int awakeEnergyDecayIntervalMinutes = 10;
  static const int focusEnergyCostIntervalMinutes = 5;
  static const int breakEnergyRestoreIntervalMinutes = 2;

  int expToNextLevel(PetModel pet) {
    return pet.level * 40;
  }

  double expProgress(PetModel pet) {
    return (pet.exp / expToNextLevel(pet)).clamp(0, 1).toDouble();
  }

  PetTimeDeltaResult applyTimeDelta(PetModel pet, DateTime now) {
    final elapsedMinutes = now.difference(pet.lastInteractionAt).inMinutes;
    if (elapsedMinutes <= 0) {
      return const PetTimeDeltaResult(changed: false, wokeUp: false);
    }

    pet.hunger = _clampStat(pet.hunger - elapsedMinutes);
    pet.mood = _clampStat(pet.mood - elapsedMinutes);
    if (pet.isSleeping) {
      pet.energy = _clampStat(pet.energy + elapsedMinutes * 2);
      pet.energyDecayRemainderMinutes = 0;
    } else {
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

  void applyPetting(PetModel pet, DateTime now) {
    pet.isSleeping = false;
    pet.mood = _clampStat(pet.mood + 1);
    pet.energy = _clampStat(pet.energy - 2);
    pet.lastInteractionAt = now;
  }

  PetExperienceResult applyFeeding(PetModel pet, PetFood food, DateTime now) {
    pet.isSleeping = false;
    pet.hunger = _clampStat(pet.hunger + food.hungerBoost);
    pet.mood = _clampStat(pet.mood + food.moodBoost);
    pet.lastInteractionAt = now;
    return gainExp(pet, 10 + food.cost ~/ 10);
  }

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

  void applyMoodDelta(PetModel pet, int delta, DateTime now) {
    pet.mood = _clampStat(pet.mood + delta);
    pet.lastInteractionAt = now;
  }

  void setSpecies(PetModel pet, String species, DateTime now) {
    pet.species = species;
    pet.lastInteractionAt = now;
  }

  bool rename(PetModel pet, String name, DateTime now) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 8) {
      return false;
    }
    pet.name = trimmed;
    pet.lastInteractionAt = now;
    return true;
  }

  void toggleSleep(PetModel pet, DateTime now) {
    pet.isSleeping = !pet.isSleeping;
    if (pet.isSleeping) {
      pet.energyDecayRemainderMinutes = 0;
    }
    pet.lastInteractionAt = now;
  }

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

  int _clampStat(int value) {
    return value.clamp(0, 100).toInt();
  }
}
