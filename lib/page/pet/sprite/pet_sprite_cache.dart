part of '../pet.dart';

class _CachedPetSprite {
  final _PetSpriteSpec spec;
  final ui.Image image;

  const _CachedPetSprite({required this.spec, required this.image});
}

class _PetSpriteCache {
  static const String _catSpecPath = 'lib/assets/images/pet/cat_hatch_pet.json';
  static const String _dogSpecPath = 'lib/assets/images/pet/dog_hatch_pet.json';

  static final Map<String, Future<_CachedPetSprite>> _cache = {};

  static Future<_CachedPetSprite> load(String species) {
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

  static Future<_CachedPetSprite> _load(String species) async {
    final spec = await _spriteSpecForSpecies(species);
    final data = await rootBundle.load(spec.assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return _CachedPetSprite(spec: spec, image: frame.image);
  }

  static Future<_PetSpriteSpec> _spriteSpecForSpecies(String species) {
    if (species == PetSpecies.dog) {
      return _jsonSpriteSpec(
        specPath: _dogSpecPath,
        displaySize: const Size(104, 112),
        flipLeft: false,
      );
    }
    return _jsonSpriteSpec(
      specPath: _catSpecPath,
      displaySize: const Size(104, 112),
      flipLeft: false,
    );
  }

  static Future<_PetSpriteSpec> _jsonSpriteSpec({
    required String specPath,
    required Size displaySize,
    required bool flipLeft,
  }) async {
    final raw = await rootBundle.loadString(specPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final actions = (json['actions'] as Map).cast<String, dynamic>();
    return _PetSpriteSpec(
      assetPath: 'lib/assets/images/pet/${json['image']}',
      frameWidth: (json['frameWidth'] as num).toInt(),
      frameHeight: (json['frameHeight'] as num).toInt(),
      displaySize: displaySize,
      flipLeft: flipLeft,
      actions: {
        _SpriteActionKey.idle: _animationFrom(actions, 'idle'),
        _SpriteActionKey.runningRight: _animationFromOr(
          actions,
          'runningRight',
          'idle',
        ),
        _SpriteActionKey.runningLeft: _animationFromOr(
          actions,
          'runningLeft',
          'runningRight',
        ),
        _SpriteActionKey.pet: _animationFromOr(actions, 'pet', 'idle'),
        _SpriteActionKey.feed: _animationFromOr(actions, 'feed', 'pet'),
        _SpriteActionKey.sleep: _animationFromOr(actions, 'sleep', 'idle'),
        _SpriteActionKey.taskComplete: _animationFromOr(
          actions,
          'taskComplete',
          'jumping',
        ),
        _SpriteActionKey.overdue: _animationFromOr(
          actions,
          'overdue',
          'waiting',
        ),
        _SpriteActionKey.jumping: _animationFromOr(actions, 'jumping', 'pet'),
        _SpriteActionKey.waiting: _animationFromOr(actions, 'waiting', 'idle'),
        _SpriteActionKey.running: _animationFromOr(
          actions,
          'running',
          'runningRight',
        ),
      },
    );
  }

  static _SpriteAnimationSpec _animationFrom(
    Map<String, dynamic> actions,
    String key,
  ) {
    return _SpriteAnimationSpec.fromJson(
      (actions[key] as Map).cast<String, dynamic>(),
    );
  }

  static _SpriteAnimationSpec _animationFromOr(
    Map<String, dynamic> actions,
    String key,
    String fallbackKey,
  ) {
    final animation = actions[key] ?? actions[fallbackKey];
    return _SpriteAnimationSpec.fromJson(
      (animation as Map).cast<String, dynamic>(),
    );
  }
}
