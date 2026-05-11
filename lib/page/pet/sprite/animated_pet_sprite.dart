part of '../pet.dart';

class _AnimatedPetSprite extends StatefulWidget {
  final PetController controller;
  final PetModel pet;

  const _AnimatedPetSprite({required this.controller, required this.pet});

  @override
  State<_AnimatedPetSprite> createState() => _AnimatedPetSpriteState();
}

class _AnimatedPetSpriteState extends State<_AnimatedPetSprite>
    with TickerProviderStateMixin {
  static const String _catSpecPath = 'lib/assets/images/pet/cat_hatch_pet.json';
  static const String _dogSpecPath = 'lib/assets/images/pet/dog_hatch_pet.json';

  late final AnimationController _idleController;
  late final AnimationController _moveController;
  Worker? _actionWorker;
  Timer? _frameTimer;
  Timer? _behaviorTimer;
  ui.Image? _spriteImage;
  _PetSpriteSpec? _spriteSpec;
  bool _spriteLoadFailed = false;
  int _frameIndex = 0;
  bool _facingLeft = false;
  bool _wasSleeping = false;
  double _positionFactor = 0;
  double _moveStartFactor = 0;
  double _moveEndFactor = 0;
  final Random _random = Random();
  _AmbientPetMotion _ambientMotion = _AmbientPetMotion.idle;
  _SpriteActionKey _lastAction = _SpriteActionKey.idle;
  String? _loadedSpecies;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _wasSleeping = widget.pet.isSleeping;
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..addStatusListener(_handleMoveStatus);
    _actionWorker = ever<PetAction>(
      widget.controller.action,
      _handlePetActionChanged,
    );
    _loadSprite();
    if (_wasSleeping) {
      _enterSleepMode();
    } else {
      _scheduleNextBehavior(initial: true);
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedPetSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pet.species != widget.pet.species) {
      _loadSprite();
    }
    _idleController.duration = widget.pet.isSleeping
        ? const Duration(milliseconds: 2600)
        : const Duration(milliseconds: 1600);
    if (!_idleController.isAnimating) {
      _idleController.repeat(reverse: true);
    }
    _syncSleepMode();
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _behaviorTimer?.cancel();
    _actionWorker?.dispose();
    _moveController.removeStatusListener(_handleMoveStatus);
    _idleController.dispose();
    _moveController.dispose();
    _spriteImage?.dispose();
    super.dispose();
  }

  Future<void> _loadSprite() async {
    final species = widget.pet.species;
    try {
      await _loadSpriteWithSpec(species, await _spriteSpecForSpecies(species));
    } catch (error) {
      debugPrint('Failed to load pet sprite: $error');
      if (species == PetSpecies.dog) {
        try {
          await _loadSpriteWithSpec(species, _legacyDogSpec());
          return;
        } catch (fallbackError) {
          debugPrint('Failed to load fallback dog sprite: $fallbackError');
        }
      } else {
        try {
          await _loadSpriteWithSpec(species, _legacyCatSpec());
          return;
        } catch (fallbackError) {
          debugPrint('Failed to load fallback cat sprite: $fallbackError');
        }
      }
      if (mounted) {
        setState(() => _spriteLoadFailed = true);
      }
    }
  }

  Future<void> _loadSpriteWithSpec(String species, _PetSpriteSpec spec) async {
    final data = await rootBundle.load(spec.assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (!mounted || widget.pet.species != species) {
      frame.image.dispose();
      return;
    }
    _spriteImage?.dispose();
    setState(() {
      _spriteImage = frame.image;
      _spriteSpec = spec;
      _spriteLoadFailed = false;
      _loadedSpecies = species;
      _frameIndex = 0;
      _lastAction = _SpriteActionKey.idle;
    });
    _startFrameTimer(spec.animationFor(_SpriteActionKey.idle));
  }

  Future<_PetSpriteSpec> _spriteSpecForSpecies(String species) async {
    if (species == PetSpecies.dog) {
      return _jsonSpriteSpec(
        specPath: _dogSpecPath,
        displaySize: const Size(184, 198),
        flipLeft: false,
      );
    }
    return _jsonSpriteSpec(
      specPath: _catSpecPath,
      displaySize: const Size(184, 198),
      flipLeft: false,
    );
  }

  Future<_PetSpriteSpec> _jsonSpriteSpec({
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
        _SpriteActionKey.runningRight: _animationFrom(actions, 'runningRight'),
        _SpriteActionKey.runningLeft: _animationFrom(actions, 'runningLeft'),
        _SpriteActionKey.pet: _animationFrom(actions, 'pet'),
        _SpriteActionKey.feed: _animationFrom(actions, 'feed'),
        _SpriteActionKey.sleep: _animationFrom(actions, 'sleep'),
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

  static _PetSpriteSpec _legacyDogSpec() {
    return const _PetSpriteSpec(
      assetPath: 'lib/assets/images/pet/dog_spritesheet.png',
      frameWidth: 128,
      frameHeight: 128,
      displaySize: Size(176, 176),
      flipLeft: true,
      actions: {
        _SpriteActionKey.idle: _SpriteAnimationSpec(row: 0, frames: 4, fps: 6),
        _SpriteActionKey.runningRight: _SpriteAnimationSpec(
          row: 1,
          frames: 4,
          fps: 7,
        ),
        _SpriteActionKey.runningLeft: _SpriteAnimationSpec(
          row: 1,
          frames: 4,
          fps: 7,
        ),
        _SpriteActionKey.pet: _SpriteAnimationSpec(row: 2, frames: 4, fps: 7),
        _SpriteActionKey.feed: _SpriteAnimationSpec(row: 3, frames: 4, fps: 7),
        _SpriteActionKey.sleep: _SpriteAnimationSpec(row: 4, frames: 4, fps: 4),
        _SpriteActionKey.jumping: _SpriteAnimationSpec(
          row: 2,
          frames: 4,
          fps: 7,
        ),
        _SpriteActionKey.waiting: _SpriteAnimationSpec(
          row: 0,
          frames: 4,
          fps: 5,
        ),
        _SpriteActionKey.running: _SpriteAnimationSpec(
          row: 1,
          frames: 4,
          fps: 7,
        ),
      },
    );
  }

  static _PetSpriteSpec _legacyCatSpec() {
    return const _PetSpriteSpec(
      assetPath: 'lib/assets/images/pet/cat_orange_spritesheet.png',
      frameWidth: 128,
      frameHeight: 128,
      displaySize: Size(176, 176),
      flipLeft: true,
      actions: {
        _SpriteActionKey.idle: _SpriteAnimationSpec(row: 0, frames: 4, fps: 6),
        _SpriteActionKey.runningRight: _SpriteAnimationSpec(
          row: 1,
          frames: 4,
          fps: 7,
        ),
        _SpriteActionKey.runningLeft: _SpriteAnimationSpec(
          row: 1,
          frames: 4,
          fps: 7,
        ),
        _SpriteActionKey.pet: _SpriteAnimationSpec(row: 2, frames: 4, fps: 7),
        _SpriteActionKey.feed: _SpriteAnimationSpec(row: 3, frames: 4, fps: 7),
        _SpriteActionKey.sleep: _SpriteAnimationSpec(row: 4, frames: 4, fps: 4),
        _SpriteActionKey.jumping: _SpriteAnimationSpec(
          row: 2,
          frames: 4,
          fps: 7,
        ),
        _SpriteActionKey.waiting: _SpriteAnimationSpec(
          row: 0,
          frames: 4,
          fps: 5,
        ),
        _SpriteActionKey.running: _SpriteAnimationSpec(
          row: 1,
          frames: 4,
          fps: 7,
        ),
      },
    );
  }

  void _startFrameTimer(
    _SpriteAnimationSpec animation, {
    bool holdLastFrame = false,
  }) {
    _frameTimer?.cancel();
    final fps = animation.fps.clamp(1, 12).toInt();
    _frameTimer = Timer.periodic(Duration(milliseconds: 1000 ~/ fps), (_) {
      if (!mounted) {
        return;
      }
      final frames = animation.frames.clamp(1, 8).toInt();
      if (holdLastFrame) {
        final nextFrame = _frameIndex + 1;
        if (nextFrame >= frames) {
          _frameTimer?.cancel();
          _frameTimer = null;
          setState(() {
            _frameIndex = frames - 1;
          });
          return;
        }
        setState(() => _frameIndex = nextFrame);
        return;
      }
      setState(() => _frameIndex = (_frameIndex + 1) % frames);
    });
  }

  void _handleMoveStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }
    _positionFactor = _moveEndFactor;
    _moveController.reset();
    if (!mounted || widget.pet.isSleeping) {
      return;
    }
    setState(() => _ambientMotion = _AmbientPetMotion.idle);
    _scheduleNextBehavior();
  }

  void _syncFrameAction(
    _SpriteActionKey action,
    _SpriteAnimationSpec animation,
  ) {
    if (_lastAction != action) {
      _lastAction = action;
      _frameIndex = 0;
      _startFrameTimer(
        animation,
        holdLastFrame: action == _SpriteActionKey.sleep,
      );
    }
  }

  void _syncSleepMode() {
    if (_wasSleeping == widget.pet.isSleeping) {
      return;
    }
    _wasSleeping = widget.pet.isSleeping;
    if (_wasSleeping) {
      _enterSleepMode();
    } else {
      _exitSleepMode();
    }
  }

  void _handlePetActionChanged(PetAction action) {
    if (!mounted || widget.pet.isSleeping) {
      return;
    }
    if (action == PetAction.pet || action == PetAction.feed) {
      _behaviorTimer?.cancel();
      _captureCurrentPosition();
      _moveController.stop();
      _moveController.reset();
      _setAmbientMotion(_AmbientPetMotion.idle);
      return;
    }
    if (action == PetAction.idle &&
        (_behaviorTimer == null || !_behaviorTimer!.isActive)) {
      _scheduleNextBehavior(initial: true);
    }
  }

  void _enterSleepMode() {
    _behaviorTimer?.cancel();
    _moveController.stop();
    _moveController.reset();
    _positionFactor = 0;
    _moveStartFactor = 0;
    _moveEndFactor = 0;
    _lastAction = _SpriteActionKey.idle;
    _frameIndex = 0;
    if (mounted) {
      setState(() => _ambientMotion = _AmbientPetMotion.idle);
    }
  }

  void _exitSleepMode() {
    _lastAction = _SpriteActionKey.idle;
    _frameIndex = 0;
    if (mounted) {
      setState(() => _ambientMotion = _AmbientPetMotion.idle);
    }
    _scheduleNextBehavior(initial: true);
  }

  void _scheduleNextBehavior({bool initial = false}) {
    _behaviorTimer?.cancel();
    if (!mounted || widget.pet.isSleeping) {
      return;
    }
    final baseDelay = initial ? 1200 : 3000;
    final randomDelay = initial ? 1200 : 4000;
    _behaviorTimer = Timer(
      Duration(milliseconds: baseDelay + _random.nextInt(randomDelay)),
      _chooseNextBehavior,
    );
  }

  void _chooseNextBehavior() {
    if (!mounted || widget.pet.isSleeping) {
      return;
    }
    if (widget.controller.action.value != PetAction.idle) {
      _scheduleNextBehavior();
      return;
    }

    final roll = _random.nextDouble();
    if (roll < 0.55) {
      _setAmbientMotion(_AmbientPetMotion.idle);
      _scheduleNextBehavior();
    } else if (roll < 0.75) {
      _playAmbientFor(
        _AmbientPetMotion.waiting,
        const Duration(milliseconds: 2600),
      );
    } else if (roll < 0.85) {
      _playAmbientFor(
        _AmbientPetMotion.jumping,
        const Duration(milliseconds: 900),
      );
    } else if (roll < 0.90) {
      _playAmbientFor(
        _AmbientPetMotion.runningInPlace,
        const Duration(milliseconds: 1200),
      );
    } else {
      _startRunBurst(toLeft: _random.nextBool());
    }
  }

  void _setAmbientMotion(_AmbientPetMotion motion) {
    if (!mounted || _ambientMotion == motion) {
      return;
    }
    setState(() => _ambientMotion = motion);
  }

  void _playAmbientFor(_AmbientPetMotion motion, Duration duration) {
    _behaviorTimer?.cancel();
    _captureCurrentPosition();
    _moveController.stop();
    _moveController.reset();
    _setAmbientMotion(motion);
    _behaviorTimer = Timer(duration, () {
      if (!mounted || widget.pet.isSleeping) {
        return;
      }
      _setAmbientMotion(_AmbientPetMotion.idle);
      _scheduleNextBehavior();
    });
  }

  void _startRunBurst({required bool toLeft}) {
    _behaviorTimer?.cancel();
    _captureCurrentPosition();
    _moveController.stop();
    _moveController.reset();
    _moveStartFactor = _positionFactor;
    final targetDistance = 0.15 + _random.nextDouble() * 0.35;
    _moveEndFactor = toLeft ? -targetDistance : targetDistance;
    _moveController.duration = Duration(
      milliseconds: 1800 + _random.nextInt(801),
    );
    setState(() {
      _facingLeft = toLeft;
      _ambientMotion = toLeft
          ? _AmbientPetMotion.runLeft
          : _AmbientPetMotion.runRight;
    });
    _moveController.forward(from: 0);
  }

  void _captureCurrentPosition() {
    if (!_moveController.isAnimating) {
      return;
    }
    final moveCurve = Curves.easeInOut.transform(_moveController.value);
    _positionFactor =
        ui.lerpDouble(_moveStartFactor, _moveEndFactor, moveCurve) ??
        _positionFactor;
  }

  _SpriteActionKey _resolveSpriteAction(PetAction action) {
    if (widget.pet.isSleeping) {
      return _SpriteActionKey.sleep;
    }
    if (action == PetAction.pet) {
      return _SpriteActionKey.pet;
    }
    if (action == PetAction.feed) {
      return _SpriteActionKey.feed;
    }
    switch (_ambientMotion) {
      case _AmbientPetMotion.runRight:
        return _SpriteActionKey.runningRight;
      case _AmbientPetMotion.runLeft:
        return _SpriteActionKey.runningLeft;
      case _AmbientPetMotion.waiting:
        return _SpriteActionKey.waiting;
      case _AmbientPetMotion.jumping:
        return _SpriteActionKey.jumping;
      case _AmbientPetMotion.runningInPlace:
        return _SpriteActionKey.running;
      case _AmbientPetMotion.idle:
        return _SpriteActionKey.idle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final action = widget.controller.action.value;
      if (_loadedSpecies != widget.pet.species && !_spriteLoadFailed) {
        _loadSprite();
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: Listenable.merge([_idleController, _moveController]),
            builder: (context, child) {
              final image = _spriteImage;
              final spec = _spriteSpec;
              final spriteAction = _resolveSpriteAction(action);
              final animation = spec?.animationFor(spriteAction);
              if (animation != null) {
                _syncFrameAction(spriteAction, animation);
              }
              final idleLift = widget.pet.isSleeping
                  ? 1.5 * _idleController.value
                  : 5 * _idleController.value;
              final actionBounce =
                  action == PetAction.pet || action == PetAction.feed
                  ? -12.0
                  : 0.0;
              final displaySize = spec?.displaySize ?? const Size(176, 176);
              final walkRange = (constraints.maxWidth - displaySize.width)
                  .clamp(0, 96)
                  .toDouble();
              final moveCurve = Curves.easeInOut.transform(
                _moveController.value,
              );
              final positionFactor = _moveController.isAnimating
                  ? ui.lerpDouble(_moveStartFactor, _moveEndFactor, moveCurve)!
                  : _positionFactor;
              final walkOffset = widget.pet.isSleeping
                  ? 0.0
                  : (walkRange * positionFactor);
              final scaleX = spec?.flipLeft == true && _facingLeft ? -1.0 : 1.0;

              return Transform.translate(
                offset: Offset(walkOffset, actionBounce - idleLift),
                child: Transform.scale(
                  scaleX: scaleX,
                  child: image == null || spec == null || animation == null
                      ? _SpriteLoadPlaceholder(
                          failed: _spriteLoadFailed,
                          size: displaySize,
                        )
                      : CustomPaint(
                          size: displaySize,
                          painter: _SpriteSheetPainter(
                            image: image,
                            row: animation.row,
                            frame: _frameIndex % animation.frames,
                            frameWidth: spec.frameWidth,
                            frameHeight: spec.frameHeight,
                          ),
                        ),
                ),
              );
            },
          );
        },
      );
    });
  }
}
