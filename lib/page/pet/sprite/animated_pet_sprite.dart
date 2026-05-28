import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/features/pet/domain/pet_action.dart';
import 'package:todolist/features/pet/sprite/pet_sprite_cache.dart';
import 'package:todolist/features/pet/sprite/pet_sprite_models.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/page/pet/pet_controller.dart';

import 'sprite_placeholder.dart';
import 'sprite_sheet_painter.dart';

/// 宠物页主舞台精灵组件，负责加载精灵图并播放帧动画。
///
/// 它监听 `PetController.action` 播放抚摸、喂食、任务完成等动作，
/// 同时在 idle 状态下随机播放等待、跳跃、奔跑等环境动作，提升陪伴感。
class AnimatedPetSprite extends StatefulWidget {
  final PetController controller;
  final PetModel pet;

  const AnimatedPetSprite({
    super.key,
    required this.controller,
    required this.pet,
  });

  @override
  State<AnimatedPetSprite> createState() => _AnimatedPetSpriteState();
}

class _AnimatedPetSpriteState extends State<AnimatedPetSprite>
    with TickerProviderStateMixin {
  // idleController 负责轻微上下浮动，moveController 负责舞台内横向移动。
  late final AnimationController _idleController;
  late final AnimationController _moveController;
  // actionWorker 监听 Controller 动作；两个 Timer 分别推进帧和随机待机行为。
  Worker? _actionWorker;
  Timer? _frameTimer;
  Timer? _behaviorTimer;
  // 精灵图片和规格来自 PetSpriteCache，加载失败时切换到占位组件。
  ui.Image? _spriteImage;
  PetSpriteSpec? _spriteSpec;
  bool _spriteLoadFailed = false;
  int _frameIndex = 0;
  bool _facingLeft = false;
  bool _wasSleeping = false;
  double _positionFactor = 0;
  double _moveStartFactor = 0;
  double _moveEndFactor = 0;
  final Random _random = Random();
  AmbientPetMotion _ambientMotion = AmbientPetMotion.idle;
  PetSpriteActionKey _lastAction = PetSpriteActionKey.idle;
  String? _loadedSpecies;

  @override
  void initState() {
    super.initState();
    // 待机浮动让像素宠物即使不移动也有呼吸感，睡眠时节奏更慢。
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _wasSleeping = widget.pet.isSleeping;
    // 横向移动只在随机奔跑动作中启用，结束后回到 idle 行为调度。
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..addStatusListener(_handleMoveStatus);
    _actionWorker = ever<PetAction>(
      // Controller 发出一次性动作时，主舞台会暂停随机待机，优先播放用户反馈。
      widget.controller.action,
      _handlePetActionChanged,
    );
    _loadSprite();
    if (_wasSleeping) {
      // 睡眠状态下不安排随机动作，精灵保持 sleep/idle 的安静表现。
      _enterSleepMode();
    } else {
      _scheduleNextBehavior(initial: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedPetSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 物种切换后重新加载对应精灵图，避免继续显示旧物种动画。
    if (oldWidget.pet.species != widget.pet.species) {
      _loadSprite();
    }
    _idleController.duration = widget.pet.isSleeping
        ? const Duration(milliseconds: 2600)
        : const Duration(milliseconds: 1600);
    if (!_idleController.isAnimating) {
      _idleController.repeat(reverse: true);
    }
    _syncSleepMode();
  }

  @override
  void dispose() {
    // 释放所有动画监听和计时器，防止离开宠物页后继续推进帧。
    _frameTimer?.cancel();
    _behaviorTimer?.cancel();
    _actionWorker?.dispose();
    _moveController.removeStatusListener(_handleMoveStatus);
    _idleController.dispose();
    _moveController.dispose();
    super.dispose();
  }

  /// 加载当前物种的精灵图和规格。
  ///
  /// 失败时只切换占位状态，不影响宠物模型和其他页面交互。
  Future<void> _loadSprite() async {
    final species = widget.pet.species;
    try {
      final cached = await PetSpriteCache.load(species);
      _useCachedSprite(species, cached, const Size(184, 198));
    } catch (error) {
      debugPrint('Failed to load pet sprite: $error');
      if (mounted) {
        setState(() => _spriteLoadFailed = true);
      }
    }
  }

  /// 使用缓存精灵并覆盖主舞台展示尺寸。
  ///
  /// 异步加载返回时会再次检查物种，防止用户切换物种后旧资源覆盖新资源。
  void _useCachedSprite(
    String species,
    CachedPetSprite cached,
    Size displaySize,
  ) {
    if (!mounted || widget.pet.species != species) {
      return;
    }
    final spec = cached.spec.copyWith(displaySize: displaySize);
    setState(() {
      _spriteImage = cached.image;
      _spriteSpec = spec;
      _spriteLoadFailed = false;
      _loadedSpecies = species;
      _frameIndex = 0;
      _lastAction = PetSpriteActionKey.idle;
    });
    _startFrameTimer(spec.animationFor(PetSpriteActionKey.idle));
  }

  /// 启动帧动画计时器。
  ///
  /// `holdLastFrame` 用于睡眠动作，让动画播到最后一帧后停住，而不是循环眨动。
  void _startFrameTimer(
    PetSpriteAnimationSpec animation, {
    bool holdLastFrame = false,
  }) {
    _frameTimer?.cancel();
    final fps = animation.fps.clamp(1, 12).toInt();
    _frameTimer = Timer.periodic(Duration(milliseconds: 1000 ~/ fps), (_) {
      if (!mounted) {
        return;
      }
      final frames = animation.frames.clamp(1, 8).toInt();
      if (holdLastFrame) {
        final nextFrame = _frameIndex + 1;
        if (nextFrame >= frames) {
          _frameTimer?.cancel();
          _frameTimer = null;
          setState(() {
            _frameIndex = frames - 1;
          });
          return;
        }
        setState(() => _frameIndex = nextFrame);
        return;
      }
      setState(() => _frameIndex = (_frameIndex + 1) % frames);
    });
  }

  /// 横向移动完成后记录最终位置，并重新进入随机待机行为调度。
  void _handleMoveStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }
    _positionFactor = _moveEndFactor;
    _moveController.reset();
    if (!mounted || widget.pet.isSleeping) {
      return;
    }
    setState(() => _ambientMotion = AmbientPetMotion.idle);
    _scheduleNextBehavior();
  }

  /// 切换精灵动作时重置帧索引并同步对应 fps。
  void _syncFrameAction(
    PetSpriteActionKey action,
    PetSpriteAnimationSpec animation,
  ) {
    if (_lastAction != action) {
      _lastAction = action;
      _frameIndex = 0;
      _startFrameTimer(
        animation,
        holdLastFrame: action == PetSpriteActionKey.sleep,
      );
    }
  }

  /// 根据模型里的睡眠状态进入或退出睡眠动画模式。
  void _syncSleepMode() {
    if (_wasSleeping == widget.pet.isSleeping) {
      return;
    }
    _wasSleeping = widget.pet.isSleeping;
    if (_wasSleeping) {
      _enterSleepMode();
    } else {
      _exitSleepMode();
    }
  }

  /// 响应 Controller 的一次性动作变化。
  ///
  /// 用户抚摸、喂食、完成任务或逾期提醒时会暂停随机移动，优先展示反馈动作。
  void _handlePetActionChanged(PetAction action) {
    if (!mounted || widget.pet.isSleeping) {
      return;
    }
    if (_usesActionAnimation(action)) {
      _behaviorTimer?.cancel();
      _captureCurrentPosition();
      _moveController.stop();
      _moveController.reset();
      _setAmbientMotion(AmbientPetMotion.idle);
      return;
    }
    if (action == PetAction.idle &&
        (_behaviorTimer == null || !_behaviorTimer!.isActive)) {
      _scheduleNextBehavior(initial: true);
    }
  }

  /// 进入睡眠模式：取消随机行为和横向移动，位置回到舞台中心。
  void _enterSleepMode() {
    _behaviorTimer?.cancel();
    _moveController.stop();
    _moveController.reset();
    _positionFactor = 0;
    _moveStartFactor = 0;
    _moveEndFactor = 0;
    _lastAction = PetSpriteActionKey.idle;
    _frameIndex = 0;
    if (mounted) {
      setState(() => _ambientMotion = AmbientPetMotion.idle);
    }
  }

  /// 退出睡眠模式：恢复 idle 动作并重新安排随机行为。
  void _exitSleepMode() {
    _lastAction = PetSpriteActionKey.idle;
    _frameIndex = 0;
    if (mounted) {
      setState(() => _ambientMotion = AmbientPetMotion.idle);
    }
    _scheduleNextBehavior(initial: true);
  }

  /// 安排下一次待机行为，初次进入时延迟更短，后续随机间隔更自然。
  void _scheduleNextBehavior({bool initial = false}) {
    _behaviorTimer?.cancel();
    if (!mounted || widget.pet.isSleeping) {
      return;
    }
    final baseDelay = initial ? 1200 : 3000;
    final randomDelay = initial ? 1200 : 4000;
    _behaviorTimer = Timer(
      Duration(milliseconds: baseDelay + _random.nextInt(randomDelay)),
      _chooseNextBehavior,
    );
  }

  /// 根据随机数选择下一段环境动作：静止、等待、跳跃、原地跑或横向短跑。
  void _chooseNextBehavior() {
    if (!mounted || widget.pet.isSleeping) {
      return;
    }
    if (widget.controller.action.value != PetAction.idle) {
      _scheduleNextBehavior();
      return;
    }

    final roll = _random.nextDouble();
    if (roll < 0.55) {
      _setAmbientMotion(AmbientPetMotion.idle);
      _scheduleNextBehavior();
    } else if (roll < 0.75) {
      _playAmbientFor(
        AmbientPetMotion.waiting,
        const Duration(milliseconds: 2600),
      );
    } else if (roll < 0.85) {
      _playAmbientFor(
        AmbientPetMotion.jumping,
        const Duration(milliseconds: 900),
      );
    } else if (roll < 0.90) {
      _playAmbientFor(
        AmbientPetMotion.runningInPlace,
        const Duration(milliseconds: 1200),
      );
    } else {
      _startRunBurst(toLeft: _random.nextBool());
    }
  }

  /// 更新当前环境动作，动作相同则不触发 rebuild。
  void _setAmbientMotion(AmbientPetMotion motion) {
    if (!mounted || _ambientMotion == motion) {
      return;
    }
    setState(() => _ambientMotion = motion);
  }

  /// 播放一段固定时长的环境动作，结束后回到 idle 并继续调度。
  void _playAmbientFor(AmbientPetMotion motion, Duration duration) {
    _behaviorTimer?.cancel();
    _captureCurrentPosition();
    _moveController.stop();
    _moveController.reset();
    _setAmbientMotion(motion);
    _behaviorTimer = Timer(duration, () {
      if (!mounted || widget.pet.isSleeping) {
        return;
      }
      _setAmbientMotion(AmbientPetMotion.idle);
      _scheduleNextBehavior();
    });
  }

  /// 播放一次横向短跑，移动距离和时长带有随机性。
  void _startRunBurst({required bool toLeft}) {
    _behaviorTimer?.cancel();
    _captureCurrentPosition();
    _moveController.stop();
    _moveController.reset();
    _moveStartFactor = _positionFactor;
    final targetDistance = 0.15 + _random.nextDouble() * 0.35;
    _moveEndFactor = toLeft ? -targetDistance : targetDistance;
    _moveController.duration = Duration(
      milliseconds: 1800 + _random.nextInt(801),
    );
    setState(() {
      _facingLeft = toLeft;
      _ambientMotion = toLeft
          ? AmbientPetMotion.runLeft
          : AmbientPetMotion.runRight;
    });
    _moveController.forward(from: 0);
  }

  /// 在打断横向移动前记录当前位置，避免切换动作时精灵瞬移。
  void _captureCurrentPosition() {
    if (!_moveController.isAnimating) {
      return;
    }
    final moveCurve = Curves.easeInOut.transform(_moveController.value);
    _positionFactor =
        ui.lerpDouble(_moveStartFactor, _moveEndFactor, moveCurve) ??
        _positionFactor;
  }

  /// 将业务动作、睡眠状态和环境动作解析为具体精灵行。
  PetSpriteActionKey _resolveSpriteAction(PetAction action) {
    if (action == PetAction.taskComplete) {
      return PetSpriteActionKey.taskComplete;
    }
    if (widget.pet.isSleeping) {
      return PetSpriteActionKey.sleep;
    }
    if (action == PetAction.pet) {
      return PetSpriteActionKey.pet;
    }
    if (action == PetAction.feed) {
      return PetSpriteActionKey.feed;
    }
    if (action == PetAction.overdue) {
      return PetSpriteActionKey.overdue;
    }
    switch (_ambientMotion) {
      case AmbientPetMotion.runRight:
        return PetSpriteActionKey.runningRight;
      case AmbientPetMotion.runLeft:
        return PetSpriteActionKey.runningLeft;
      case AmbientPetMotion.waiting:
        return PetSpriteActionKey.waiting;
      case AmbientPetMotion.jumping:
        return PetSpriteActionKey.jumping;
      case AmbientPetMotion.runningInPlace:
        return PetSpriteActionKey.running;
      case AmbientPetMotion.idle:
        return PetSpriteActionKey.idle;
    }
  }

  /// 判断某个业务动作是否需要暂停随机待机并播放专属动画。
  bool _usesActionAnimation(PetAction action) {
    return action == PetAction.pet ||
        action == PetAction.feed ||
        action == PetAction.taskComplete ||
        action == PetAction.overdue;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 监听 Controller.action，使按钮操作和跨模块反馈能立即反映到舞台动画。
      final action = widget.controller.action.value;
      if (_loadedSpecies != widget.pet.species && !_spriteLoadFailed) {
        _loadSprite();
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            // 合并浮动和横向移动两个动画源，统一计算最终位移和朝向。
            animation: Listenable.merge([_idleController, _moveController]),
            builder: (context, child) {
              final image = _spriteImage;
              final spec = _spriteSpec;
              final spriteAction = _resolveSpriteAction(action);
              final animation = spec?.animationFor(spriteAction);
              if (animation != null) {
                // build 中只做帧动画同步，不修改宠物模型。
                _syncFrameAction(spriteAction, animation);
              }
              final idleLift = widget.pet.isSleeping
                  ? 1.5 * _idleController.value
                  : 5 * _idleController.value;
              final actionBounce =
                  action == PetAction.pet ||
                      action == PetAction.feed ||
                      action == PetAction.taskComplete
                  ? -12.0
                  : 0.0;
              final displaySize = spec?.displaySize ?? const Size(176, 176);
              final walkRange = (constraints.maxWidth - displaySize.width)
                  .clamp(0, 96)
                  .toDouble();
              final moveCurve = Curves.easeInOut.transform(
                _moveController.value,
              );
              final positionFactor = _moveController.isAnimating
                  ? ui.lerpDouble(_moveStartFactor, _moveEndFactor, moveCurve)!
                  : _positionFactor;
              final walkOffset = widget.pet.isSleeping
                  ? 0.0
                  : (walkRange * positionFactor);
              final scaleX = spec?.flipLeft == true && _facingLeft ? -1.0 : 1.0;

              return Transform.translate(
                // 位移叠加横向移动、呼吸浮动和一次性动作弹跳。
                offset: Offset(walkOffset, actionBounce - idleLift),
                child: Transform.scale(
                  scaleX: scaleX,
                  child: image == null || spec == null || animation == null
                      ? SpriteLoadPlaceholder(
                          failed: _spriteLoadFailed,
                          size: displaySize,
                        )
                      : CustomPaint(
                          size: displaySize,
                          painter: SpriteSheetPainter(
                            image: image,
                            row: animation.row,
                            frame: _frameIndex % animation.frames,
                            frameWidth: spec.frameWidth,
                            frameHeight: spec.frameHeight,
                          ),
                        ),
                ),
              );
            },
          );
        },
      );
    });
  }
}
