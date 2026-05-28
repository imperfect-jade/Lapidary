import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todolist/features/pet/domain/pet_action.dart';
import 'package:todolist/model/pet/pet.dart';
import 'package:todolist/page/pet/pet_controller.dart';

/// 宠物页主舞台上的局部反馈层。
///
/// 它监听 `PetController.feedbackTick/feedbackAction` 播放爱心、食物、星星等短动画；
/// 反馈只在宠物页内显示，全局跨页面提示由 `PetGlobalFeedbackOverlay` 负责。
class PetFeedbackOverlay extends StatelessWidget {
  final PetController controller;
  final PetModel pet;

  const PetFeedbackOverlay({
    super.key,
    required this.controller,
    required this.pet,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // tick 用来区分连续同类反馈，确保相同 action 也能重新创建动画 Widget。
      final tick = controller.feedbackTick.value;
      final feedbackAction = controller.feedbackAction.value;
      if (feedbackAction == PetAction.taskComplete && tick > 0) {
        // 任务/专注完成用星星表现正向奖励感。
        return Positioned(
          key: ValueKey('task_complete_feedback_$tick'),
          top: 42,
          right: 58,
          child: SizedBox(
            width: 104,
            height: 82,
            child: Stack(
              children: const [
                Positioned(
                  left: 34,
                  top: 8,
                  child: _FloatingFeedback(
                    icon: Icons.star_rounded,
                    color: Colors.amber,
                    size: 40,
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 30,
                  child: _FloatingFeedback(
                    icon: Icons.auto_awesome,
                    color: Color.fromARGB(255, 255, 193, 7),
                    delay: Duration(milliseconds: 100),
                    size: 30,
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 28,
                  child: _FloatingFeedback(
                    icon: Icons.star_rounded,
                    color: Color.fromARGB(255, 255, 179, 0),
                    delay: Duration(milliseconds: 200),
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (feedbackAction == PetAction.overdue && tick > 0) {
        // 逾期反馈保持克制，只显示提醒图标，不做惩罚式强打扰。
        return Positioned(
          key: ValueKey('overdue_feedback_$tick'),
          top: 50,
          right: 70,
          child: const _FloatingFeedback(
            icon: Icons.access_time,
            color: Colors.blueGrey,
            size: 36,
          ),
        );
      }

      if (pet.isSleeping) {
        // 睡眠状态下持续显示 Z，优先级高于普通 idle 空状态。
        return const Positioned(
          top: 48,
          right: 76,
          child: _FloatingFeedback(
            icon: Icons.nights_stay,
            color: Colors.indigoAccent,
            label: 'Z',
          ),
        );
      }

      if (feedbackAction == PetAction.pet && tick > 0) {
        // 抚摸反馈使用多颗爱心，强化用户与宠物的直接互动。
        return Positioned(
          key: ValueKey('pet_feedback_$tick'),
          top: 48,
          right: 64,
          child: SizedBox(
            width: 92,
            height: 76,
            child: Stack(
              children: const [
                Positioned(
                  left: 30,
                  top: 16,
                  child: _FloatingFeedback(
                    icon: Icons.favorite,
                    color: Colors.pinkAccent,
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 28,
                  child: _FloatingFeedback(
                    icon: Icons.favorite,
                    color: Color.fromARGB(255, 255, 121, 164),
                    delay: Duration(milliseconds: 110),
                    size: 30,
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 22,
                  child: _FloatingFeedback(
                    icon: Icons.favorite,
                    color: Color.fromARGB(255, 255, 93, 135),
                    delay: Duration(milliseconds: 210),
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (feedbackAction == PetAction.feed && tick > 0) {
        // 喂食反馈显示饭碗图标，数值变化已经由 PetController 持久化。
        return Positioned(
          key: ValueKey('feed_feedback_$tick'),
          bottom: 72,
          right: 78,
          child: const _FloatingFeedback(
            icon: Icons.rice_bowl,
            color: Colors.orange,
          ),
        );
      }

      return const SizedBox.shrink();
    });
  }
}

/// 单个漂浮反馈图标，负责淡入淡出、上浮和缩放动画。
class _FloatingFeedback extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String? label;
  final Duration delay;
  final double size;

  const _FloatingFeedback({
    required this.icon,
    required this.color,
    this.label,
    this.delay = Duration.zero,
    this.size = 38,
  });

  @override
  State<_FloatingFeedback> createState() => _FloatingFeedbackState();
}

class _FloatingFeedbackState extends State<_FloatingFeedback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    // 每个图标自带动画控制器，支持通过 delay 做错落的星星/爱心效果。
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 80),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _offset = Tween<Offset>(
      begin: const Offset(0, 10),
      end: const Offset(0, -22),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _scale = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    // 动画结束前页面离开时要释放控制器，避免 Ticker 泄漏。
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      // AnimatedBuilder 只重绘当前图标，不影响主舞台精灵帧动画。
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: _offset.value,
            child: Transform.scale(scale: _scale.value, child: child),
          ),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.86),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.16),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: widget.label == null
              ? Icon(widget.icon, color: widget.color, size: widget.size * 0.58)
              : Text(
                  widget.label!,
                  style: TextStyle(
                    color: widget.color,
                    fontSize: widget.size * 0.47,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
