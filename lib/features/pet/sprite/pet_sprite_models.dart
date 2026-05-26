import 'package:flutter/material.dart';

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

enum AmbientPetMotion {
  idle,
  runRight,
  runLeft,
  waiting,
  jumping,
  runningInPlace,
}

class PetSpriteAnimationSpec {
  final int row;
  final int frames;
  final int fps;

  const PetSpriteAnimationSpec({
    required this.row,
    required this.frames,
    required this.fps,
  });

  factory PetSpriteAnimationSpec.fromJson(Map<String, dynamic> json) {
    return PetSpriteAnimationSpec(
      row: (json['row'] as num?)?.toInt() ?? 0,
      frames: (json['frames'] as num?)?.toInt() ?? 1,
      fps: (json['fps'] as num?)?.toInt() ?? 6,
    );
  }
}

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

  PetSpriteAnimationSpec animationFor(PetSpriteActionKey key) {
    return actions[key] ?? actions[PetSpriteActionKey.idle]!;
  }

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

class PetSpriteSpecParser {
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

  static PetSpriteAnimationSpec _animationFrom(
    Map<String, dynamic> actions,
    String key,
  ) {
    return PetSpriteAnimationSpec.fromJson(
      (actions[key] as Map).cast<String, dynamic>(),
    );
  }

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
