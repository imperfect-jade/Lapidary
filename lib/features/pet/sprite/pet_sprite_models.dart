import 'package:flutter/material.dart';

/// 精灵图中的动作键。
///
/// 这些键是业务动作和 spritesheet 行号之间的稳定映射，新增动作时需要同步 JSON、
/// fallback 规格以及主舞台/迷你精灵的解析逻辑。
enum PetSpriteActionKey {
  idle,
  runningRight,
  runningLeft,
  pet,
  feed,
  sleep,
  taskComplete,
  overdue,
  jumping,
  waiting,
  running,
}

/// 宠物主舞台的环境动作。
///
/// 与 `PetAction` 不同，这些动作不代表业务事件，只用于 idle 时的随机陪伴动画。
enum AmbientPetMotion {
  idle,
  runRight,
  runLeft,
  waiting,
  jumping,
  runningInPlace,
}

/// 单个动作在 spritesheet 中的动画规格。
///
/// `row` 表示动作所在行，`frames` 表示该行动画帧数，`fps` 控制播放速度。
class PetSpriteAnimationSpec {
  final int row;
  final int frames;
  final int fps;

  const PetSpriteAnimationSpec({
    required this.row,
    required this.frames,
    required this.fps,
  });

  /// 从 JSON 读取动作规格，并为缺失字段提供保守默认值。
  factory PetSpriteAnimationSpec.fromJson(Map<String, dynamic> json) {
    return PetSpriteAnimationSpec(
      row: (json['row'] as num?)?.toInt() ?? 0,
      frames: (json['frames'] as num?)?.toInt() ?? 1,
      fps: (json['fps'] as num?)?.toInt() ?? 6,
    );
  }
}

/// 一套宠物精灵规格，描述图片路径、帧尺寸、展示尺寸和动作映射。
///
/// 规格是纯数据对象，不负责加载图片；图片缓存由 `PetSpriteCache` 管理。
class PetSpriteSpec {
  final String assetPath;
  final int frameWidth;
  final int frameHeight;
  final Size displaySize;
  final bool flipLeft;
  final Map<PetSpriteActionKey, PetSpriteAnimationSpec> actions;

  const PetSpriteSpec({
    required this.assetPath,
    required this.frameWidth,
    required this.frameHeight,
    required this.displaySize,
    required this.flipLeft,
    required this.actions,
  });

  /// 获取指定动作的动画规格，缺失时退回 idle，保证 UI 不因单个动作缺失崩溃。
  PetSpriteAnimationSpec animationFor(PetSpriteActionKey key) {
    return actions[key] ?? actions[PetSpriteActionKey.idle]!;
  }

  /// 复制规格并覆盖展示尺寸，主舞台和迷你精灵可以共用同一资源但显示不同大小。
  PetSpriteSpec copyWith({Size? displaySize}) {
    return PetSpriteSpec(
      assetPath: assetPath,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
      displaySize: displaySize ?? this.displaySize,
      flipLeft: flipLeft,
      actions: actions,
    );
  }
}

/// hatch pet JSON 规格解析器。
///
/// 解析时会为缺失动作指定 fallback，例如 taskComplete 可退回 jumping，
/// 这样早期精灵资源不必一次性补齐所有动作也能正常展示。
class PetSpriteSpecParser {
  /// 将 JSON 转换为应用内部使用的 `PetSpriteSpec`。
  static PetSpriteSpec fromJson({
    required Map<String, dynamic> json,
    required Size displaySize,
    required bool flipLeft,
  }) {
    final actions = (json['actions'] as Map).cast<String, dynamic>();
    return PetSpriteSpec(
      assetPath: 'lib/assets/images/pet/${json['image']}',
      frameWidth: (json['frameWidth'] as num).toInt(),
      frameHeight: (json['frameHeight'] as num).toInt(),
      displaySize: displaySize,
      flipLeft: flipLeft,
      actions: {
        PetSpriteActionKey.idle: _animationFrom(actions, 'idle'),
        PetSpriteActionKey.runningRight: _animationFromOr(
          actions,
          'runningRight',
          'idle',
        ),
        PetSpriteActionKey.runningLeft: _animationFromOr(
          actions,
          'runningLeft',
          'runningRight',
        ),
        PetSpriteActionKey.pet: _animationFromOr(actions, 'pet', 'idle'),
        PetSpriteActionKey.feed: _animationFromOr(actions, 'feed', 'pet'),
        PetSpriteActionKey.sleep: _animationFromOr(actions, 'sleep', 'idle'),
        PetSpriteActionKey.taskComplete: _animationFromOr(
          actions,
          'taskComplete',
          'jumping',
        ),
        PetSpriteActionKey.overdue: _animationFromOr(
          actions,
          'overdue',
          'waiting',
        ),
        PetSpriteActionKey.jumping: _animationFromOr(actions, 'jumping', 'pet'),
        PetSpriteActionKey.waiting: _animationFromOr(
          actions,
          'waiting',
          'idle',
        ),
        PetSpriteActionKey.running: _animationFromOr(
          actions,
          'running',
          'runningRight',
        ),
      },
    );
  }

  /// 读取必需动作；idle 缺失表示规格不可用，应让上层走 legacy fallback。
  static PetSpriteAnimationSpec _animationFrom(
    Map<String, dynamic> actions,
    String key,
  ) {
    return PetSpriteAnimationSpec.fromJson(
      (actions[key] as Map).cast<String, dynamic>(),
    );
  }

  /// 读取可选动作，缺失时按指定 fallback 再退到 idle。
  static PetSpriteAnimationSpec _animationFromOr(
    Map<String, dynamic> actions,
    String key,
    String fallbackKey,
  ) {
    final animation = actions[key] ?? actions[fallbackKey] ?? actions['idle'];
    return PetSpriteAnimationSpec.fromJson(
      (animation as Map).cast<String, dynamic>(),
    );
  }
}
