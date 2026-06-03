import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todolist/features/pet/domain/pet_action.dart';
import 'package:todolist/features/pet/domain/pet_food.dart';
import 'package:todolist/features/pet/services/pet_feedback_service.dart';
import 'package:todolist/features/pet/services/pet_food_catalog.dart';
import 'package:todolist/features/pet/services/pet_message_service.dart';
import 'package:todolist/features/pet/services/pet_state_service.dart';
import 'package:todolist/features/pet/sprite/pet_sprite_models.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/model/pomodoro/pomodoro.dart';
import 'package:todolist/model/task/task.dart';

void main() {
  group('PetStateService', () {
    late PetStateService service;

    setUp(() {
      service = PetStateService();
    });

    test('applies offline decay and awake energy remainder', () {
      final now = DateTime(2026, 5, 26, 10);
      final pet = _pet(
        hunger: 80,
        mood: 78,
        energy: 50,
        energyDecayRemainderMinutes: 5,
        lastInteractionAt: now.subtract(const Duration(minutes: 30)),
      );

      final result = service.applyTimeDelta(pet, now);

      expect(result.changed, isTrue);
      expect(result.wokeUp, isFalse);
      expect(pet.hunger, 50);
      expect(pet.mood, 48);
      expect(pet.energy, 47);
      expect(pet.energyDecayRemainderMinutes, 5);
      expect(pet.lastInteractionAt, now);
    });

    test('restores energy during sleep and wakes at full energy', () {
      final now = DateTime(2026, 5, 26, 10);
      final pet = _pet(
        energy: 80,
        isSleeping: true,
        lastInteractionAt: now.subtract(const Duration(minutes: 20)),
      );

      final result = service.applyTimeDelta(pet, now);

      expect(result.changed, isTrue);
      expect(result.wokeUp, isTrue);
      expect(pet.energy, 100);
      expect(pet.isSleeping, isFalse);
      expect(pet.energyDecayRemainderMinutes, 0);
    });

    test('accumulates auto exp after qualified online minutes', () {
      final pet = _pet(hunger: 72, mood: 70, energy: 88);

      final firstResult = service.applyAutoExpGrowth(pet, onlineMinutes: 29);
      expect(firstResult.changed, isTrue);
      expect(firstResult.gainedExp, 0);
      expect(firstResult.leveledUp, isFalse);
      expect(pet.exp, 0);
      expect(pet.autoExpGrowthRemainderMinutes, 29);

      final secondResult = service.applyAutoExpGrowth(pet, onlineMinutes: 2);
      expect(secondResult.changed, isTrue);
      expect(secondResult.gainedExp, 1);
      expect(secondResult.leveledUp, isFalse);
      expect(pet.exp, 1);
      expect(pet.autoExpGrowthRemainderMinutes, 1);
    });

    test('pauses auto exp accumulation below stat threshold', () {
      final pet = _pet(
        hunger: 72,
        mood: 69,
        energy: 88,
        autoExpGrowthRemainderMinutes: 12,
      );

      final result = service.applyAutoExpGrowth(pet, onlineMinutes: 10);

      expect(result.changed, isFalse);
      expect(result.gainedExp, 0);
      expect(pet.exp, 0);
      expect(pet.autoExpGrowthRemainderMinutes, 12);
    });

    test('auto exp can level up through existing exp rules', () {
      final pet = _pet(
        level: 1,
        exp: 39,
        hunger: 70,
        mood: 70,
        energy: 70,
        autoExpGrowthRemainderMinutes: 29,
      );

      final result = service.applyAutoExpGrowth(pet, onlineMinutes: 1);

      expect(result.changed, isTrue);
      expect(result.gainedExp, 1);
      expect(result.leveledUp, isTrue);
      expect(pet.level, 2);
      expect(pet.exp, 0);
      expect(pet.mood, 80);
      expect(pet.autoExpGrowthRemainderMinutes, 0);
    });

    test('handles petting, feeding, sleep toggle, and level up', () {
      final now = DateTime(2026, 5, 26, 10);
      final pet = _pet(
        exp: 39,
        mood: 70,
        hunger: 70,
        energy: 60,
        isSleeping: true,
      );
      const food = PetFood(
        species: PetSpecies.cat,
        name: '测试食物',
        cost: 20,
        hungerBoost: 12,
        moodBoost: 4,
      );

      service.applyPetting(pet, now);
      expect(pet.isSleeping, isFalse);
      expect(pet.mood, 71);
      expect(pet.energy, 58);

      final expResult = service.applyFeeding(pet, food, now);
      expect(expResult.leveledUp, isTrue);
      expect(pet.level, 2);
      expect(pet.exp, 11);
      expect(pet.hunger, 82);
      expect(pet.mood, 85);

      service.toggleSleep(pet, now);
      expect(pet.isSleeping, isTrue);
      expect(pet.energyDecayRemainderMinutes, 0);
    });

    test('calculates focus and task rewards without UI dependencies', () {
      final pet = _pet(energy: 30);
      final focusRecord = PomodoroModel(
        id: 'focus-1',
        durationMinutes: 25,
        actualSeconds: 25 * 60,
        startTime: DateTime(2026, 5, 26, 9),
        isCompleted: true,
        type: 'focus',
      );
      final breakRecord = PomodoroModel(
        id: 'break-1',
        durationMinutes: 5,
        actualSeconds: 4 * 60,
        startTime: DateTime(2026, 5, 26, 9, 30),
        isCompleted: true,
        type: 'break',
      );
      final importantTask = TaskModel(
        id: 'task-1',
        title: '重要任务',
        deadline: DateTime(2026, 5, 26, 18),
        priority: 1,
      );

      expect(
        service.applyFocusEnergyCost(
          pet,
          focusRecord,
          DateTime(2026, 5, 26, 10),
        ),
        isTrue,
      );
      expect(pet.energy, 25);

      expect(
        service.restoreBreakEnergy(
          pet,
          breakRecord,
          DateTime(2026, 5, 26, 10, 5),
        ),
        isTrue,
      );
      expect(pet.energy, 27);
      expect(service.taskMoodBoost(importantTask), 10);
      expect(service.taskExpReward(importantTask), 16);
    });
  });

  group('PetMessageService', () {
    final service = PetMessageService();

    test('returns state, task, overdue, and focus messages', () {
      final pet = _pet(name: '小云', hunger: 30);
      final task = TaskModel(
        id: 'task-1',
        title: '整理项目',
        deadline: DateTime(2026, 5, 26, 18),
        priority: 1,
      );
      final record = PomodoroModel(
        id: 'focus-1',
        taskTitle: '整理项目',
        durationMinutes: 25,
        actualSeconds: 1500,
        startTime: DateTime(2026, 5, 26, 9),
        isCompleted: true,
        type: 'focus',
      );

      expect(service.statusMessage(pet), contains('饿'));
      expect(service.taskCompletion(pet, task), contains('重要'));
      expect(service.overdue(1, '整理项目'), contains('整理项目'));
      expect(service.focusCompletion(pet, record, 25), contains('25 分钟'));
      expect(service.feedPrompt(PetSpecies.cat), contains('小猫'));
    });
  });

  group('PetFoodCatalog', () {
    test('filters food by species and exposes species labels', () {
      final catFoods = PetFoodCatalog.foodsForSpecies(PetSpecies.cat);
      final dogFoods = PetFoodCatalog.foodsForSpecies(PetSpecies.dog);

      expect(catFoods, hasLength(3));
      expect(dogFoods, hasLength(3));
      expect(catFoods.every((food) => food.species == PetSpecies.cat), isTrue);
      expect(dogFoods.every((food) => food.species == PetSpecies.dog), isTrue);
      expect(PetFoodCatalog.speciesLabel(PetSpecies.cat), '小猫');
      expect(PetFoodCatalog.speciesLabel(PetSpecies.dog), '小狗');
    });
  });

  group('PetFeedbackService', () {
    test('creates overlay events without touching controller state', () {
      final event = PetFeedbackService().createOverlayEvent(
        PetAction.taskComplete,
        '做得很好',
        moodDelta: 6,
        now: DateTime(2026, 5, 26, 10),
      );

      expect(event.action, PetAction.taskComplete);
      expect(event.message, '做得很好');
      expect(event.moodDelta, 6);
      expect(event.id, contains('taskComplete'));
    });
  });

  group('PetSpriteSpecParser', () {
    test('parses sprite specs and fills action fallbacks', () {
      final spec = PetSpriteSpecParser.fromJson(
        json: {
          'image': 'cat.png',
          'frameWidth': 32,
          'frameHeight': 32,
          'actions': {
            'idle': {'row': 0, 'frames': 1, 'fps': 6},
            'runningRight': {'row': 1, 'frames': 2, 'fps': 7},
            'pet': {'row': 2, 'frames': 3, 'fps': 8},
            'waiting': {'row': 3, 'frames': 4, 'fps': 5},
            'jumping': {'row': 4, 'frames': 5, 'fps': 9},
          },
        },
        displaySize: const Size(10, 12),
        flipLeft: true,
      );

      expect(spec.assetPath, 'lib/assets/images/pet/cat.png');
      expect(spec.frameWidth, 32);
      expect(spec.frameHeight, 32);
      expect(spec.displaySize, const Size(10, 12));
      expect(spec.flipLeft, isTrue);
      expect(spec.animationFor(PetSpriteActionKey.runningLeft).row, 1);
      expect(spec.animationFor(PetSpriteActionKey.feed).row, 2);
      expect(spec.animationFor(PetSpriteActionKey.sleep).row, 0);
      expect(spec.animationFor(PetSpriteActionKey.taskComplete).row, 4);
      expect(spec.animationFor(PetSpriteActionKey.overdue).row, 3);
      expect(spec.animationFor(PetSpriteActionKey.running).row, 1);

      final minimalSpec = PetSpriteSpecParser.fromJson(
        json: {
          'image': 'minimal.png',
          'frameWidth': 32,
          'frameHeight': 32,
          'actions': {
            'idle': {'row': 0, 'frames': 1, 'fps': 6},
          },
        },
        displaySize: const Size(10, 12),
        flipLeft: false,
      );
      expect(minimalSpec.animationFor(PetSpriteActionKey.runningRight).row, 0);
      expect(minimalSpec.animationFor(PetSpriteActionKey.runningLeft).row, 0);
      expect(minimalSpec.animationFor(PetSpriteActionKey.feed).row, 0);
      expect(minimalSpec.animationFor(PetSpriteActionKey.running).row, 0);
    });
  });
}

PetModel _pet({
  String id = 'pet-1',
  String species = PetSpecies.cat,
  String name = '小云',
  int level = 1,
  int exp = 0,
  int mood = 76,
  int hunger = 72,
  int energy = 80,
  bool isSleeping = false,
  DateTime? lastInteractionAt,
  int energyDecayRemainderMinutes = 0,
  int autoExpGrowthRemainderMinutes = 0,
}) {
  return PetModel(
    id: id,
    species: species,
    name: name,
    level: level,
    exp: exp,
    mood: mood,
    hunger: hunger,
    energy: energy,
    isSleeping: isSleeping,
    lastInteractionAt: lastInteractionAt ?? DateTime(2026, 5, 26, 9),
    energyDecayRemainderMinutes: energyDecayRemainderMinutes,
    autoExpGrowthRemainderMinutes: autoExpGrowthRemainderMinutes,
  );
}
