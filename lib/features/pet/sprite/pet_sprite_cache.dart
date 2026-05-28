import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:todolist/features/pet/sprite/pet_sprite_models.dart';
import 'package:todolist/model/pet/pet.dart';

/// 已加载并解码的宠物精灵资源。
///
/// `spec` 描述每个动作在 spritesheet 中的位置，`image` 是 Flutter 可直接绘制的图片。
class CachedPetSprite {
  final PetSpriteSpec spec;
  final ui.Image image;

  const CachedPetSprite({required this.spec, required this.image});
}

/// 宠物精灵缓存，统一加载猫/狗的 JSON 规格和 spritesheet 图片。
///
/// 主舞台、全局浮层和番茄钟陪伴卡都复用这里，避免重复解码图片；
/// 加载失败时会移除缓存并回退 legacy 规格，后续再次请求仍可重试。
class PetSpriteCache {
  static const String _catSpecPath = 'lib/assets/images/pet/cat_hatch_pet.json';
  static const String _dogSpecPath = 'lib/assets/images/pet/dog_hatch_pet.json';

  static final Map<String, Future<CachedPetSprite>> _cache = {};

  /// 按物种加载精灵资源。
  ///
  /// 返回的是 Future 缓存，因此并发请求同一物种时只会触发一次真实加载。
  static Future<CachedPetSprite> load(String species) {
    final cached = _cache[species];
    if (cached != null) {
      return cached;
    }

    final loading = _load(species).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      // 加载失败不能把失败 Future 永久留在缓存中，否则资源恢复后也无法重试。
      _cache.remove(species);
      Error.throwWithStackTrace(error, stackTrace);
    });
    _cache[species] = loading;
    return loading;
  }

  /// 实际加载规格和图片资源，并把 spritesheet 解码成 ui.Image。
  static Future<CachedPetSprite> _load(String species) async {
    final spec = await _spriteSpecForSpecies(species);
    final data = await rootBundle.load(spec.assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return CachedPetSprite(spec: spec, image: frame.image);
  }

  /// 根据物种读取对应 JSON 规格；JSON 解析失败时退回旧版硬编码规格。
  static Future<PetSpriteSpec> _spriteSpecForSpecies(String species) async {
    try {
      if (species == PetSpecies.dog) {
        return await _jsonSpriteSpec(
          specPath: _dogSpecPath,
          displaySize: const Size(104, 112),
          flipLeft: false,
        );
      }
      return await _jsonSpriteSpec(
        specPath: _catSpecPath,
        displaySize: const Size(104, 112),
        flipLeft: false,
      );
    } catch (_) {
      return species == PetSpecies.dog ? _legacyDogSpec() : _legacyCatSpec();
    }
  }

  /// 从 hatch pet 规格 JSON 解析精灵动作配置。
  static Future<PetSpriteSpec> _jsonSpriteSpec({
    required String specPath,
    required Size displaySize,
    required bool flipLeft,
  }) async {
    final raw = await rootBundle.loadString(specPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return PetSpriteSpecParser.fromJson(
      json: json,
      displaySize: displaySize,
      flipLeft: flipLeft,
    );
  }

  /// 旧狗精灵规格 fallback。
  ///
  /// 保留它是为了在 JSON 缺失或格式错误时仍能显示旧精灵图，避免宠物舞台空白。
  static PetSpriteSpec _legacyDogSpec() {
    return const PetSpriteSpec(
      assetPath: 'lib/assets/images/pet/dog_spritesheet.png',
      frameWidth: 128,
      frameHeight: 128,
      displaySize: Size(104, 112),
      flipLeft: true,
      actions: {
        PetSpriteActionKey.idle: PetSpriteAnimationSpec(
          row: 0,
          frames: 4,
          fps: 6,
        ),
        PetSpriteActionKey.runningRight: PetSpriteAnimationSpec(
          row: 1,
          frames: 4,
          fps: 7,
        ),
        PetSpriteActionKey.runningLeft: PetSpriteAnimationSpec(
          row: 1,
          frames: 4,
          fps: 7,
        ),
        PetSpriteActionKey.pet: PetSpriteAnimationSpec(
          row: 2,
          frames: 4,
          fps: 7,
        ),
        PetSpriteActionKey.feed: PetSpriteAnimationSpec(
          row: 3,
          frames: 4,
          fps: 7,
        ),
        PetSpriteActionKey.sleep: PetSpriteAnimationSpec(
          row: 4,
          frames: 4,
          fps: 4,
        ),
        PetSpriteActionKey.taskComplete: PetSpriteAnimationSpec(
          row: 2,
          frames: 4,
          fps: 7,
        ),
        PetSpriteActionKey.overdue: PetSpriteAnimationSpec(
          row: 0,
          frames: 4,
          fps: 5,
        ),
        PetSpriteActionKey.jumping: PetSpriteAnimationSpec(
          row: 2,
          frames: 4,
          fps: 7,
        ),
        PetSpriteActionKey.waiting: PetSpriteAnimationSpec(
          row: 0,
          frames: 4,
          fps: 5,
        ),
        PetSpriteActionKey.running: PetSpriteAnimationSpec(
          row: 1,
          frames: 4,
          fps: 7,
        ),
      },
    );
  }

  /// 旧猫精灵规格 fallback，策略与狗一致。
  static PetSpriteSpec _legacyCatSpec() {
    return const PetSpriteSpec(
      assetPath: 'lib/assets/images/pet/cat_orange_spritesheet.png',
      frameWidth: 128,
      frameHeight: 128,
      displaySize: Size(104, 112),
      flipLeft: true,
      actions: {
        PetSpriteActionKey.idle: PetSpriteAnimationSpec(
          row: 0,
          frames: 4,
          fps: 6,
        ),
        PetSpriteActionKey.runningRight: PetSpriteAnimationSpec(
          row: 1,
          frames: 4,
          fps: 7,
        ),
        PetSpriteActionKey.runningLeft: PetSpriteAnimationSpec(
          row: 1,
          frames: 4,
          fps: 7,
        ),
        PetSpriteActionKey.pet: PetSpriteAnimationSpec(
          row: 2,
          frames: 4,
          fps: 7,
        ),
        PetSpriteActionKey.feed: PetSpriteAnimationSpec(
          row: 3,
          frames: 4,
          fps: 7,
        ),
        PetSpriteActionKey.sleep: PetSpriteAnimationSpec(
          row: 4,
          frames: 4,
          fps: 4,
        ),
        PetSpriteActionKey.taskComplete: PetSpriteAnimationSpec(
          row: 2,
          frames: 4,
          fps: 7,
        ),
        PetSpriteActionKey.overdue: PetSpriteAnimationSpec(
          row: 0,
          frames: 4,
          fps: 5,
        ),
        PetSpriteActionKey.jumping: PetSpriteAnimationSpec(
          row: 2,
          frames: 4,
          fps: 7,
        ),
        PetSpriteActionKey.waiting: PetSpriteAnimationSpec(
          row: 0,
          frames: 4,
          fps: 5,
        ),
        PetSpriteActionKey.running: PetSpriteAnimationSpec(
          row: 1,
          frames: 4,
          fps: 7,
        ),
      },
    );
  }
}
