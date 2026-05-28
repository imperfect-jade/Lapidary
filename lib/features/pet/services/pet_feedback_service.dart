import 'package:todolist/features/pet/domain/pet_action.dart';
import 'package:todolist/features/pet/domain/pet_overlay_event.dart';

/// 宠物反馈事件工厂。
///
/// 这里只把业务动作、文案和心情变化封装成 `PetOverlayEvent`，
/// 不直接写 Rx、不展示 Snackbar，也不访问 Hive，保持跨模块反馈可测试。
class PetFeedbackService {
  /// 创建一条全局浮层事件。
  ///
  /// id 使用时间戳和动作名组合，保证连续同类型事件也能触发 Overlay 重新播放。
  PetOverlayEvent createOverlayEvent(
    PetAction action,
    String message, {
    required int moodDelta,
    DateTime? now,
  }) {
    final createdAt = now ?? DateTime.now();
    return PetOverlayEvent(
      id: '${createdAt.microsecondsSinceEpoch}_${action.name}',
      action: action,
      message: message,
      createdAt: createdAt,
      moodDelta: moodDelta,
    );
  }
}
