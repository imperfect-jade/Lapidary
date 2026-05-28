import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/features/pet/domain/pet_action.dart';
import 'package:todolist/features/pet/domain/pet_overlay_event.dart';
import 'package:todolist/features/pet/sprite/pet_sprite_cache.dart';
import 'package:todolist/features/pet/sprite/pet_sprite_models.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/page/pet/pet_controller.dart';

import '../sprite/sprite_sheet_painter.dart';

/// 全局宠物反馈浮层，显示任务完成、专注完成和逾期等跨页面反馈。
///
/// 该组件通常放在首页 `Stack` 顶层，监听 `PetController.overlayEvent`；
/// 它只消费事件并播放动画，不修改宠物数值或奖励钱包。
class PetGlobalFeedbackOverlay extends StatefulWidget {
  const PetGlobalFeedbackOverlay({super.key});

  @override
  State<PetGlobalFeedbackOverlay> createState() =>
      _PetGlobalFeedbackOverlayState();
}

class _PetGlobalFeedbackOverlayState extends State<PetGlobalFeedbackOverlay>
    with SingleTickerProviderStateMixin {
  // 单条事件显示时长，过短会看不清文案，过长会遮挡当前工作流。
  static const Duration _visibleDuration = Duration(milliseconds: 1800);

  final PetController _controller = Get.find<PetController>();
  late final AnimationController _entranceController;
  // Worker 订阅全局事件；Timer 控制自动隐藏，两者都需要在 dispose 释放。
  Worker? _eventWorker;
  Timer? _hideTimer;
  PetOverlayEvent? _event;

  @override
  void initState() {
    super.initState();
    // 入场/退场共用一个控制器，保证新事件到来时可以从头播放。
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _eventWorker = ever<PetOverlayEvent?>(
      // 监听 Controller 发出的全局事件，保持页面层和业务联动解耦。
      _controller.overlayEvent,
      _handleOverlayEvent,
    );
  }

  @override
  void dispose() {
    // 取消隐藏定时器和 GetX Worker，避免首页销毁后仍尝试 setState。
    _hideTimer?.cancel();
    _eventWorker?.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  /// 处理新的浮层事件：立即显示、播放入场动画，并在延迟后隐藏。
  ///
  /// 通过事件 id 判断当前隐藏回调是否仍对应同一条事件，避免连续事件互相覆盖。
  void _handleOverlayEvent(PetOverlayEvent? event) {
    if (!mounted || event == null) {
      return;
    }

    _hideTimer?.cancel();
    setState(() => _event = event);
    _entranceController.forward(from: 0);
    _hideTimer = Timer(_visibleDuration, () async {
      if (!mounted || _event?.id != event.id) {
        return;
      }
      await _entranceController.reverse();
      if (mounted && _event?.id == event.id) {
        setState(() => _event = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    if (event == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      // 固定在右下角，既能被注意到，也尽量不遮挡当前页面的主内容。
      right: 16,
      bottom: 20,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: FadeTransition(
            // 透明度和缩放组合成轻量弹出效果，不拦截点击事件。
            opacity: CurvedAnimation(
              parent: _entranceController,
              curve: Curves.easeOut,
              reverseCurve: Curves.easeIn,
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(
                CurvedAnimation(
                  parent: _entranceController,
                  curve: Curves.easeOutBack,
                  reverseCurve: Curves.easeIn,
                ),
              ),
              child: _PetOverlayCard(
                key: ValueKey(event.id),
                event: event,
                controller: _controller,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 单条全局反馈卡片，包含迷你宠物、事件图标、文案和心情变化。
class _PetOverlayCard extends StatelessWidget {
  final PetOverlayEvent event;
  final PetController controller;

  const _PetOverlayCard({
    super.key,
    required this.event,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // 不同事件使用不同强调色：逾期偏冷静提醒，完成类偏正向奖励。
    final accent = _accentFor(event.action);
    final icon = _iconFor(event.action);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 220,
        padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withValues(alpha: 0.32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 左侧迷你宠物复用精灵缓存，事件角标帮助用户快速识别反馈类型。
            SizedBox(
              width: 82,
              height: 92,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: 6,
                    child: Container(
                      width: 68,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                  MiniPetSprite(controller: controller, action: event.action),
                  Positioned(
                    right: 2,
                    top: 4,
                    child: _OverlayIconBadge(icon: icon, color: accent),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              // 右侧展示事件文案和心情变化，不提供按钮，避免打断当前页面流程。
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 7),
                  _MoodDeltaPill(delta: event.moodDelta, color: accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 根据动作类型选择浮层强调色。
  Color _accentFor(PetAction action) {
    return action == PetAction.overdue ? Colors.blueGrey : Colors.amber;
  }

  /// 根据动作类型选择角标图标。
  IconData _iconFor(PetAction action) {
    return action == PetAction.overdue ? Icons.access_time : Icons.star_rounded;
  }
}

/// 全局浮层和番茄钟陪伴卡使用的迷你宠物精灵。
///
/// 它按当前宠物物种加载缓存精灵，并把 `PetAction` 映射到精灵动作；
/// 资源加载失败时退回普通宠物图标，保证反馈浮层不会空白。
class MiniPetSprite extends StatefulWidget {
  final PetController controller;
  final PetAction action;
  final PetSpriteActionKey? spriteAction;

  const MiniPetSprite({
    super.key,
    required this.controller,
    required this.action,
    this.spriteAction,
  });

  @override
  State<MiniPetSprite> createState() => _MiniPetSpriteState();
}

class _MiniPetSpriteState extends State<MiniPetSprite> {
  // 迷你精灵使用独立帧计时器，避免和主舞台精灵生命周期互相影响。
  Timer? _frameTimer;
  int _frameIndex = 0;
  CachedPetSprite? _sprite;
  bool _loadFailed = false;
  PetSpriteActionKey? _lastAction;

  @override
  void initState() {
    super.initState();
    _loadSprite();
  }

  @override
  void didUpdateWidget(covariant MiniPetSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.pet.value?.species !=
        widget.controller.pet.value?.species) {
      _loadSprite();
    }
    if (oldWidget.action != widget.action) {
      _lastAction = null;
      _frameIndex = 0;
      _syncAnimation();
    } else if (oldWidget.spriteAction != widget.spriteAction) {
      _lastAction = null;
      _frameIndex = 0;
      _syncAnimation();
    }
  }

  @override
  void dispose() {
    // 取消帧动画计时器，防止浮层消失后继续 setState。
    _frameTimer?.cancel();
    super.dispose();
  }

  /// 按当前宠物物种加载精灵缓存，失败时设置 fallback 状态。
  Future<void> _loadSprite() async {
    try {
      final species = widget.controller.pet.value?.species ?? PetSpecies.cat;
      final sprite = await PetSpriteCache.load(species);
      if (!mounted) {
        return;
      }
      setState(() {
        _sprite = sprite;
        _loadFailed = false;
        _frameIndex = 0;
        _lastAction = null;
      });
      _syncAnimation();
    } catch (error) {
      debugPrint('Failed to load pet overlay sprite: $error');
      if (mounted) {
        setState(() => _loadFailed = true);
      }
    }
  }

  /// 根据当前动作同步帧动画；动作未变化且计时器仍有效时不重复重启。
  void _syncAnimation() {
    final sprite = _sprite;
    if (sprite == null) {
      return;
    }
    final action = _actionKeyFor(widget.action);
    final animation = sprite.spec.animationFor(action);
    if (_lastAction == action && _frameTimer?.isActive == true) {
      return;
    }
    _lastAction = action;
    _frameTimer?.cancel();
    final fps = animation.fps.clamp(1, 8).toInt();
    _frameTimer = Timer.periodic(Duration(milliseconds: 1000 ~/ fps), (_) {
      if (!mounted) {
        return;
      }
      final frames = animation.frames.clamp(1, 8).toInt();
      setState(() => _frameIndex = (_frameIndex + 1) % frames);
    });
  }

  /// 将业务动作转换为精灵动作。
  ///
  /// 外部可通过 `spriteAction` 强制指定动作，番茄钟陪伴卡就使用这个入口播放随机动作。
  PetSpriteActionKey _actionKeyFor(PetAction action) {
    final spriteAction = widget.spriteAction;
    if (spriteAction != null) {
      return spriteAction;
    }
    if (action == PetAction.overdue) {
      return PetSpriteActionKey.overdue;
    }
    return PetSpriteActionKey.taskComplete;
  }

  @override
  Widget build(BuildContext context) {
    final sprite = _sprite;
    if (_loadFailed || sprite == null) {
      // 精灵资源缺失时显示稳定 fallback，避免全局浮层出现空区域。
      return const Icon(Icons.pets, color: Colors.black45, size: 54);
    }

    final action = _actionKeyFor(widget.action);
    final animation = sprite.spec.animationFor(action);
    return CustomPaint(
      size: sprite.spec.displaySize,
      painter: SpriteSheetPainter(
        image: sprite.image,
        row: animation.row,
        frame: _frameIndex % animation.frames,
        frameWidth: sprite.spec.frameWidth,
        frameHeight: sprite.spec.frameHeight,
      ),
    );
  }
}

/// 浮层宠物旁的事件角标，只负责视觉提示，不参与点击。
class _OverlayIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _OverlayIconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

/// 心情变化标签，展示本次事件对宠物心情的影响。
class _MoodDeltaPill extends StatelessWidget {
  final int delta;
  final Color color;

  const _MoodDeltaPill({required this.delta, required this.color});

  @override
  Widget build(BuildContext context) {
    final text = delta >= 0 ? '心情 +$delta' : '心情 $delta';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color == Colors.amber ? Colors.orange[800] : color,
        ),
      ),
    );
  }
}
