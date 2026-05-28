import 'package:todolist/features/pet/domain/pet_action.dart';

/// 全局宠物浮层事件。
///
/// 事件由 `PetFeedbackService` 创建、`PetController.overlayEvent` 发出，
/// 页面层只消费这个对象播放动画，不再回查任务或番茄钟上下文。
class PetOverlayEvent {
  /// 唯一事件 id，用于连续事件的动画去重和延迟隐藏校验。
  final String id;

  /// 触发浮层的宠物动作，决定图标、颜色和迷你精灵动作。
  final PetAction action;

  /// 浮层展示文案。
  final String message;

  /// 事件创建时间，便于后续扩展日志或调试。
  final DateTime createdAt;

  /// 本次事件对心情的影响，用于浮层标签展示。
  final int moodDelta;

  const PetOverlayEvent({
    required this.id,
    required this.action,
    required this.message,
    required this.createdAt,
    required this.moodDelta,
  });
}
