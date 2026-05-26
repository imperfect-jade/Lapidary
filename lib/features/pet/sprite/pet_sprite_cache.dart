import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:todolist/features/pet/sprite/pet_sprite_models.dart';
import 'package:todolist/model/pet/pet.dart';

class CachedPetSprite {
  final PetSpriteSpec spec;
  final ui.Image image;

  const CachedPetSprite({required this.spec, required this.image});
}

class PetSpriteCache {
  static const String _catSpecPath = 'lib/assets/images/pet/cat_hatch_pet.json';
  static const String _dogSpecPath = 'lib/assets/images/pet/dog_hatch_pet.json';

  static final Map<String, Future<CachedPetSprite>> _cache = {};

  static Future<CachedPetSprite> load(String species) {
    final cached = _cache[species];
    if (cached != null) {
      return cached;
    }

    final loading = _load(species).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      _cache.remove(species);
      Error.throwWithStackTrace(error, stackTrace);
    });
    _cache[species] = loading;
    return loading;
  }

  static Future<CachedPetSprite> _load(String species) async {
    final spec = await _spriteSpecForSpecies(species);
    final data = await rootBundle.load(spec.assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return CachedPetSprite(spec: spec, image: frame.image);
  }

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
