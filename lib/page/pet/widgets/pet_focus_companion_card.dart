import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/constants/theme.dart';
import 'package:todolist/features/pet/domain/pet_action.dart';
import 'package:todolist/features/pet/sprite/pet_sprite_models.dart';
import 'package:todolist/page/pet/pet_controller.dart';

import 'pet_global_feedback_overlay.dart';

/// 番茄钟运行态的宠物陪伴卡。
///
/// 卡片读取当前宠物名称和物种，展示轻量陪伴文案，并在专注过程中随机播放小动作；
/// 它不保存记录、不发奖励，只负责陪伴感展示。
class PetFocusCompanionCard extends StatefulWidget {
  final String? taskTitle;

  const PetFocusCompanionCard({super.key, this.taskTitle});

  @override
  State<PetFocusCompanionCard> createState() => _PetFocusCompanionCardState();
}

class _PetFocusCompanionCardState extends State<PetFocusCompanionCard> {
  // 专注陪伴卡只在几个温和动作间随机切换，避免干扰计时主流程。
  static const List<PetSpriteActionKey> _randomActions = [
    PetSpriteActionKey.pet,
    PetSpriteActionKey.waiting,
    PetSpriteActionKey.feed,
  ];

  final Random _random = Random();
  Timer? _behaviorTimer;
  PetSpriteActionKey _currentAction = PetSpriteActionKey.idle;

  @override
  void initState() {
    super.initState();
    // 首次进入运行态后延迟播放随机动作，保持卡片出现时先稳定展示 idle。
    _scheduleNextAction();
  }

  @override
  void dispose() {
    // 取消随机行为定时器，防止离开番茄钟运行态后继续 setState。
    _behaviorTimer?.cancel();
    super.dispose();
  }

  /// 安排下一次随机陪伴动作，动作间隔故意留出空档，减少视觉噪音。
  void _scheduleNextAction() {
    _behaviorTimer?.cancel();
    final delay = Duration(seconds: 6 + _random.nextInt(7));
    _behaviorTimer = Timer(delay, _playRandomAction);
  }

  /// 播放一个随机动作，结束后回到 idle 并继续安排下一次。
  void _playRandomAction() {
    if (!mounted) {
      return;
    }

    final action = _randomActions[_random.nextInt(_randomActions.length)];
    setState(() => _currentAction = action);

    _behaviorTimer = Timer(_durationFor(action), () {
      if (!mounted) {
        return;
      }
      setState(() => _currentAction = PetSpriteActionKey.idle);
      _scheduleNextAction();
    });
  }

  /// 不同动作持续时间不同，用于让喂食/等待等动画完整播放。
  Duration _durationFor(PetSpriteActionKey action) {
    return switch (action) {
      PetSpriteActionKey.pet => const Duration(milliseconds: 1200),
      PetSpriteActionKey.feed => const Duration(milliseconds: 1400),
      PetSpriteActionKey.waiting => const Duration(milliseconds: 1800),
      _ => const Duration(milliseconds: 1400),
    };
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PetController>();
    return Obx(() {
      // 宠物尚未加载时不占位，避免番茄钟页面出现空白卡片。
      final pet = controller.pet.value;
      if (pet == null) {
        return const SizedBox.shrink();
      }

      final title = '${pet.name}正在陪你专注';
      final subtitle = widget.taskTitle == null || widget.taskTitle!.isEmpty
          ? '每次进步一点点，我们慢慢来。'
          : '加油，任务“${widget.taskTitle}”就快要完成了。';

      return RepaintBoundary(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: TaskTheme.appBarColor.withValues(alpha: 0.42),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 左侧迷你精灵使用全局浮层同一套加载逻辑，并由 _currentAction 指定随机动作。
              SizedBox(
                width: 74,
                height: 78,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      bottom: 7,
                      child: Container(
                        width: 58,
                        height: 9,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),
                    MiniPetSprite(
                      key: ValueKey('focus-${pet.species}'),
                      controller: controller,
                      action: PetAction.idle,
                      spriteAction: _currentAction,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                // 右侧文字根据是否关联任务显示不同陪伴描述，不影响番茄钟记录。
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color.fromARGB(255, 44, 58, 70),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.25,
                        color: Color.fromARGB(255, 89, 106, 121),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
