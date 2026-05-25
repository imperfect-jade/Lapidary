part of '../pet.dart';

enum _SpriteActionKey {
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

enum _AmbientPetMotion {
  idle,
  runRight,
  runLeft,
  waiting,
  jumping,
  runningInPlace,
}

class _SpriteAnimationSpec {
  final int row;
  final int frames;
  final int fps;

  const _SpriteAnimationSpec({
    required this.row,
    required this.frames,
    required this.fps,
  });

  factory _SpriteAnimationSpec.fromJson(Map<String, dynamic> json) {
    return _SpriteAnimationSpec(
      row: (json['row'] as num?)?.toInt() ?? 0,
      frames: (json['frames'] as num?)?.toInt() ?? 1,
      fps: (json['fps'] as num?)?.toInt() ?? 6,
    );
  }
}

class _PetSpriteSpec {
  final String assetPath;
  final int frameWidth;
  final int frameHeight;
  final Size displaySize;
  final bool flipLeft;
  final Map<_SpriteActionKey, _SpriteAnimationSpec> actions;

  const _PetSpriteSpec({
    required this.assetPath,
    required this.frameWidth,
    required this.frameHeight,
    required this.displaySize,
    required this.flipLeft,
    required this.actions,
  });

  _SpriteAnimationSpec animationFor(_SpriteActionKey key) {
    return actions[key] ?? actions[_SpriteActionKey.idle]!;
  }
}
